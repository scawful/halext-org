from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app import crud, models, schemas, auth
from app.dependencies import get_db

router = APIRouter()

def _serialize_event(event: models.Event) -> schemas.Event:
    """Convert ORM Event to schema with share list populated."""
    shared_with = [share.user.username for share in event.shares]
    return schemas.Event(
        id=event.id,
        title=event.title,
        description=event.description,
        start_time=event.start_time,
        end_time=event.end_time,
        location=event.location,
        recurrence_type=event.recurrence_type,
        recurrence_interval=event.recurrence_interval,
        recurrence_end_date=event.recurrence_end_date,
        owner_id=event.owner_id,
        shared_with=shared_with,
    )

@router.post("/events/", response_model=schemas.Event)
def create_event(
    event: schemas.EventCreate,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    try:
        created = crud.create_user_event(db=db, event=event, user_id=current_user.id)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))
    return _serialize_event(created)


@router.get("/events/", response_model=List[schemas.Event])
def read_events(
    skip: int = 0,
    limit: int = 100,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    events = crud.get_events_by_user(db, user_id=current_user.id, skip=skip, limit=limit)
    return [_serialize_event(event) for event in events]


@router.get("/events/shared", response_model=List[schemas.Event])
def get_shared_events(
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    """
    Get events shared with current user.
    """
    events = crud.get_shared_events_for_user(db, user_id=current_user.id)
    return [_serialize_event(event) for event in events]


@router.put("/events/{event_id}/share", response_model=schemas.Event)
def update_event_sharing(
    event_id: int,
    payload: schemas.EventShareUpdate,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    """
    Update the share list for an event (owner only).
    """
    event = crud.get_event(db, event_id)
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")
    if event.owner_id != current_user.id:
        raise HTTPException(status_code=403, detail="Only the owner can update sharing")

    try:
        crud.sync_event_shares(db, event, payload.shared_with)
        db.commit()
        db.refresh(event)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))
    return _serialize_event(event)
