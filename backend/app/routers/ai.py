from fastapi import APIRouter, Depends, HTTPException, Query, status
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime
import time
import asyncio

from app import crud, models, schemas, auth
from app.dependencies import get_db, ai_gateway
from app.admin_utils import get_current_admin_user
from app.ai_features import AiTaskHelper, AiEventHelper, AiNoteHelper
from app.ai_usage_logger import log_ai_usage, estimate_token_count
from app.smart_generation import AiSmartGenerator
from app.recipe_ai import AiRecipeGenerator

router = APIRouter()

# Helpers
def _with_env_credentials(credential_status: List[dict]) -> List[dict]:
    """
    Ensure providers configured via environment are reflected as having keys so UI/tests stay aligned.
    """
    for provider_key in ("openai", "gemini"):
        if ai_gateway.providers.get(provider_key):
            existing = None
            for entry in credential_status:
                if isinstance(entry, dict) and entry.get("provider") == provider_key:
                    existing = entry
                    break
            if existing is None:
                credential_status.append(
                    {
                        "provider": provider_key,
                        "has_key": True,
                        "masked_key": None,
                        "key_name": "env",
                        "model": None,
                    }
                )
            else:
                existing["has_key"] = existing.get("has_key") or True
                existing.setdefault("key_name", "env")
    return credential_status

def _build_provider_info(db: Session, current_user: models.User) -> schemas.AiProviderInfo:
    # Load any user-scoped credentials before returning provider info
    try:
        ai_gateway._ensure_cloud_providers(db, user_id=current_user.id)
    except Exception as exc:
        print(f"Warning: could not refresh provider credentials: {exc}")

    base = ai_gateway.get_provider_info()
    creds = crud.list_provider_credentials(db, owner_id=current_user.id)
    creds = _with_env_credentials(creds)
    base["credentials"] = [schemas.ProviderCredentialStatus(**c) for c in creds]
    return schemas.AiProviderInfo(**base)

# Info Endpoints
@router.get("/ai/info", response_model=schemas.AiProviderInfo)
def get_ai_provider_info(
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db),
):
    """Get current AI provider configuration"""
    return _build_provider_info(db, current_user)


@router.get("/ai/provider-info", response_model=schemas.AiProviderInfo)
def get_ai_provider_info_alias(
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db),
):
    """Alias for provider info to support older clients/tests."""
    return _build_provider_info(db, current_user)

