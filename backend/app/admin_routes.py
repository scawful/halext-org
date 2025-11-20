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

from . import models, schemas, crud
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


@router.get("/ai/credentials", response_model=List[schemas.ProviderCredentialStatus])
async def list_provider_credentials(
    admin_user: models.User = Depends(get_current_admin_user),
    db: Session = Depends(get_db),
):
    """Return masked AI provider credentials for admin view."""
    items = crud.list_provider_credentials(db, owner_id=admin_user.id)
    return [schemas.ProviderCredentialStatus(**item) for item in items]


@router.post("/ai/credentials", response_model=schemas.ProviderCredentialStatus)
async def upsert_provider_credentials(
    payload: schemas.ProviderCredentialUpdate,
    admin_user: models.User = Depends(get_current_admin_user),
    db: Session = Depends(get_db),
):
    """Store encrypted OpenAI/Gemini credentials and mark them as default."""
    provider = payload.provider.lower().strip()
    if provider not in {"openai", "gemini"}:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Unsupported provider")

    crud.set_provider_credentials(
        db,
        owner_id=admin_user.id,
        provider_type=provider,
        api_key=payload.api_key,
        model=payload.model,
        key_name=payload.key_name,
    )

    items = crud.list_provider_credentials(db, owner_id=admin_user.id)
    current = next((item for item in items if item["provider"] == provider), None)
    if not current:
        raise HTTPException(status_code=500, detail="Failed to store credentials")
    return schemas.ProviderCredentialStatus(**current)


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


# AI Model Discovery Endpoints
class CloudModelInfo(BaseModel):
    id: str
    name: str
    description: Optional[str] = None
    context_window: Optional[int] = None
    max_output_tokens: Optional[int] = None
    input_cost_per_1m: Optional[float] = None
    output_cost_per_1m: Optional[float] = None
    supports_vision: bool = False
    supports_function_calling: bool = False
    owned_by: Optional[str] = None
    created: Optional[int] = None

    class Config:
        from_attributes = True


class CloudModelsResponse(BaseModel):
    provider: str
    models: List[CloudModelInfo]
    total_count: int
    credentials_configured: bool
    error: Optional[str] = None


@router.get("/ai/models/openai", response_model=CloudModelsResponse)
async def list_openai_models(
    admin_user: models.User = Depends(get_current_admin_user),
    db: Session = Depends(get_db),
):
    """Fetch available OpenAI models from OpenAI API"""
    from .ai_providers import OpenAIProvider

    # Get stored credentials
    secret = crud.get_provider_secret(db, "openai")
    if not secret or not secret.get("api_key"):
        return CloudModelsResponse(
            provider="openai",
            models=[],
            total_count=0,
            credentials_configured=False,
            error="OpenAI API key not configured"
        )

    try:
        provider = OpenAIProvider(secret["api_key"])
        raw_models = await provider.list_models()

        # Enrich with metadata
        models = []
        for m in raw_models:
            model_id = m.get("name") or m.get("id")
            models.append(CloudModelInfo(
                id=model_id,
                name=model_id,
                description=_get_openai_model_description(model_id),
                context_window=_get_openai_context_window(model_id),
                max_output_tokens=_get_openai_max_output(model_id),
                input_cost_per_1m=_get_openai_input_cost(model_id),
                output_cost_per_1m=_get_openai_output_cost(model_id),
                supports_vision=_openai_supports_vision(model_id),
                supports_function_calling=_openai_supports_functions(model_id),
                owned_by=m.get("owned_by"),
                created=m.get("created")
            ))

        return CloudModelsResponse(
            provider="openai",
            models=models,
            total_count=len(models),
            credentials_configured=True
        )
    except Exception as e:
        return CloudModelsResponse(
            provider="openai",
            models=[],
            total_count=0,
            credentials_configured=True,
            error=str(e)
        )


@router.get("/ai/models/gemini", response_model=CloudModelsResponse)
async def list_gemini_models(
    admin_user: models.User = Depends(get_current_admin_user),
    db: Session = Depends(get_db),
):
    """Fetch available Gemini models from Google API"""
    from .ai_providers import GoogleGeminiProvider

    # Get stored credentials
    secret = crud.get_provider_secret(db, "gemini")
    if not secret or not secret.get("api_key"):
        return CloudModelsResponse(
            provider="gemini",
            models=[],
            total_count=0,
            credentials_configured=False,
            error="Gemini API key not configured"
        )

    try:
        provider = GoogleGeminiProvider(secret["api_key"])
        raw_models = await provider.list_models()

        # Enrich with metadata
        models = []
        for m in raw_models:
            model_id = m.get("name") or m.get("id")
            models.append(CloudModelInfo(
                id=model_id,
                name=model_id,
                description=m.get("description") or _get_gemini_model_description(model_id),
                context_window=_get_gemini_context_window(model_id),
                max_output_tokens=_get_gemini_max_output(model_id),
                input_cost_per_1m=_get_gemini_input_cost(model_id),
                output_cost_per_1m=_get_gemini_output_cost(model_id),
                supports_vision=_gemini_supports_vision(model_id),
                supports_function_calling=True  # All Gemini models support function calling
            ))

        return CloudModelsResponse(
            provider="gemini",
            models=models,
            total_count=len(models),
            credentials_configured=True
        )
    except Exception as e:
        return CloudModelsResponse(
            provider="gemini",
            models=[],
            total_count=0,
            credentials_configured=True,
            error=str(e)
        )


