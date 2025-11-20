"""
Admin API Routes for AI Client Management
Requires admin privileges
"""
import os
import platform
import subprocess
import time
from datetime import datetime
from pathlib import Path
from typing import List, Optional

import psutil
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy.orm import Session

from . import models, schemas
from .admin_utils import get_current_admin_user, get_db
from .ai_client_manager import ai_client_manager


router = APIRouter(prefix="/admin", tags=["admin"])

SERVICE_NAMES = ["halext-api", "nginx", "postgresql", "openwebui", "ollama"]


def _format_duration(seconds: float) -> str:
    minutes, sec = divmod(int(seconds), 60)
    hours, minutes = divmod(minutes, 60)
    days, hours = divmod(hours, 24)
    parts = []
    if days:
        parts.append(f"{days}d")
    if days or hours:
        parts.append(f"{hours}h")
    parts.append(f"{minutes}m")
    parts.append(f"{sec}s")
    return " ".join(parts)


def _check_service_status(service: str) -> str:
    try:
        result = subprocess.run(
            ["systemctl", "is-active", service],
            capture_output=True,
            text=True,
            timeout=5,
        )
        if result.returncode == 0:
            return result.stdout.strip() or "active"
        return result.stdout.strip() or result.stderr.strip() or "unknown"
    except FileNotFoundError:
        # systemctl not available (e.g., during tests)
        return "unavailable"
    except Exception:
        return "unknown"


def _get_git_info() -> dict:
    project_root = Path(__file__).resolve().parent.parent
    info = {}
    try:
        branch = subprocess.run(
            ["git", "rev-parse", "--abbrev-ref", "HEAD"],
            cwd=project_root,
            capture_output=True,
            text=True,
            timeout=5,
            check=True,
        ).stdout.strip()
        commit = subprocess.run(
            ["git", "rev-parse", "HEAD"],
            cwd=project_root,
            capture_output=True,
            text=True,
            timeout=5,
            check=True,
        ).stdout.strip()
        short_commit = subprocess.run(
            ["git", "rev-parse", "--short", "HEAD"],
            cwd=project_root,
            capture_output=True,
            text=True,
            timeout=5,
            check=True,
        ).stdout.strip()
        info.update(
            {
                "branch": branch,
                "commit": commit,
                "short_commit": short_commit,
            }
        )
        last_commit = subprocess.run(
            ["git", "log", "-1", "--format=%cI"],
            cwd=project_root,
            capture_output=True,
            text=True,
            timeout=5,
            check=True,
        ).stdout.strip()
        info["last_commit_date"] = last_commit
    except Exception:
        # Git not available; leave info empty
        pass
    return info


# Schemas
class AIClientNodeCreate(BaseModel):
    name: str
    node_type: str  # 'ollama', 'openwebui'
    hostname: str
    port: int = 11434
    is_public: bool = False
    node_metadata: dict = {}


class AIClientNodeUpdate(BaseModel):
    name: Optional[str] = None
    is_active: Optional[bool] = None
    is_public: Optional[bool] = None
    node_metadata: Optional[dict] = None


class AIClientNodeResponse(BaseModel):
    id: int
    name: str
    node_type: str
    hostname: str
    port: int
    is_active: bool
    is_public: bool
    status: str
    last_seen_at: Optional[str]
    capabilities: dict
    node_metadata: dict
    base_url: str
    owner_id: int

    class Config:
        from_attributes = True


class ConnectionTestResponse(BaseModel):
    status: str
    online: bool
    message: Optional[str] = None
    models: Optional[List[str]] = None
    model_count: Optional[int] = None
    response_time_ms: Optional[int] = None


class ModelAction(BaseModel):
    model_name: str


# Client Node Management
@router.get("/ai-clients", response_model=List[AIClientNodeResponse])
async def list_ai_clients(
    admin_user: models.User = Depends(get_current_admin_user),
    db: Session = Depends(get_db)
):
    """List all AI client nodes"""
    nodes = db.query(models.AIClientNode).all()
    return nodes


