from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional
import json
import time

from app import crud, models, schemas, auth
from app.dependencies import get_db, ai_gateway
from app.websockets import manager
from app.ai_usage_logger import log_ai_usage, estimate_token_count
from app.ai_features import AiHiveMindHelper

router = APIRouter()

def _serialize_conversation(conversation: models.Conversation):
    base = schemas.Conversation.from_orm(conversation).dict()
    participants = []
    participant_details: list[schemas.UserSummary] = []
    for participant in conversation.participants:
        if participant.user is None:
            continue
        participants.append(participant.user.username)
        participant_details.append(
            schemas.UserSummary.from_orm(participant.user)
        )

    last_message = None
    if conversation.messages:
        last_message_obj = sorted(conversation.messages, key=lambda m: m.created_at)[-1]
        last_message = schemas.ChatMessage.from_orm(last_message_obj)

    return schemas.ConversationSummary(
        **base,
        participants=participants,
        participant_details=participant_details,
        last_message=last_message,
        unread_count=0,
    )

def _resolve_default_model_id(payload_default: Optional[str]) -> Optional[str]:
    """
    Normalize/choose a default model identifier for new/updated conversations.
    """
    if payload_default:
        if ":" in payload_default:
            return payload_default
        return f"{ai_gateway.provider}:{payload_default}"
    return ai_gateway.default_model_identifier

