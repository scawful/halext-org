from fastapi import APIRouter, Depends, HTTPException, status, Query
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from sqlalchemy import func, or_
from typing import List, Optional
from datetime import timedelta, datetime

from app import crud, models, schemas, auth
from app.dependencies import get_db, verify_access_code

router = APIRouter()

def _build_partner_presence(user: models.User, presence: Optional[models.UserPresence]) -> schemas.PartnerPresence:
    """
    Convert stored presence (or fallback) into API schema.
    """
    if presence:
        return schemas.PartnerPresence(
            username=user.username,
            is_online=presence.is_online,
            status=presence.status if hasattr(presence, 'status') else "online",
            current_activity=presence.current_activity,
            status_message=presence.status_message,
            last_seen=presence.last_seen or datetime.utcnow(),
        )
    return schemas.PartnerPresence(
        username=user.username,
        is_online=True,
        status="online",
        current_activity=None,
        status_message=None,
        last_seen=datetime.utcnow(),
    )

@router.post("/token", response_model=schemas.Token)
async def login_for_access_token(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db)
):
    user = auth.authenticate_user(db, username=form_data.username, password=form_data.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    access_token_expires = timedelta(minutes=auth.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = auth.create_access_token(
        data={"sub": user.username}, expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer"}


@router.post("/users/", response_model=schemas.User)
def create_user(
    user: schemas.UserCreate,
    create_demo_data: bool = True,
    db: Session = Depends(get_db),
    _: str = Depends(verify_access_code)
):
    db_user = crud.get_user_by_email(db, email=user.email)
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    db_user = crud.get_user_by_username(db, username=user.username)
    if db_user:
        raise HTTPException(status_code=400, detail="Username already registered")

    new_user = crud.create_user(db=db, user=user)

    # Create demo content for new users to showcase the UI
    if create_demo_data:
        try:
            from app.seed_data import create_demo_content
            create_demo_content(new_user.id, db)
        except Exception as e:
            print(f"Warning: Failed to create demo content: {e}")
            # Don't fail registration if demo content creation fails

    return new_user


@router.get("/users/me/", response_model=schemas.User)
async def read_users_me(current_user: models.User = Depends(auth.get_current_active_user)):
    return current_user


@router.get("/users/search", response_model=List[schemas.UserSummary])
def search_users(
    q: str = "",
    limit: int = 20,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    """
    Lightweight user search for messaging (matches username/full_name, excludes the requester).
    """
    query = db.query(models.User).filter(models.User.id != current_user.id)
    if q:
        like = f"%{q.lower()}%"
        query = query.filter(
            or_(
                func.lower(models.User.username).like(like),
                func.lower(models.User.full_name).like(like),
            )
        )
    results = query.order_by(models.User.username.asc()).limit(limit).all()
    return [schemas.UserSummary.from_orm(user) for user in results]


@router.post("/users/me/presence", response_model=schemas.PartnerPresence)
def update_presence(
    payload: schemas.PresenceUpdate,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db),
):
    presence = crud.upsert_user_presence(db, current_user.id, payload)
    return _build_partner_presence(current_user, presence)


@router.get("/users/{username}/presence", response_model=schemas.PartnerPresence)
def get_user_presence(
    username: str,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    """
    Get presence status for a user.
    """
    user = crud.get_user_by_username(db, username)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    presence = crud.get_user_presence(db, user.id)
    return _build_partner_presence(user, presence)


@router.post("/presence/status", response_model=schemas.PartnerPresence)
def update_presence_status(
    payload: schemas.PresenceUpdate,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db),
):
    """
    Update user's presence status (for iOS compatibility).
    Endpoint: POST /api/presence/status
    """
    presence = crud.upsert_user_presence(db, current_user.id, payload)
    return _build_partner_presence(current_user, presence)


@router.get("/users/presence", response_model=List[schemas.UserPresenceResponse])
def get_multiple_presences(
    user_ids: str = Query(None, description="Comma-separated user IDs"),
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db),
):
    """
    Get presence information for multiple users.
    Endpoint: GET /api/users/presence?user_ids=1,2,3
    """
    if not user_ids:
        # If no IDs specified, return presence for all users (limit to avoid performance issues)
        all_users = db.query(models.User).limit(100).all()
        user_id_list = [u.id for u in all_users]
    else:
        user_id_list = [int(uid.strip()) for uid in user_ids.split(",")]

    presences = crud.get_multiple_user_presences(db, user_id_list)
    presence_map = {p.user_id: p for p in presences}

    result = []
    for user_id in user_id_list:
        if user_id in presence_map:
            p = presence_map[user_id]
            result.append(schemas.UserPresenceResponse(
                user_id=user_id,
                status=p.status if hasattr(p, 'status') else "offline",
                last_seen=p.last_seen,
                is_typing=False
            ))
        else:
            # User has no presence record, assume offline
            result.append(schemas.UserPresenceResponse(
                user_id=user_id,
                status="offline",
                last_seen=datetime.utcnow(),
                is_typing=False
            ))

    return result


@router.delete("/users/me/", status_code=status.HTTP_204_NO_CONTENT)
def delete_current_user(
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db),
):
    """
    Delete the currently authenticated user's account.
    This is a destructive operation that removes the user and all associated data.
    Endpoint: DELETE /api/users/me/
    """
    crud.delete_user_account(db, current_user.id)
