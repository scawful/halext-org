from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional

from app import crud, models, schemas, auth
from app.dependencies import get_db

router = APIRouter()

def _serialize_page(db: Session, page: models.Page):
    share_entries = crud.get_page_shares(db, page.id)
    share_payload = []
    for share in share_entries:
        username = share.user.username if share.user else "unknown"
        share_payload.append(
            schemas.PageShareInfo(
                user_id=share.user_id,
                username=username,
                can_edit=share.can_edit,
            )
        )
    base = schemas.Page.from_orm(page).dict()
    return schemas.PageDetail(**base, shared_with=share_payload)

def _ensure_page_edit_permission(db: Session, page: models.Page, user_id: int):
    if page.owner_id == user_id:
        return
    share = (
        db.query(models.PageShare)
        .filter(
            models.PageShare.page_id == page.id,
            models.PageShare.user_id == user_id,
        )
        .first()
    )
    if not share or not share.can_edit:
        raise HTTPException(status_code=403, detail="Not allowed to modify this page")

@router.get("/pages/", response_model=List[schemas.PageDetail])
def read_pages(
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    pages = crud.get_pages_for_user(db, user_id=current_user.id)
    return [_serialize_page(db, page) for page in pages]

@router.post("/pages/", response_model=schemas.PageDetail)
def create_page(
    page: schemas.PageCreate,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    db_page = crud.create_page(db=db, user_id=current_user.id, page=page)
    return _serialize_page(db, db_page)

@router.put("/pages/{page_id}", response_model=schemas.PageDetail)
def update_page(
    page_id: int,
    page: schemas.PageBase,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    db_page = crud.get_page(db, page_id=page_id)
    if not db_page:
        raise HTTPException(status_code=404, detail="Page not found")
    _ensure_page_edit_permission(db, db_page, current_user.id)
    updated_page = crud.update_page(db=db, db_page=db_page, page=page)
    return _serialize_page(db, updated_page)

@router.get("/layout-presets/", response_model=List[schemas.LayoutPresetInfo])
def list_layout_presets(
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    presets = crud.get_layout_presets(db)
    return [schemas.LayoutPresetInfo.from_orm(preset) for preset in presets]

@router.post("/layout-presets/", response_model=schemas.LayoutPresetInfo)
def create_layout_preset(
    preset: schemas.LayoutPresetCreate,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    db_preset = crud.create_layout_preset(db=db, preset=preset, owner_id=current_user.id)
    return schemas.LayoutPresetInfo.from_orm(db_preset)

@router.post("/layout-presets/from-page/{page_id}", response_model=schemas.LayoutPresetInfo)
def create_preset_from_page(
    page_id: int,
    name: str,
    description: Optional[str] = None,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    db_page = crud.get_page(db, page_id=page_id)
    if not db_page:
        raise HTTPException(status_code=404, detail="Page not found")
    if db_page.owner_id != current_user.id:
        raise HTTPException(status_code=403, detail="Only the owner can create presets from this page")

    preset_data = schemas.LayoutPresetCreate(
        name=name,
        description=description,
        layout=[schemas.LayoutColumn(**col) for col in db_page.layout]
    )
    db_preset = crud.create_layout_preset(db=db, preset=preset_data, owner_id=current_user.id)
    return schemas.LayoutPresetInfo.from_orm(db_preset)

@router.put("/layout-presets/{preset_id}", response_model=schemas.LayoutPresetInfo)
def update_layout_preset(
    preset_id: int,
    preset: schemas.LayoutPresetBase,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    db_preset = crud.get_layout_preset(db, preset_id=preset_id)
    if not db_preset:
        raise HTTPException(status_code=404, detail="Preset not found")
    if db_preset.is_system:
        raise HTTPException(status_code=403, detail="Cannot modify system presets")
    if db_preset.owner_id != current_user.id:
        raise HTTPException(status_code=403, detail="Only the owner can modify this preset")

    updated_preset = crud.update_layout_preset(db=db, db_preset=db_preset, preset=preset)
    return schemas.LayoutPresetInfo.from_orm(updated_preset)

@router.delete("/layout-presets/{preset_id}", status_code=204)
def delete_layout_preset(
    preset_id: int,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    db_preset = crud.get_layout_preset(db, preset_id=preset_id)
    if not db_preset:
        raise HTTPException(status_code=404, detail="Preset not found")
    if db_preset.is_system:
        raise HTTPException(status_code=403, detail="Cannot delete system presets")
    if db_preset.owner_id != current_user.id:
        raise HTTPException(status_code=403, detail="Only the owner can delete this preset")

    crud.delete_layout_preset(db, preset_id=preset_id)
    return

@router.post("/pages/{page_id}/apply-preset/{preset_id}", response_model=schemas.PageDetail)
def apply_layout_preset_to_page(
    page_id: int,
    preset_id: int,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    db_page = crud.get_page(db, page_id=page_id)
    if not db_page:
        raise HTTPException(status_code=404, detail="Page not found")
    if db_page.owner_id != current_user.id:
        raise HTTPException(status_code=403, detail="Only the owner can apply presets")
    preset = crud.get_layout_preset(db, preset_id=preset_id)
    if not preset:
        raise HTTPException(status_code=404, detail="Preset not found")
    updated_page = crud.apply_layout_preset(db, db_page, preset)
    return _serialize_page(db, updated_page)

@router.post("/pages/{page_id}/share", response_model=List[schemas.PageShareInfo])
def share_page(
    page_id: int,
    share: schemas.PageShareUpdate,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    db_page = crud.get_page(db, page_id=page_id)
    if not db_page:
        raise HTTPException(status_code=404, detail="Page not found")
    if db_page.owner_id != current_user.id:
        raise HTTPException(status_code=403, detail="Only the owner can manage sharing")
    target_user = crud.get_user_by_username(db, username=share.username)
    if not target_user:
        raise HTTPException(status_code=404, detail="Target user not found")
    crud.share_page_with_user(db=db, page_id=page_id, user_id=target_user.id, can_edit=share.can_edit)
    shares = crud.get_page_shares(db, page_id=page_id)
    return [
        schemas.PageShareInfo(
            user_id=s.user_id,
            username=s.user.username if s.user else "unknown",
            can_edit=s.can_edit,
        )
        for s in shares
    ]

@router.delete("/pages/{page_id}/share/{username}", status_code=204)
def revoke_share(
    page_id: int,
    username: str,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    db_page = crud.get_page(db, page_id=page_id)
    if not db_page:
        raise HTTPException(status_code=404, detail="Page not found")
    if db_page.owner_id != current_user.id:
        raise HTTPException(status_code=403, detail="Only the owner can modify sharing")
    target_user = crud.get_user_by_username(db, username=username)
    if not target_user:
        raise HTTPException(status_code=404, detail="Target user not found")
    crud.remove_page_share(db, page_id=page_id, user_id=target_user.id)
    return
