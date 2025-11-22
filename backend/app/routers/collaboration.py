from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional

from app import crud, models, schemas, auth
from app.dependencies import get_db

router = APIRouter()


def _serialize_memory(memory: models.Memory) -> schemas.Memory:
    shared_with = [share.user.username for share in memory.shares]
    return schemas.Memory(
        id=memory.id,
        title=memory.title,
        content=memory.content,
        photos=memory.photos or [],
        location=memory.location,
        shared_with=shared_with,
        created_at=memory.created_at,
        updated_at=memory.updated_at,
        created_by=memory.owner_id,
    )


def _serialize_goal(goal: models.Goal) -> schemas.Goal:
    shared_with = [share.user.username for share in goal.shares]
    milestones = [
        schemas.Milestone(
            id=m.id,
            goal_id=m.goal_id,
            title=m.title,
            description=m.description,
            completed=m.completed,
            completed_at=m.completed_at,
            created_at=m.created_at,
        )
        for m in goal.milestones
    ]
    return schemas.Goal(
        id=goal.id,
        title=goal.title,
        description=goal.description,
        progress=goal.progress,
        shared_with=shared_with,
        milestones=milestones,
        created_at=goal.created_at,
        updated_at=goal.updated_at,
        created_by=goal.owner_id,
    )


@router.get("/memories", response_model=List[schemas.Memory])
def list_memories(
    shared_with: Optional[str] = None,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db),
):
    memories = crud.list_memories(db, current_user.id, shared_with=shared_with)
    return [_serialize_memory(memory) for memory in memories]


@router.post("/memories", response_model=schemas.Memory, status_code=status.HTTP_201_CREATED)
def create_memory(
    payload: schemas.MemoryCreate,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db),
):
    try:
        memory = crud.create_memory(db, current_user.id, payload)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))
    return _serialize_memory(memory)


@router.put("/memories/{memory_id}", response_model=schemas.Memory)
def update_memory(
    memory_id: int,
    payload: schemas.MemoryUpdate,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db),
):
    memory = crud._load_memory(db, memory_id)
    if not memory:
        raise HTTPException(status_code=404, detail="Memory not found")
    if memory.owner_id != current_user.id:
        raise HTTPException(status_code=403, detail="Only the owner can update this memory")
    try:
        updated = crud.update_memory(db, memory, payload)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))
    return _serialize_memory(updated)


@router.delete("/memories/{memory_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_memory(
    memory_id: int,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db),
):
    memory = crud._load_memory(db, memory_id)
    if not memory:
        raise HTTPException(status_code=404, detail="Memory not found")
    if memory.owner_id != current_user.id:
        raise HTTPException(status_code=403, detail="Only the owner can delete this memory")
    crud.delete_memory(db, memory)
    return


@router.get("/goals", response_model=List[schemas.Goal])
def list_goals(
    shared_with: Optional[str] = None,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db),
):
    goals = crud.list_goals(db, current_user.id, shared_with=shared_with)
    return [_serialize_goal(goal) for goal in goals]


@router.post("/goals", response_model=schemas.Goal, status_code=status.HTTP_201_CREATED)
def create_goal(
    payload: schemas.GoalCreate,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db),
):
    try:
        goal = crud.create_goal(db, current_user.id, payload)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))
    return _serialize_goal(goal)


@router.put("/goals/{goal_id}/progress", response_model=schemas.Goal)
def update_goal_progress(
    goal_id: int,
    payload: schemas.GoalProgressUpdate,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db),
):
    goal = crud._load_goal(db, goal_id)
    if not goal:
        raise HTTPException(status_code=404, detail="Goal not found")
    if goal.owner_id != current_user.id:
        raise HTTPException(status_code=403, detail="Only the owner can update this goal")
    updated = crud.update_goal_progress(db, goal, payload.progress)
    return _serialize_goal(updated)


@router.post("/goals/{goal_id}/milestones", response_model=schemas.Milestone, status_code=status.HTTP_201_CREATED)
def add_milestone(
    goal_id: int,
    payload: schemas.MilestoneCreate,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db),
):
    goal = crud._load_goal(db, goal_id)
    if not goal:
        raise HTTPException(status_code=404, detail="Goal not found")
    if goal.owner_id != current_user.id:
        raise HTTPException(status_code=403, detail="Only the owner can modify this goal")
    milestone = crud.add_milestone(db, goal, payload)
    return schemas.Milestone(
        id=milestone.id,
        goal_id=milestone.goal_id,
        title=milestone.title,
        description=milestone.description,
        completed=milestone.completed,
        completed_at=milestone.completed_at,
        created_at=milestone.created_at,
    )