@router.get("/ai/models", response_model=schemas.AiModelsResponse)
async def list_ai_models(
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db),
    provider: Optional[str] = Query(None, description="Filter models by provider key (openai, gemini, ollama, etc.)"),
    limit: int = Query(200, ge=1, le=500, description="Max models to return"),
):
    """List available AI models - always returns a valid response."""
    fallback_identifier = "mock:llama3.1"

    def _fallback_response(default_id: str = fallback_identifier) -> schemas.AiModelsResponse:
        provider_key, model_name, _ = ai_gateway._parse_identifier(default_id)
        return schemas.AiModelsResponse(
            models=[
                schemas.AiModelInfo(
                    id=default_id,
                    name=model_name,
                    provider=provider_key,
                    source=provider_key,
                )
            ],
            provider=provider_key,
            current_model=model_name,
            default_model_id=default_id,
            credentials=[],
        )

    try:
        try:
            models_list = await ai_gateway.get_models(db=db, user_id=current_user.id)
        except Exception as exc:
            print(f"Error listing AI models: {exc}")
            import traceback
            traceback.print_exc()
            models_list = [
                ai_gateway._format_model_entry(
                    ai_gateway.provider or "mock",
                    ai_gateway.model or "llama3.1",
                    source=ai_gateway.provider or "mock",
                )
            ]

        if not models_list:
            models_list = [
                ai_gateway._format_model_entry(
                    "mock",
                    "llama3.1",
                    source="mock",
                )
            ]

        normalized_provider = None
        if provider:
            normalized_provider = provider.lower()
            if normalized_provider == "ollama-local":
                normalized_provider = "ollama"
            models_list = [
                m for m in models_list if isinstance(m, dict) and (m.get("provider") or "").lower() == normalized_provider
            ]
            if not models_list:
                models_list = [
                    ai_gateway._format_model_entry(
                        normalized_provider or "mock",
                        name=ai_gateway.model,
                        source=normalized_provider or "mock",
                    )
                ]

        try:
            credential_status = crud.list_provider_credentials(db, owner_id=current_user.id)
        except Exception as exc:
            print(f"Error getting credential status: {exc}")
            import traceback
            traceback.print_exc()
            credential_status = []

        credential_status = _with_env_credentials(credential_status)

        if normalized_provider:
            credential_status = [c for c in credential_status if c.get("provider") == normalized_provider]

        credential_has_key = {
            c.get("provider"): bool(c.get("has_key")) for c in credential_status if isinstance(c, dict)
        }

        available_ids: List[str] = []
        provider_first: dict = {}
        for entry in models_list:
            if not isinstance(entry, dict):
                continue
            model_id = entry.get("id")
            provider_key = entry.get("provider") or "mock"
            name = None
            if isinstance(model_id, str) and ":" in model_id:
                name = model_id.split(":", 1)[1]
            name = entry.get("name") or name or model_id
            if not model_id:
                model_id = f"{provider_key}:{name or ai_gateway.model}"
            if model_id:
                available_ids.append(model_id)
                provider_first.setdefault(provider_key, model_id)

        default_model_id = ai_gateway.default_model_identifier or None

        def _provider_from_identifier(identifier: Optional[str]) -> str:
            try:
                provider_key, _, _ = (
                    ai_gateway._parse_identifier(identifier)
                    if identifier
                    else ("mock", "llama3.1", None)
                )
            except Exception:
                provider_key = "mock"
            return "ollama" if provider_key == "ollama-local" else provider_key

        def _has_credentials(provider_key: str) -> bool:
            provider_key = "ollama" if provider_key == "ollama-local" else provider_key
            if provider_key in ("openai", "gemini"):
                return credential_has_key.get(provider_key, False) or ai_gateway.providers.get(provider_key) is not None
            return True

        if not default_model_id or default_model_id not in available_ids or not _has_credentials(_provider_from_identifier(default_model_id)):
            priorities = ["openai", "gemini", "openwebui", "ollama", "client"]
            if normalized_provider:
                priorities = [normalized_provider] + [p for p in priorities if p != normalized_provider]
            preferred = None
            for provider_key in priorities:
                if not _has_credentials(provider_key):
                    continue
                preferred = next(
                    (
                        mid
                        for mid in available_ids
                        if isinstance(mid, str) and mid.startswith(f"{provider_key}:")
                    ),
                    None,
                )
                if preferred:
                    break
            if not preferred:
                # fallback to any provider that has credentials
                for pk, ident in provider_first.items():
                    if ident and _has_credentials(pk):
                        preferred = ident
                        break
            default_model_id = preferred or (available_ids[0] if available_ids else fallback_identifier)

        try:
            provider, model_name, _ = ai_gateway._parse_identifier(default_model_id)
        except Exception as exc:
            print(f"❌ Error parsing model identifier '{default_model_id}': {exc}")
            import traceback
            traceback.print_exc()
            provider, model_name, default_model_id = "mock", "llama3.1", fallback_identifier

        ai_gateway.default_model_identifier = default_model_id
        ai_gateway.provider = provider
        ai_gateway.model = model_name

        model_schemas: List[schemas.AiModelInfo] = []
        for entry in models_list:
            if not isinstance(entry, dict):
                continue
            provider_key = entry.get("provider") or "mock"
            name = entry.get("name") or entry.get("id") or model_name
            model_id = entry.get("id") or f"{provider_key}:{name}"
            modified_at = entry.get("modified_at")
            if isinstance(modified_at, datetime):
                modified_at = modified_at.isoformat()
            elif modified_at is not None and not isinstance(modified_at, str):
                modified_at = str(modified_at)
            model_dict = {
                "id": model_id,
                "name": name or model_name,
                "provider": provider_key,
                "size": entry.get("size"),
                "source": entry.get("source") or provider_key,
                "node_id": entry.get("node_id"),
                "node_name": entry.get("node_name"),
                "endpoint": entry.get("endpoint"),
                "latency_ms": entry.get("latency_ms"),
                "metadata": entry.get("metadata") or {},
                "modified_at": modified_at,
                "description": entry.get("description"),
                "context_window": entry.get("context_window"),
                "max_output_tokens": entry.get("max_output_tokens"),
                "input_cost_per_1m": entry.get("input_cost_per_1m"),
                "output_cost_per_1m": entry.get("output_cost_per_1m"),
                "supports_vision": entry.get("supports_vision"),
                "supports_function_calling": entry.get("supports_function_calling"),
            }
            try:
                model_schemas.append(schemas.AiModelInfo(**model_dict))
            except Exception as exc:
                print(f"❌ Error creating AiModelInfo for model {model_id}: {exc}")

        if not model_schemas:
            model_schemas = [
                schemas.AiModelInfo(
                    id=default_model_id,
                    name=model_name,
                    provider=provider,
                    source=provider,
                )
            ]

        if default_model_id:
            model_schemas.sort(key=lambda m: 0 if m.id == default_model_id else 1)

        if limit:
            model_schemas = model_schemas[:limit]

        credential_schemas = [schemas.ProviderCredentialStatus(**c) for c in credential_status]

        return schemas.AiModelsResponse(
            models=model_schemas,
            provider=provider,
            current_model=model_name,
            default_model_id=default_model_id,
            credentials=credential_schemas,
        )
    except Exception as exc:
        print(f"❌ CRITICAL: Unexpected error in list_ai_models: {exc}")
        import traceback
        traceback.print_exc()
        return _fallback_response()

