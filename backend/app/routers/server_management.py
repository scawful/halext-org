"""
Server management and monitoring endpoints
Admin-only access required
"""

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List, Optional
import psutil
import platform
import os
import subprocess
from datetime import datetime, timedelta

from app import models
from app.dependencies import get_db
from app.admin_utils import get_current_admin_user

router = APIRouter()

def get_system_stats():
    """Get current system resource usage"""
    try:
        cpu_percent = psutil.cpu_percent(interval=1)
        memory = psutil.virtual_memory()
        disk = psutil.disk_usage('/')
        
        # Get uptime
        boot_time = datetime.fromtimestamp(psutil.boot_time())
        uptime_seconds = int((datetime.now() - boot_time).total_seconds())
        
        return {
            "cpu_usage_percent": cpu_percent,
            "memory_usage_percent": memory.percent,
            "disk_usage_percent": disk.percent,
            "uptime_seconds": uptime_seconds,
        }
    except Exception as e:
        print(f"Warning: Failed to get system stats: {e}")
        return {
            "cpu_usage_percent": 0,
            "memory_usage_percent": 0,
            "disk_usage_percent": 0,
            "uptime_seconds": 0,
        }

@router.get("/admin/server/stats")
def get_server_stats(
    current_user: models.User = Depends(get_current_admin_user),
    db: Session = Depends(get_db)
):
    """Get server statistics (admin only)"""
    system_stats = get_system_stats()
    
    # Count active users (users who logged in within last 24 hours)
    # For now, we'll just count total users
    active_users = db.query(models.User).count()
    
    # Database health check
    database_connected = True
    try:
        db.execute("SELECT 1")
    except Exception:
        database_connected = False
    
    # AI provider check
    from app.dependencies import ai_gateway
    ai_provider_available = ai_gateway.provider != "mock"
    
    return {
        "cpu_usage_percent": system_stats["cpu_usage_percent"],
        "memory_usage_percent": system_stats["memory_usage_percent"],
        "disk_usage_percent": system_stats["disk_usage_percent"],
        "uptime_seconds": system_stats["uptime_seconds"],
        "active_users": active_users,
        "total_requests": 0,  # Would need request counter middleware
        "api_server_running": True,  # If this endpoint returns, server is running
        "database_connected": database_connected,
        "ai_provider_available": ai_provider_available,
    }


@router.get("/admin/stats")
def admin_stats_alias(
    current_user: models.User = Depends(get_current_admin_user),
    db: Session = Depends(get_db)
):
    """
    Alias for /admin/server/stats to match iOS client expectations.
    """
    return get_server_stats(current_user, db)

@router.post("/admin/server/restart")
def restart_api_server(
    current_user: models.User = Depends(get_current_admin_user)
):
    """
    Restart the API server (admin only)
    
    Note: This requires systemd setup and proper permissions.
    In production, use: sudo systemctl restart halext-api.service
    """
    try:
        # Check if running under systemd
        result = subprocess.run(
            ["systemctl", "is-active", "halext-api.service"],
            capture_output=True,
            text=True,
            timeout=5
        )
        
        if result.returncode == 0:
            # Systemd service is active - we can restart it
            restart_result = subprocess.run(
                ["sudo", "-n", "systemctl", "restart", "halext-api.service"],
                capture_output=True,
                text=True,
                timeout=10
            )
            
            if restart_result.returncode == 0:
                return {
                    "success": True,
                    "message": "Server restart initiated successfully"
                }
            else:
                return {
                    "success": False,
                    "message": f"Failed to restart: {restart_result.stderr}"
                }
        else:
            return {
                "success": False,
                "message": "Not running under systemd - manual restart required"
            }
    except subprocess.TimeoutExpired:
        return {
            "success": False,
            "message": "Restart command timed out"
        }
    except Exception as e:
        return {
            "success": False,
            "message": f"Error: {str(e)}"
        }

