from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from datetime import timedelta

from app import models, schemas, auth
from app.dependencies import get_db, openwebui_sync, ai_gateway

router = APIRouter()

@router.get("/integrations/openwebui", response_model=schemas.OpenWebUiStatus)
def openwebui_status():
    status_payload = ai_gateway.openwebui_status()
    return schemas.OpenWebUiStatus(**status_payload)

@router.get("/integrations/openwebui/sync/status", response_model=schemas.OpenWebUISyncStatus)
def get_openwebui_sync_status(current_user: models.User = Depends(auth.get_current_user)):
    """Get OpenWebUI sync configuration status"""
    if not openwebui_sync.is_enabled():
        raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail="OpenWebUI sync is disabled")
    status = openwebui_sync.get_sync_status()
    return schemas.OpenWebUISyncStatus(**status)

@router.post("/integrations/openwebui/sync/user", response_model=schemas.OpenWebUISyncResponse)
async def sync_user_to_openwebui(
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Sync current user to OpenWebUI"""
    if not openwebui_sync.is_enabled():
        raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail="OpenWebUI sync is disabled")

    result = await openwebui_sync.sync_user_from_halext(
        current_user.id,
        current_user.username,
        current_user.email,
        current_user.full_name
    )

    return schemas.OpenWebUISyncResponse(
        success=result.get("success", False),
        action=result.get("action"),
        user_id=result.get("user_id"),
        message=result.get("message", ""),
        error=result.get("error")
    )

@router.post("/integrations/openwebui/sso", response_model=schemas.OpenWebUISSOResponse)
async def get_openwebui_sso_link(
    request: schemas.OpenWebUISSORequest,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Generate SSO link for OpenWebUI"""
    if not openwebui_sync.is_enabled():
        raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail="OpenWebUI sync is disabled")

    # Generate SSO token
    token = await openwebui_sync.generate_sso_token(
        current_user.id,
        current_user.username,
        current_user.email,
        expires_delta=timedelta(hours=24)
    )

    # Generate SSO URL
    sso_url = await openwebui_sync.get_openwebui_login_url(
        current_user.id,
        current_user.username,
        current_user.email,
        request.redirect_to
    )

    return schemas.OpenWebUISSOResponse(
        sso_url=sso_url,
        token=token,
        expires_in=86400  # 24 hours in seconds
    )