@router.post("/admin/ai/default-model", response_model=schemas.AiModelsResponse)
async def set_default_ai_model(
    payload: schemas.AiDefaultModelRequest,
    admin_user: models.User = Depends(get_current_admin_user),
    db: Session = Depends(get_db),
):
    """
    Admin-only: set the backend default model so Messages/AgentHub pick the same route.
    """
    models_list = await ai_gateway.get_models(db=db, user_id=admin_user.id)
    available_ids = [m["id"] for m in models_list]
    if payload.default_model_id not in available_ids:
        raise HTTPException(status_code=400, detail="Model is not available on this backend")

    provider, model_name, _ = ai_gateway._parse_identifier(payload.default_model_id)
    ai_gateway.default_model_identifier = payload.default_model_id
    ai_gateway.provider = provider
    ai_gateway.model = model_name

    credential_status = crud.list_provider_credentials(db, owner_id=admin_user.id)
    return schemas.AiModelsResponse(
        models=[schemas.AiModelInfo(**m) for m in models_list],
        provider=provider,
        current_model=model_name,
        default_model_id=payload.default_model_id,
        credentials=[schemas.ProviderCredentialStatus(**c) for c in credential_status],
    )

# Chat & Embeddings
@router.post("/ai/chat", response_model=schemas.AiChatResponse)
async def ai_chat(
    request: schemas.AiChatRequest,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Generate AI chat response"""
    start_time = time.time()
    try:
        response, route = await ai_gateway.generate_reply(
            request.prompt,
            request.history,
            model_identifier=request.model,
            user_id=current_user.id,
            db=db,
            include_context=True,
        )
    except TimeoutError:
        raise HTTPException(status_code=503, detail="AI provider timed out")
    except Exception as exc:
        print(f"AI chat error: {exc}")
        raise HTTPException(status_code=500, detail="AI chat failed")

    latency_ms = int((time.time() - start_time) * 1000)
    try:
        log_ai_usage(
            db=db,
            user_id=current_user.id,
            model_identifier=route.identifier,
            endpoint="/ai/chat",
            prompt_tokens=estimate_token_count(request.prompt),
            response_tokens=estimate_token_count(response),
            latency_ms=latency_ms,
        )
    except Exception as e:
        print(f"Warning: Failed to log AI usage: {e}")
    
    return schemas.AiChatResponse(
        response=response,
        model=route.identifier,
        provider=route.key,
    )

async def _chat_stream_response(
    request: schemas.AiChatRequest,
    current_user: models.User,
    db: Session,
):
    """
    Shared streaming response helper so legacy endpoints can reuse the same logic.
    """
    stream, route = await ai_gateway.generate_stream(
        request.prompt,
        request.history,
        model_identifier=request.model,
        user_id=current_user.id,
        db=db,
    )
    async def generate():
        async for chunk in stream:
            yield f"data: {chunk}\n\n"
        yield "data: [DONE]\n\n"

    headers = {"X-Halext-AI-Model": route.identifier}
    return StreamingResponse(generate(), media_type="text/event-stream", headers=headers)

@router.post("/ai/chat/stream")
async def ai_chat_stream(
    request: schemas.AiChatRequest,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Stream AI chat response (Server-Sent Events)"""
    return await _chat_stream_response(request, current_user, db)

@router.post("/ai/stream")
async def ai_chat_stream_legacy(
    request: schemas.AiChatRequest,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Legacy streaming endpoint for backward compatibility"""
    return await _chat_stream_response(request, current_user, db)

@router.post("/ai/embeddings", response_model=schemas.AiEmbeddingsResponse)
async def generate_embeddings(
    request: schemas.AiEmbeddingsRequest,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Generate embeddings for text"""
    embeddings = await ai_gateway.generate_embeddings(
        request.text,
        model_identifier=request.model,
        user_id=current_user.id,
        db=db,
    )
    return schemas.AiEmbeddingsResponse(
        embeddings=embeddings,
        model=request.model or ai_gateway.default_model_identifier,
        dimension=len(embeddings)
    )

# AI Task Features
@router.post("/ai/tasks/suggest-stream")
async def suggest_task_enhancements_stream(
    request: schemas.AiTaskSuggestionsRequest,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Get AI suggestions for task breakdown, labels, time estimate, and priority"""
    helper = AiTaskHelper(ai_gateway, user_id=current_user.id, db=db)
    
    async def generate():
        stream = await helper.suggest_subtasks_stream(request.title, request.description)
        async for chunk in stream:
            yield f"data: {chunk}\n\n"
        yield "data: [DONE]\n\n"

    return StreamingResponse(generate(), media_type="text/event-stream")


@router.post("/ai/tasks/suggest", response_model=schemas.AiTaskSuggestionsResponse)
async def suggest_task_enhancements(
    request: schemas.AiTaskSuggestionsRequest,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Get AI suggestions for task breakdown, labels, time estimate, and priority"""
    helper = AiTaskHelper(ai_gateway, user_id=current_user.id, db=db)

    subtasks, labels, time_est, priority = await asyncio.gather(
        helper.suggest_subtasks(request.title, request.description),
        helper.suggest_labels(request.title, request.description),
        helper.estimate_time(request.title, request.description),
        helper.suggest_priority(request.title, request.description, model_identifier=request.model)
    )

    return schemas.AiTaskSuggestionsResponse(
        subtasks=subtasks,
        labels=labels,
        estimated_hours=time_est["estimated_hours"],
        priority=priority["priority"],
        priority_reasoning=priority["reasoning"]
    )

@router.post("/ai/tasks/estimate-time", response_model=schemas.AiTimeEstimateResponse)
async def estimate_task_time(
    request: schemas.AiTaskSuggestionsRequest,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Estimate time required for a task"""
    helper = AiTaskHelper(ai_gateway, user_id=current_user.id, db=db)
    result = await helper.estimate_time(request.title, request.description, request.model)
    return schemas.AiTimeEstimateResponse(**result)

@router.post("/ai/tasks/suggest-priority", response_model=schemas.AiPriorityResponse)
async def suggest_task_priority(
    request: schemas.AiTaskSuggestionsRequest,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Suggest priority for a task"""
    helper = AiTaskHelper(ai_gateway, user_id=current_user.id, db=db)
    result = await helper.suggest_priority(request.title, request.description, model_identifier=request.model)
    return schemas.AiPriorityResponse(**result)

@router.post("/ai/tasks/suggest-labels", response_model=List[str])
async def suggest_task_labels(
    request: schemas.AiTaskSuggestionsRequest,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Suggest labels for a task"""
    helper = AiTaskHelper(ai_gateway, user_id=current_user.id, db=db)
    return await helper.suggest_labels(request.title, request.description, request.model)

# AI Event Features
@router.post("/ai/events/analyze", response_model=schemas.AiEventAnalysisResponse)
async def analyze_event(
    request: schemas.AiEventAnalysisRequest,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Analyze event and provide AI suggestions"""
    helper = AiEventHelper(ai_gateway, user_id=current_user.id, db=db)

    existing_events = crud.get_user_events(db, current_user.id)
    events_data = [
        {
            "id": e.id,
            "title": e.title,
            "start_time": e.start_time,
            "end_time": e.end_time
        }
        for e in existing_events
    ]

    duration_minutes = int((request.end_time - request.start_time).total_seconds() / 60)

    summary, prep_steps, optimal_times = await asyncio.gather(
        helper.summarize_event(request.title, request.description, duration_minutes, request.model),
        helper.suggest_preparation(request.title, request.description, request.event_type, request.model),
        helper.suggest_optimal_time(request.title, duration_minutes, request.start_time, events_data)
    )

    conflicts = await helper.detect_conflicts(
        request.title,
        request.start_time,
        request.end_time,
        events_data
    )

    return schemas.AiEventAnalysisResponse(
        summary=summary,
        preparation_steps=prep_steps,
        optimal_times=optimal_times,
        conflicts=conflicts
    )

# AI Note Features
@router.post("/ai/notes/summarize", response_model=schemas.AiNoteSummaryResponse)
async def summarize_note(
    request: schemas.AiNoteSummaryRequest,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Summarize note and extract information"""
    helper = AiNoteHelper(ai_gateway, user_id=current_user.id, db=db)

    summary, tags, tasks = await asyncio.gather(
        helper.summarize_note(request.content, request.max_length, request.model),
        helper.generate_tags(request.content, request.model),
        helper.extract_tasks(request.content, request.model)
    )

    return schemas.AiNoteSummaryResponse(
        summary=summary,
        tags=tags,
        extracted_tasks=tasks
    )

# Smart Generation
@router.post("/ai/generate-tasks", response_model=schemas.AiGenerateTasksResponse)
async def generate_smart_tasks(
    request: schemas.AiGenerateTasksRequest,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Generate tasks, events, and smart lists from natural language prompt"""
    import time
    from fastapi import HTTPException, status
    
    start_time = time.time()
    try:
        helper = AiSmartGenerator(ai_gateway, user_id=current_user.id)

        result = await helper.generate_from_prompt(
            prompt=request.prompt,
            timezone=request.context.timezone,
            current_date=request.context.current_date,
            existing_task_titles=request.context.existing_task_titles,
            upcoming_event_dates=request.context.upcoming_event_dates,
            model_identifier=request.model,
            db=db,
        )

        # Log AI usage
        latency_ms = int((time.time() - start_time) * 1000)
        try:
            log_ai_usage(
                db=db,
                user_id=current_user.id,
                model_identifier=request.model or "default",
                endpoint="/ai/generate-tasks",
                prompt_tokens=estimate_token_count(request.prompt),
                response_tokens=estimate_token_count(str(result)),
                latency_ms=latency_ms,
            )
        except Exception as e:
            print(f"⚠️ Warning: Failed to log AI usage for task generation: {e}")

        return schemas.AiGenerateTasksResponse(**result)
    except TimeoutError:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="AI provider timed out while generating tasks. Please try again."
        )
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=f"Failed to generate tasks: {str(e)}"
        )
    except Exception as exc:
        print(f"❌ Error generating tasks: {exc}")
        import traceback
        traceback.print_exc()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to generate tasks: {str(exc)}"
        )

# Recipe AI
@router.post("/ai/recipes/generate", response_model=schemas.RecipeGenerationResponse)
async def generate_recipes(
    request: schemas.RecipeGenerationRequest,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db),
):
    """Generate recipes from available ingredients"""
    import time
    from fastapi import HTTPException, status
    
    start_time = time.time()
    try:
        helper = AiRecipeGenerator(ai_gateway, user_id=current_user.id)

        result = await helper.generate_recipes(
            ingredients=request.ingredients,
            dietary_restrictions=request.dietary_restrictions,
            cuisine_preferences=request.cuisine_preferences,
            difficulty_level=request.difficulty_level,
            time_limit_minutes=request.time_limit_minutes,
            servings=request.servings,
            meal_type=request.meal_type,
            model_identifier=request.model,
            db=db,
        )

        # Log AI usage
        latency_ms = int((time.time() - start_time) * 1000)
        try:
            from app.ai_usage_logger import log_ai_usage
            from app.ai_features import estimate_token_count
            prompt_text = f"Generate recipes with ingredients: {', '.join(request.ingredients)}"
            response_text = str(result)
            log_ai_usage(
                db=db,
                user_id=current_user.id,
                model_identifier=request.model or "default",
                endpoint="/ai/recipes/generate",
                prompt_tokens=estimate_token_count(prompt_text),
                response_tokens=estimate_token_count(response_text),
                latency_ms=latency_ms,
            )
        except Exception as e:
            print(f"⚠️ Warning: Failed to log AI usage for recipe generation: {e}")

        return schemas.RecipeGenerationResponse(**result)
    except TimeoutError:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="AI provider timed out while generating recipes. Please try again."
        )
    except ValueError as e:
        # Handle parsing errors or validation errors
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=f"Failed to generate recipes: {str(e)}"
        )
    except Exception as exc:
        print(f"❌ Error generating recipes: {exc}")
        import traceback
        traceback.print_exc()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to generate recipes: {str(exc)}"
        )