# Model metadata helpers for OpenAI
def _get_openai_model_description(model_id: str) -> str:
    descriptions = {
        "gpt-4o": "Most advanced multimodal model, best for complex tasks",
        "gpt-4o-mini": "Affordable and intelligent small model for fast, lightweight tasks",
        "gpt-4-turbo": "Latest GPT-4 Turbo model with vision capabilities",
        "gpt-4": "GPT-4 base model, high intelligence",
        "gpt-3.5-turbo": "Fast, inexpensive model for simple tasks",
        "gpt-3.5-turbo-16k": "Extended context version of GPT-3.5 Turbo",
    }
    return descriptions.get(model_id, "OpenAI language model")


def _get_openai_context_window(model_id: str) -> int:
    windows = {
        "gpt-4o": 128000,
        "gpt-4o-mini": 128000,
        "gpt-4-turbo": 128000,
        "gpt-4": 8192,
        "gpt-3.5-turbo": 16385,
        "gpt-3.5-turbo-16k": 16385,
    }
    return windows.get(model_id, 8192)


def _get_openai_max_output(model_id: str) -> int:
    outputs = {
        "gpt-4o": 16384,
        "gpt-4o-mini": 16384,
        "gpt-4-turbo": 4096,
        "gpt-4": 8192,
        "gpt-3.5-turbo": 4096,
    }
    return outputs.get(model_id, 4096)


def _get_openai_input_cost(model_id: str) -> Optional[float]:
    """Cost per 1M input tokens in USD"""
    costs = {
        "gpt-4o": 5.00,
        "gpt-4o-mini": 0.15,
        "gpt-4-turbo": 10.00,
        "gpt-4": 30.00,
        "gpt-3.5-turbo": 0.50,
    }
    return costs.get(model_id)


def _get_openai_output_cost(model_id: str) -> Optional[float]:
    """Cost per 1M output tokens in USD"""
    costs = {
        "gpt-4o": 15.00,
        "gpt-4o-mini": 0.60,
        "gpt-4-turbo": 30.00,
        "gpt-4": 60.00,
        "gpt-3.5-turbo": 1.50,
    }
    return costs.get(model_id)


def _openai_supports_vision(model_id: str) -> bool:
    vision_models = {"gpt-4o", "gpt-4o-mini", "gpt-4-turbo", "gpt-4-vision-preview"}
    return model_id in vision_models


def _openai_supports_functions(model_id: str) -> bool:
    # All modern GPT models support function calling
    return "gpt-4" in model_id or "gpt-3.5" in model_id


# Model metadata helpers for Gemini
def _get_gemini_model_description(model_id: str) -> str:
    descriptions = {
        "gemini-1.5-pro": "Most capable Gemini model, best for complex reasoning",
        "gemini-1.5-flash": "Fast and versatile performance across a variety of tasks",
        "gemini-1.0-pro": "Previous generation Gemini model",
        "gemini-2.0-flash": "Next generation flash model with enhanced capabilities",
    }
    return descriptions.get(model_id, "Google Gemini model")


def _get_gemini_context_window(model_id: str) -> int:
    windows = {
        "gemini-1.5-pro": 2000000,  # 2M tokens
        "gemini-1.5-flash": 1000000,  # 1M tokens
        "gemini-1.0-pro": 32760,
        "gemini-2.0-flash": 1000000,
    }
    # Default to 1M for unknown Gemini models
    for key in windows:
        if key in model_id:
            return windows[key]
    return 1000000


def _get_gemini_max_output(model_id: str) -> int:
    outputs = {
        "gemini-1.5-pro": 8192,
        "gemini-1.5-flash": 8192,
        "gemini-1.0-pro": 2048,
        "gemini-2.0-flash": 8192,
    }
    return outputs.get(model_id, 8192)


def _get_gemini_input_cost(model_id: str) -> Optional[float]:
    """Cost per 1M input tokens in USD"""
    costs = {
        "gemini-1.5-pro": 1.25,  # <= 128K context
        "gemini-1.5-flash": 0.075,  # <= 128K context
        "gemini-1.0-pro": 0.50,
    }
    # Gemini 2.0 Flash is free during preview
    if "gemini-2.0-flash" in model_id:
        return 0.0
    return costs.get(model_id)


def _get_gemini_output_cost(model_id: str) -> Optional[float]:
    """Cost per 1M output tokens in USD"""
    costs = {
        "gemini-1.5-pro": 5.00,
        "gemini-1.5-flash": 0.30,
        "gemini-1.0-pro": 1.50,
    }
    if "gemini-2.0-flash" in model_id:
        return 0.0
    return costs.get(model_id)


def _gemini_supports_vision(model_id: str) -> bool:
    # All Gemini 1.5+ models support vision
    return "gemini-1.5" in model_id or "gemini-2.0" in model_id
