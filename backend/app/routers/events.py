from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app import crud, models, schemas, auth
from app.dependencies import get_db

router = APIRouter()

@router.post("/events/", response_model=schemas.Event)
def create_event(
    event: schemas.EventCreate,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    return crud.create_user_event(db=db, event=event, user_id=current_user.id)


@router.get("/events/", response_model=List[schemas.Event])
def read_events(
    skip: int = 0,
    limit: int = 100,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    events = crud.get_events_by_user(db, user_id=current_user.id, skip=skip, limit=limit)
    return events


@router.get("/events/shared", response_model=List[schemas.Event])
def get_shared_events(
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    """
    Get events shared with current user.
    TODO: Implement event sharing logic with participants/shared_with list.
    For now, returns empty list until sharing is implemented.
    """
    # TODO: Implement event sharing logic
    # Query events where current user is in participants/shared_with list
    # For now, return empty list until sharing is implemented
    return []