@router.get("/conversations/", response_model=List[schemas.ConversationSummary])
def list_conversations(
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    conversations = crud.get_conversations_for_user(db=db, user_id=current_user.id)
    return [_serialize_conversation(conversation) for conversation in conversations]

@router.get("/conversations/{conversation_id}", response_model=schemas.ConversationSummary)
def get_conversation(
    conversation_id: int,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    conversation = crud.get_conversation_for_user(db=db, conversation_id=conversation_id, user_id=current_user.id)
    if not conversation:
        raise HTTPException(status_code=404, detail="Conversation not found")
    return _serialize_conversation(conversation)

@router.post("/conversations/", response_model=schemas.ConversationSummary)
def create_conversation(
    conversation: schemas.ConversationCreate,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    conversation.default_model_id = _resolve_default_model_id(conversation.default_model_id)
    participant_ids: List[int] = []
    for username in conversation.participant_usernames:
        target = crud.get_user_by_username(db, username=username)
        if not target:
            raise HTTPException(status_code=404, detail=f"User {username} not found")
        participant_ids.append(target.id)
    db_conversation = crud.create_conversation(
        db=db,
        payload=conversation,
        owner_id=current_user.id,
        participant_ids=participant_ids,
    )
    return _serialize_conversation(db_conversation)

@router.put("/conversations/{conversation_id}", response_model=schemas.ConversationSummary)
def update_conversation(
    conversation_id: int,
    update: schemas.ConversationBase,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    update.default_model_id = _resolve_default_model_id(update.default_model_id)
    conversation = crud.get_conversation_for_user(db=db, conversation_id=conversation_id, user_id=current_user.id)
    if not conversation:
        raise HTTPException(status_code=404, detail="Conversation not found")
    if conversation.owner_id != current_user.id:
        raise HTTPException(status_code=403, detail="Only the owner can modify conversation settings")

    # Update fields
    conversation.title = update.title
    conversation.mode = update.mode
    conversation.with_ai = update.with_ai
    conversation.default_model_id = update.default_model_id

    db.add(conversation)
    db.commit()
    db.refresh(conversation)
    return _serialize_conversation(conversation)

@router.delete("/conversations/{conversation_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_conversation(
    conversation_id: int,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    """Delete a conversation (owner only)"""
    conversation = crud.get_conversation_for_user(db=db, conversation_id=conversation_id, user_id=current_user.id)
    if not conversation:
        raise HTTPException(status_code=404, detail="Conversation not found")
    if conversation.owner_id != current_user.id:
        raise HTTPException(status_code=403, detail="Only the owner can delete this conversation")
    
    # Delete conversation (cascade should handle messages)
    db.delete(conversation)
    db.commit()
    return

@router.get("/conversations/{conversation_id}/messages", response_model=List[schemas.ChatMessage])
def get_conversation_messages(
    conversation_id: int,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    conversation = crud.get_conversation_for_user(db=db, conversation_id=conversation_id, user_id=current_user.id)
    if not conversation:
        raise HTTPException(status_code=404, detail="Conversation not found")
    messages = crud.get_messages_for_conversation(db=db, conversation_id=conversation_id, limit=200)
    # Convert ORM models to Pydantic schemas using from_orm (Pydantic v1)
    return [schemas.ChatMessage.from_orm(msg) for msg in messages]

@router.post("/conversations/{conversation_id}/messages", response_model=List[schemas.ChatMessage])
async def send_conversation_message(
    conversation_id: int,
    message: schemas.ChatMessageCreate,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    """Send a message to a conversation and get AI response if enabled"""
    try:
        conversation = crud.get_conversation_for_user(db=db, conversation_id=conversation_id, user_id=current_user.id)
        if not conversation:
            raise HTTPException(status_code=404, detail="Conversation not found")
        
        user_message = crud.add_message_to_conversation(
            db=db,
            conversation_id=conversation_id,
            content=message.content,
            author_id=current_user.id,
            author_type="user",
        )
        
        # Convert ORM model to Pydantic schema for JSON serialization (Pydantic v1)
        user_message_schema = schemas.ChatMessage.from_orm(user_message)
        
        try:
            await manager.broadcast(json.dumps(user_message_schema.dict()), str(conversation_id))
        except Exception as e:
            print(f"⚠️ Warning: Failed to broadcast user message: {e}")
            # Continue - broadcasting is not critical
        
        responses = [user_message_schema]
        if conversation.with_ai:
            if conversation.hive_mind_goal:
                print(f"Hive Mind logic would be triggered for conversation {conversation_id}")

            history_messages = crud.get_messages_for_conversation(db=db, conversation_id=conversation_id, limit=50)
            history_payload = [
                {"role": "assistant" if msg.author_type == "ai" else "user", "content": msg.content}
                for msg in history_messages
            ]
            
            # Enhanced Context Awareness
            context_str = ""
            try:
                embedding_model = "all-minilm-l6-v2" # or some other default
                embedding = await ai_gateway.generate_embeddings(message.content, embedding_model, user_id=current_user.id, db=db)
                if embedding:
                    similar_items = crud.get_similar_embeddings(db, owner_id=current_user.id, query_embedding=embedding)
                    if similar_items:
                        context_str = "\n\nHere is some additional context that might be relevant:\n"
                        for item in similar_items:
                            # TODO: Fetch the actual content from the source
                            context_str += f"- From {item.source} (ID: {item.source_id})\n"
            except Exception as e:
                print(f"⚠️ Warning: Failed to get context embeddings: {e}")
                # Continue without context - not critical

            # Use model from: 1) message override, 2) conversation default, 3) system default
            model_to_use = message.model or conversation.default_model_id
            
            start_time = time.time()
            
            try:
                ai_reply, route = await ai_gateway.generate_reply(
                    message.content + context_str,
                    history_payload,
                    model_identifier=model_to_use,
                    user_id=current_user.id,
                    db=db,
                    include_context=True,
                )
                print(f"AI route for conversation {conversation_id}: {route.identifier} (provider {route.key})")
                if route.key == "mock" and any(ai_gateway.providers.get(p) for p in ("openai", "gemini")):
                    raise HTTPException(
                        status_code=503,
                        detail="AI provider unavailable; configured provider fell back to mock.",
                    )
            except Exception as e:
                print(f"❌ Error generating AI reply: {e}")
                import traceback
                traceback.print_exc()
                # Return user message only if AI generation fails
                raise HTTPException(
                    status_code=500,
                    detail=f"Failed to generate AI response: {str(e)}"
                )
            
            # Log AI usage
            latency_ms = int((time.time() - start_time) * 1000)
            try:
                log_ai_usage(
                    db=db,
                    user_id=current_user.id,
                    model_identifier=route.identifier,
                    endpoint="/conversations/{id}/messages",
                    prompt_tokens=estimate_token_count(message.content),
                    response_tokens=estimate_token_count(ai_reply),
                    conversation_id=conversation_id,
                    latency_ms=latency_ms,
                )
            except Exception as e:
                print(f"⚠️ Warning: Failed to log AI usage: {e}")
            
            ai_message = crud.add_message_to_conversation(
                db=db,
                conversation_id=conversation_id,
                content=ai_reply,
                author_id=None,
                author_type="ai",
                model_used=route.identifier,
            )
            # Convert ORM model to Pydantic schema for JSON serialization (Pydantic v1)
            ai_message_schema = schemas.ChatMessage.from_orm(ai_message)
            
            try:
                await manager.broadcast(json.dumps(ai_message_schema.dict()), str(conversation_id))
            except Exception as e:
                print(f"⚠️ Warning: Failed to broadcast AI message: {e}")
                # Continue - broadcasting is not critical
            
            responses.append(ai_message_schema)
        return responses
    except HTTPException:
        # Re-raise HTTP exceptions (like 404) as-is
        raise
    except Exception as e:
        print(f"❌ Unexpected error in send_conversation_message: {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(
            status_code=500,
            detail=f"Internal server error: {str(e)}"
        )


@router.post("/conversations/{conversation_id}/hive-mind/goal", response_model=schemas.ConversationSummary)
async def set_hive_mind_goal(
    conversation_id: int,
    goal: str,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    conversation = crud.get_conversation_for_user(db=db, conversation_id=conversation_id, user_id=current_user.id)
    if not conversation:
        raise HTTPException(status_code=404, detail="Conversation not found")
    if conversation.owner_id != current_user.id:
        raise HTTPException(status_code=403, detail="Only the owner can set the hive mind goal")

    conversation.hive_mind_goal = goal
    db.add(conversation)
    db.commit()
    db.refresh(conversation)
    return _serialize_conversation(conversation)


@router.get("/conversations/{conversation_id}/hive-mind/summary", response_model=str)
async def get_hive_mind_summary(
    conversation_id: int,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    conversation = crud.get_conversation_for_user(db=db, conversation_id=conversation_id, user_id=current_user.id)
    if not conversation:
        raise HTTPException(status_code=404, detail="Conversation not found")
    if not conversation.hive_mind_goal:
        raise HTTPException(status_code=400, detail="This conversation does not have a hive mind goal.")

    history_messages = crud.get_messages_for_conversation(db=db, conversation_id=conversation_id, limit=50)
    history_payload = [
        {"role": "assistant" if msg.author_type == "ai" else "user", "content": msg.content}
        for msg in history_messages
    ]

    helper = AiHiveMindHelper(ai_gateway, user_id=current_user.id, db=db)
    summary = await helper.summarize_conversation(history_payload, conversation.hive_mind_goal)
    return summary


@router.get("/conversations/{conversation_id}/hive-mind/next-steps", response_model=List[str])
async def get_hive_mind_next_steps(
    conversation_id: int,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    conversation = crud.get_conversation_for_user(db=db, conversation_id=conversation_id, user_id=current_user.id)
    if not conversation:
        raise HTTPException(status_code=404, detail="Conversation not found")
    if not conversation.hive_mind_goal:
        raise HTTPException(status_code=400, detail="This conversation does not have a hive mind goal.")

    history_messages = crud.get_messages_for_conversation(db=db, conversation_id=conversation_id, limit=50)
    history_payload = [
        {"role": "assistant" if msg.author_type == "ai" else "user", "content": msg.content}
        for msg in history_messages
    ]

    helper = AiHiveMindHelper(ai_gateway, user_id=current_user.id, db=db)
    next_steps = await helper.suggest_next_steps(history_payload, conversation.hive_mind_goal)
    return next_steps

# Message read/typing endpoints for iOS compatibility
@router.post("/messages/{message_id}/read", status_code=status.HTTP_204_NO_CONTENT)
def mark_message_as_read(
    message_id: int,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    """Mark a specific message as read"""
    # TODO: Implement message read tracking if needed
    # For now, this is a no-op endpoint for iOS compatibility
    return

@router.post("/messages/conversations/{conversation_id}/read", status_code=status.HTTP_204_NO_CONTENT)
def mark_conversation_as_read(
    conversation_id: int,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    """Mark all messages in a conversation as read"""
    # Verify user has access to conversation
    conversation = crud.get_conversation_for_user(db=db, conversation_id=conversation_id, user_id=current_user.id)
    if not conversation:
        raise HTTPException(status_code=404, detail="Conversation not found")
    # TODO: Implement conversation read tracking if needed
    # For now, this is a no-op endpoint for iOS compatibility
    return

@router.post("/messages/conversations/{conversation_id}/typing", status_code=status.HTTP_204_NO_CONTENT)
async def send_typing_indicator(
    conversation_id: int,
    is_typing: bool = True,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    """Send typing indicator for a conversation"""
    # Verify user has access to conversation
    conversation = crud.get_conversation_for_user(db=db, conversation_id=conversation_id, user_id=current_user.id)
    if not conversation:
        raise HTTPException(status_code=404, detail="Conversation not found")
    
    # Broadcast typing indicator via WebSocket
    try:
        typing_data = json.dumps({
            "type": "typing",
            "user_id": current_user.id,
            "username": current_user.username,
            "is_typing": is_typing
        })
        await manager.broadcast(typing_data, str(conversation_id))
    except Exception as e:
        print(f"⚠️ Warning: Failed to broadcast typing indicator: {e}")
        # Continue - typing indicators are not critical
    
    return


@router.post("/messages/quick", response_model=schemas.ChatMessage)
def send_quick_message(
    payload: schemas.QuickMessageCreate,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db),
):
    """
    Quickly send a message to a username by reusing or creating a 1:1 conversation.
    """
    username = payload.username.strip()
    if not username:
        raise HTTPException(status_code=400, detail="username is required")

    target = crud.get_user_by_username(db, username=username)
    if not target:
        raise HTTPException(status_code=404, detail="User not found")
    if target.id == current_user.id:
        raise HTTPException(status_code=400, detail="Cannot quick message yourself")

    conversations = crud.get_conversations_for_user(db=db, user_id=current_user.id)
    direct_conv = next(
        (
            c
            for c in conversations
            if len(c.participants) == 2
            and {p.user_id for p in c.participants} == {current_user.id, target.id}
        ),
        None,
    )
    if not direct_conv:
        conv_payload = schemas.ConversationCreate(
            title=f"Chat with {target.username}",
            mode="partner",
            with_ai=False,
            default_model_id=None,
            participant_usernames=[target.username],
        )
        direct_conv = crud.create_conversation(
            db=db,
            payload=conv_payload,
            owner_id=current_user.id,
            participant_ids=[target.id],
        )

    message = crud.add_message_to_conversation(
        db=db,
        conversation_id=direct_conv.id,
        content=payload.content,
        author_id=current_user.id,
        author_type="user",
        model_used=payload.model,
    )
    return schemas.ChatMessage.from_orm(message)