@router.post("/ai-clients", response_model=AIClientNodeResponse)
async def create_ai_client(
    client: AIClientNodeCreate,
    admin_user: models.User = Depends(get_current_admin_user),
    db: Session = Depends(get_db)
):
    """Create a new AI client node"""
    db_client = models.AIClientNode(
        **client.dict(),
        owner_id=admin_user.id
    )
    db.add(db_client)
    db.commit()
    db.refresh(db_client)

    # Test connection immediately
    await ai_client_manager.update_node_status(db, db_client.id)

    return db_client


@router.get("/ai-clients/{client_id}", response_model=AIClientNodeResponse)
async def get_ai_client(
    client_id: int,
    admin_user: models.User = Depends(get_current_admin_user),
    db: Session = Depends(get_db)
):
    """Get details of a specific AI client"""
    client = db.query(models.AIClientNode).filter(models.AIClientNode.id == client_id).first()
    if not client:
        raise HTTPException(status_code=404, detail="Client not found")
    return client


@router.put("/ai-clients/{client_id}", response_model=AIClientNodeResponse)
async def update_ai_client(
    client_id: int,
    update: AIClientNodeUpdate,
    admin_user: models.User = Depends(get_current_admin_user),
    db: Session = Depends(get_db)
):
    """Update an AI client node"""
    client = db.query(models.AIClientNode).filter(models.AIClientNode.id == client_id).first()
    if not client:
        raise HTTPException(status_code=404, detail="Client not found")

    update_data = update.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(client, field, value)

    db.commit()
    db.refresh(client)
    return client


@router.delete("/ai-clients/{client_id}", status_code=204)
async def delete_ai_client(
    client_id: int,
    admin_user: models.User = Depends(get_current_admin_user),
    db: Session = Depends(get_db)
):
    """Delete an AI client node"""
    client = db.query(models.AIClientNode).filter(models.AIClientNode.id == client_id).first()
    if not client:
        raise HTTPException(status_code=404, detail="Client not found")

    db.delete(client)
    db.commit()
    return


# Client Operations
@router.post("/ai-clients/{client_id}/test", response_model=ConnectionTestResponse)
async def test_ai_client_connection(
    client_id: int,
    admin_user: models.User = Depends(get_current_admin_user),
    db: Session = Depends(get_db)
):
    """Test connection to an AI client"""
    result = await ai_client_manager.update_node_status(db, client_id)
    return result


@router.get("/ai-clients/{client_id}/models")
async def get_client_models(
    client_id: int,
    admin_user: models.User = Depends(get_current_admin_user),
    db: Session = Depends(get_db)
):
    """Get list of models available on a client"""
    client = db.query(models.AIClientNode).filter(models.AIClientNode.id == client_id).first()
    if not client:
        raise HTTPException(status_code=404, detail="Client not found")

    models_list = await ai_client_manager.get_models_from_node(client)
    return {"models": models_list}


@router.post("/ai-clients/{client_id}/pull-model")
async def pull_model(
    client_id: int,
    action: ModelAction,
    admin_user: models.User = Depends(get_current_admin_user),
    db: Session = Depends(get_db)
):
    """Pull a model on an Ollama client"""
    client = db.query(models.AIClientNode).filter(models.AIClientNode.id == client_id).first()
    if not client:
        raise HTTPException(status_code=404, detail="Client not found")

    result = await ai_client_manager.pull_model_on_node(client, action.model_name)
    if "error" in result:
        raise HTTPException(status_code=400, detail=result["error"])

    return result


@router.post("/ai-clients/{client_id}/delete-model")
async def delete_model(
    client_id: int,
    action: ModelAction,
    admin_user: models.User = Depends(get_current_admin_user),
    db: Session = Depends(get_db)
):
    """Delete a model from an Ollama client"""
    client = db.query(models.AIClientNode).filter(models.AIClientNode.id == client_id).first()
    if not client:
        raise HTTPException(status_code=404, detail="Client not found")

    result = await ai_client_manager.delete_model_on_node(client, action.model_name)
    if "error" in result:
        raise HTTPException(status_code=400, detail=result["error"])

    return result


