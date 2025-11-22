from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app import crud, models, schemas, auth
from app.dependencies import get_db

router = APIRouter()

@router.get("/social/circles", response_model=List[schemas.SocialCircle])
def list_social_circles(
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db),
):
    try:
        circles = crud.list_social_circles(db, current_user.id)
        for circle in circles:
            circle.member_count = len(circle.members)
        return circles
    except Exception as e:
        print(f"Error listing social circles: {e}")
        import traceback
        traceback.print_exc()
        # Return empty list instead of crashing
        return []


@router.post("/social/circles", response_model=schemas.SocialCircle, status_code=status.HTTP_201_CREATED)
def create_social_circle(
    payload: schemas.SocialCircleCreate,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db),
):
    circle = crud.create_social_circle(db, current_user.id, payload)
    circle.member_count = len(circle.members)
    return circle


@router.post("/social/circles/join", response_model=schemas.SocialCircle)
def join_social_circle(
    invite_code: str,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db),
):
    circle = crud.join_social_circle(db, current_user.id, invite_code)
    if not circle:
        raise HTTPException(status_code=404, detail="Circle not found")
    circle.member_count = len(circle.members)
    return circle


@router.get("/social/circles/{circle_id}/pulses", response_model=List[schemas.SocialPulse])
def list_social_pulses(
    circle_id: int,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db),
):
    return crud.list_social_pulses(db, current_user.id, circle_id=circle_id)


@router.post("/social/circles/{circle_id}/pulses", response_model=schemas.SocialPulse, status_code=status.HTTP_201_CREATED)
def create_social_pulse(
    circle_id: int,
    payload: schemas.SocialPulseCreate,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db),
):
    pulse = crud.create_social_pulse(db, current_user.id, circle_id, payload)
    if not pulse:
        raise HTTPException(status_code=404, detail="Circle not found")
    return pulse
