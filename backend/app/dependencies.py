import os
from fastapi import Header, HTTPException, status
from typing import Optional
from app.database import SessionLocal
from app.ai import AiGateway
from app.openwebui_sync import OpenWebUISync
from app.env_validation import validate_runtime_env

# Database dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Shared AI Gateway instance
ai_gateway = AiGateway()

# Shared OpenWebUI Sync instance
openwebui_sync = OpenWebUISync()

# Access Control
ACCESS_CODE = os.getenv("ACCESS_CODE", "").strip()
# For development, disable access code requirement
DEV_MODE = os.getenv("DEV_MODE", "false").lower() == "true"

# Environment Validation
ENV_CHECK = validate_runtime_env(DEV_MODE)

def verify_access_code(x_halext_code: Optional[str] = Header(default=None)):
    # Skip access code check in development mode
    if DEV_MODE:
        return
    if ACCESS_CODE and x_halext_code != ACCESS_CODE:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Access code required")