@router.get("/ai-clients/{client_id}/info")
async def get_client_info(
    client_id: int,
    admin_user: models.User = Depends(get_current_admin_user),
    db: Session = Depends(get_db)
):
    """Get detailed info about a client"""
    client = db.query(models.AIClientNode).filter(models.AIClientNode.id == client_id).first()
    if not client:
        raise HTTPException(status_code=404, detail="Client not found")

    info = await ai_client_manager.get_node_info(client)
    return info


@router.get("/server/status", response_model=schemas.ServerStatusResponse)
async def get_server_status(
    admin_user: models.User = Depends(get_current_admin_user),
):
    """Return server, git, and service information for admins"""
    generated_at = datetime.utcnow()
    hostname = platform.node()
    uptime_seconds = max(0.0, time.time() - psutil.boot_time())

    load_avg = {"one": 0.0, "five": 0.0, "fifteen": 0.0}
    if hasattr(os, "getloadavg"):
        try:
            load1, load5, load15 = os.getloadavg()
            load_avg = {
                "one": round(load1, 2),
                "five": round(load5, 2),
                "fifteen": round(load15, 2),
            }
        except OSError:
            pass

    vmem = psutil.virtual_memory()
    disk = psutil.disk_usage("/")

    services = [
        schemas.ServiceStatus(
            name=service,
            status=_check_service_status(service),
            last_checked=generated_at,
        )
        for service in SERVICE_NAMES
    ]

    git_info = _get_git_info()

    return schemas.ServerStatusResponse(
        hostname=hostname,
        uptime_seconds=uptime_seconds,
        uptime_human=_format_duration(uptime_seconds),
        load_avg=load_avg,
        memory=schemas.ResourceUsage(
            total=int(vmem.total),
            used=int(vmem.used),
            free=int(vmem.available),
            percent=round(vmem.percent, 2),
        ),
        disk=schemas.ResourceUsage(
            total=int(disk.total),
            used=int(disk.used),
            free=int(disk.free),
            percent=round(disk.percent, 2),
        ),
        services=services,
        git=git_info,
        generated_at=generated_at,
    )


# Health check all nodes
@router.post("/ai-clients/health-check-all")
async def health_check_all_clients(
    admin_user: models.User = Depends(get_current_admin_user),
    db: Session = Depends(get_db)
):
    """Test connection to all AI clients"""
    nodes = db.query(models.AIClientNode).filter(models.AIClientNode.is_active == True).all()

    results = []
    for node in nodes:
        result = await ai_client_manager.update_node_status(db, node.id)
        results.append({
            "node_id": node.id,
            "name": node.name,
            **result
        })

    return {"results": results}


# Frontend rebuild endpoint
@router.post("/rebuild-frontend")
async def rebuild_frontend(
    admin_user: models.User = Depends(get_current_admin_user)
):
    """Trigger a frontend rebuild (runs npm run build)"""
    import subprocess
    import os
    from pathlib import Path

    # Get project root (backend is in backend/, frontend is in frontend/)
    backend_dir = Path(__file__).parent.parent
    project_root = backend_dir.parent
    frontend_dir = project_root / "frontend"

    if not frontend_dir.exists():
        raise HTTPException(status_code=404, detail="Frontend directory not found")

    try:
        # Run npm run build in frontend directory
        result = subprocess.run(
            ["npm", "run", "build"],
            cwd=str(frontend_dir),
            capture_output=True,
            text=True,
            timeout=300  # 5 minute timeout
        )

        if result.returncode == 0:
            return {
                "status": "success",
                "message": "Frontend rebuilt successfully",
                "output": result.stdout[-500:] if result.stdout else ""  # Last 500 chars
            }
        else:
            raise HTTPException(
                status_code=500,
                detail=f"Build failed: {result.stderr}"
            )

    except subprocess.TimeoutExpired:
        raise HTTPException(
            status_code=504,
            detail="Build timed out after 5 minutes"
        )
    except FileNotFoundError:
        raise HTTPException(
            status_code=500,
            detail="npm not found - ensure Node.js is installed"
        )
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Build error: {str(e)}"
        )