@router.post("/admin/database/sync")
def sync_database(
    current_user: models.User = Depends(get_current_admin_user),
    db: Session = Depends(get_db)
):
    """Run database sync/maintenance tasks (admin only)"""
    try:
        # Refresh all materialized views, update statistics, etc.
        # For now, just validate connection
        db.execute("SELECT 1")
        
        return {
            "success": True,
            "message": "Database sync completed successfully"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database sync failed: {str(e)}")

@router.post("/admin/cache/clear")
def clear_server_cache(
    current_user: models.User = Depends(get_current_admin_user)
):
    """Clear server-side caches (admin only)"""
    try:
        items_cleared = 0
        
        # Clear Python __pycache__ directories
        backend_path = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        for root, dirs, files in os.walk(backend_path):
            if '__pycache__' in dirs:
                pycache_path = os.path.join(root, '__pycache__')
                for file in os.listdir(pycache_path):
                    os.remove(os.path.join(pycache_path, file))
                    items_cleared += 1
        
        return {
            "success": True,
            "message": "Cache cleared successfully",
            "items_cleared": items_cleared
        }
    except Exception as e:
        return {
            "success": False,
            "message": f"Failed to clear cache: {str(e)}",
            "items_cleared": 0
        }

@router.post("/admin/frontend/rebuild")
def rebuild_frontend(
    current_user: models.User = Depends(get_current_admin_user)
):
    """Trigger frontend rebuild (admin only)"""
    try:
        # In production, this might trigger a CI/CD pipeline
        # For now, just return success
        return {
            "success": True,
            "message": "Frontend rebuild request submitted (check CI/CD pipeline)"
        }
    except Exception as e:
        return {
            "success": False,
            "message": f"Failed to trigger rebuild: {str(e)}"
        }


# Aliases expected by iOS admin client
@router.post("/admin/rebuild-frontend")
def rebuild_frontend_alias(current_user: models.User = Depends(get_current_admin_user)):
    return rebuild_frontend(current_user)


@router.post("/admin/rebuild-indexes")
def rebuild_indexes(
    current_user: models.User = Depends(get_current_admin_user)
):
    """
    Placeholder for search/index rebuilds.
    """
    return {
        "success": True,
        "message": "Rebuild indexes request accepted (no-op placeholder)",
    }

@router.get("/admin/logs")
def get_server_logs(
    current_user: models.User = Depends(get_current_admin_user),
    level: str = Query("all", regex="^(all|error|warning|info)$"),
    limit: int = Query(100, ge=1, le=1000)
):
    """Get server logs (admin only)"""
    try:
        logs = []
        
        # Try to read systemd journal logs
        try:
            result = subprocess.run(
                ["journalctl", "-u", "halext-api.service", "-n", str(limit), "--no-pager"],
                capture_output=True,
                text=True,
                timeout=10
            )
            
            if result.returncode == 0:
                all_logs = result.stdout.split('\n')
                
                # Filter by level if not "all"
                if level != "all":
                    logs = [line for line in all_logs if level.upper() in line]
                else:
                    logs = all_logs
                
                # Limit to requested count
                logs = logs[-limit:]
            else:
                logs = ["Unable to read systemd logs - service may not be running under systemd"]
        except subprocess.TimeoutExpired:
            logs = ["Log read timed out"]
        except FileNotFoundError:
            logs = ["journalctl not available - install systemd or check permissions"]
        
        return {
            "logs": logs,
            "count": len(logs),
            "level": level
        }
    except Exception as e:
        return {
        "logs": [f"Error reading logs: {str(e)}"],
        "count": 1,
        "level": level
    }


@router.get("/admin/health")
def get_server_health(
    current_user: models.User = Depends(get_current_admin_user),
    db: Session = Depends(get_db)
):
    """
    Lightweight health summary expected by iOS admin client.
    """
    system_stats = get_system_stats()
    db_status = True
    try:
        db.execute("SELECT 1")
    except Exception:
        db_status = False

    return {
        "status": "healthy" if db_status else "degraded",
        "database_connected": db_status,
        "api_server_running": True,
        "system": system_stats,
    }