@router.post("/ai/recipes/meal-plan", response_model=schemas.MealPlanResponse)
async def generate_meal_plan(
    request: schemas.MealPlanRequest,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db),
):
    """Generate a meal plan for multiple days"""
    start_time = time.time()
    try:
        helper = AiRecipeGenerator(ai_gateway, user_id=current_user.id)

        result = await helper.generate_meal_plan(
            ingredients=request.ingredients,
            days=request.days,
            dietary_restrictions=request.dietary_restrictions,
            budget=request.budget,
            meals_per_day=request.meals_per_day,
            model_identifier=request.model,
            db=db,
        )

        # Log AI usage
        latency_ms = int((time.time() - start_time) * 1000)
        try:
            prompt_text = f"Generate meal plan for {request.days} days with ingredients: {', '.join(request.ingredients)}"
            response_text = str(result)
            log_ai_usage(
                db=db,
                user_id=current_user.id,
                model_identifier=request.model or "default",
                endpoint="/ai/recipes/meal-plan",
                prompt_tokens=estimate_token_count(prompt_text),
                response_tokens=estimate_token_count(response_text),
                latency_ms=latency_ms,
            )
        except Exception as e:
            print(f"⚠️ Warning: Failed to log AI usage for meal plan generation: {e}")

        return schemas.MealPlanResponse(**result)
    except TimeoutError:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="AI provider timed out while generating meal plan. Please try again."
        )
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=f"Failed to generate meal plan: {str(e)}"
        )
    except Exception as exc:
        print(f"❌ Error generating meal plan: {exc}")
        import traceback
        traceback.print_exc()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to generate meal plan: {str(exc)}"
        )

@router.post("/ai/recipes/suggest-substitutions", response_model=schemas.RecipeGenerationResponse)
async def suggest_ingredient_substitutions(
    request: schemas.SubstitutionRequest,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db),
):
    """Suggest ingredient substitutions and alternative recipes"""
    helper = AiRecipeGenerator(ai_gateway, user_id=current_user.id)

    result = await helper.suggest_substitutions(
        ingredients=request.ingredients,
        recipe_type=request.recipe_type,
        model_identifier=request.model,
        db=db,
    )

    return schemas.RecipeGenerationResponse(**result)

@router.post("/ai/recipes/analyze-ingredients", response_model=schemas.IngredientAnalysis)
async def analyze_ingredients(
    request: schemas.IngredientsRequest,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db),
):
    """Analyze and categorize ingredients"""
    helper = AiRecipeGenerator(ai_gateway, user_id=current_user.id)

    result = await helper.analyze_ingredients(
        ingredients=request.ingredients,
        model_identifier=request.model,
        db=db,
    )

    return schemas.IngredientAnalysis(**result)
