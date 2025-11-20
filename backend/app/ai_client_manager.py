"""
AI Client Node Manager
Manages connections to distributed Ollama/OpenWebUI instances
"""
import asyncio
from datetime import datetime, timedelta
from typing import List, Dict, Any, Optional
from sqlalchemy.orm import Session

try:
    import httpx
except ImportError:
    httpx = None

from .models import AIClientNode


class AIClientManager:
    """Manages AI client nodes and their health"""

    def __init__(self):
        self.client_cache: Dict[int, dict] = {}
        self.timeout = 10  # seconds

    async def test_connection(self, node: AIClientNode) -> Dict[str, Any]:
        """
        Test connection to an AI client node
        Returns status information
        """
        if httpx is None:
            return {
                "status": "error",
                "message": "httpx not installed",
                "online": False
            }

        try:
            # Test Ollama API
            if node.node_type == "ollama":
                url = f"{node.base_url}/api/tags"
                async with httpx.AsyncClient(timeout=self.timeout) as client:
                    response = await client.get(url)
                    response.raise_for_status()
                    data = response.json()

                    models = data.get("models", [])
                    return {
                        "status": "online",
                        "online": True,
                        "models": [m["name"] for m in models],
                        "model_count": len(models),
                        "response_time_ms": int(response.elapsed.total_seconds() * 1000)
                    }

            # Test OpenWebUI
            elif node.node_type == "openwebui":
                url = f"{node.base_url}/api/v1/models"
                async with httpx.AsyncClient(timeout=self.timeout) as client:
                    response = await client.get(url)
                    response.raise_for_status()
                    data = response.json()

                    models = data.get("data", [])
                    return {
                        "status": "online",
                        "online": True,
                        "models": [m.get("id") for m in models],
                        "model_count": len(models),
                        "response_time_ms": int(response.elapsed.total_seconds() * 1000)
                    }

            else:
                return {
                    "status": "error",
                    "message": f"Unknown node type: {node.node_type}",
                    "online": False
                }

        except httpx.ConnectError:
            return {
                "status": "offline",
                "message": "Connection refused - service not running",
                "online": False
            }
        except httpx.TimeoutException:
            return {
                "status": "timeout",
                "message": f"Connection timeout after {self.timeout}s",
                "online": False
            }
        except Exception as e:
            return {
                "status": "error",
                "message": str(e),
                "online": False
            }

    async def update_node_status(self, db: Session, node_id: int) -> Dict[str, Any]:
        """
        Test a node and update its status in the database
        """
        node = db.query(AIClientNode).filter(AIClientNode.id == node_id).first()
        if not node:
            return {"error": "Node not found"}

        # Test connection
        result = await self.test_connection(node)

        # Update node
        node.status = result["status"]
        node.last_seen_at = datetime.utcnow() if result["online"] else node.last_seen_at

        # Update capabilities
        if result["online"]:
            node.capabilities = {
                "models": result.get("models", []),
                "model_count": result.get("model_count", 0),
                "last_response_time_ms": result.get("response_time_ms", 0)
            }

        db.commit()
        db.refresh(node)

        return result

    async def get_available_nodes(
        self,
        db: Session,
        user_id: Optional[int] = None,
        node_type: Optional[str] = None
    ) -> List[AIClientNode]:
        """
        Get all available (online) nodes
        If user_id provided, includes their private nodes + public nodes
        """
        query = db.query(AIClientNode).filter(AIClientNode.is_active == True)

        if user_id:
            # User's own nodes OR public nodes
            from sqlalchemy import or_
            query = query.filter(
                or_(
                    AIClientNode.owner_id == user_id,
                    AIClientNode.is_public == True
                )
            )
        else:
            # Only public nodes
            query = query.filter(AIClientNode.is_public == True)

        if node_type:
            query = query.filter(AIClientNode.node_type == node_type)

        # Only return nodes that were recently online
        recent_threshold = datetime.utcnow() - timedelta(minutes=30)
        query = query.filter(
            (AIClientNode.status == "online") |
            (AIClientNode.last_seen_at >= recent_threshold)
        )

        return query.all()

    async def get_models_from_node(self, node: AIClientNode) -> List[str]:
        """Get list of available models from a node"""
        if httpx is None:
            return []

        # Fast-path: if the node already reports its models in capabilities, use them
        if node.capabilities and isinstance(node.capabilities, dict):
            caps_models = node.capabilities.get("models")
            if isinstance(caps_models, list) and caps_models:
                return caps_models

        try:
            if node.node_type == "ollama":
                url = f"{node.base_url}/api/tags"
                async with httpx.AsyncClient(timeout=self.timeout) as client:
                    response = await client.get(url)
                    response.raise_for_status()
                    data = response.json()
                    return [m["name"] for m in data.get("models", [])]

            elif node.node_type == "openwebui":
                url = f"{node.base_url}/api/v1/models"
                async with httpx.AsyncClient(timeout=self.timeout) as client:
                    response = await client.get(url)
                    response.raise_for_status()
                    data = response.json()
                    return [m.get("id") for m in data.get("data", [])]

        except Exception as e:
            print(f"Error getting models from {node.name}: {e}")
            # If capabilities were present but network failed, still return them
            if node.capabilities and isinstance(node.capabilities, dict):
                caps_models = node.capabilities.get("models")
                if isinstance(caps_models, list):
                    return caps_models
            return []

        return []

    async def pull_model_on_node(
        self,
        node: AIClientNode,
        model_name: str
    ) -> Dict[str, Any]:
        """
        Pull a model on an Ollama node
        Returns streaming status
        """
        if httpx is None:
            return {"error": "httpx not installed"}

        if node.node_type != "ollama":
            return {"error": "Only Ollama nodes support model pulling"}

        try:
            url = f"{node.base_url}/api/pull"
            payload = {"name": model_name}

            async with httpx.AsyncClient(timeout=300) as client:  # 5 min timeout
                response = await client.post(url, json=payload)
                response.raise_for_status()

                return {
                    "status": "success",
                    "message": f"Started pulling {model_name} on {node.name}"
                }

        except Exception as e:
            return {"error": str(e)}

    async def delete_model_on_node(
        self,
        node: AIClientNode,
        model_name: str
    ) -> Dict[str, Any]:
        """Delete a model from an Ollama node"""
        if httpx is None:
            return {"error": "httpx not installed"}

        if node.node_type != "ollama":
            return {"error": "Only Ollama nodes support model deletion"}

        try:
            url = f"{node.base_url}/api/delete"
            payload = {"name": model_name}

            async with httpx.AsyncClient(timeout=30) as client:
                response = await client.delete(url, json=payload)
                response.raise_for_status()

                return {
                    "status": "success",
                    "message": f"Deleted {model_name} from {node.name}"
                }

        except Exception as e:
            return {"error": str(e)}

    async def get_node_info(self, node: AIClientNode) -> Dict[str, Any]:
        """Get detailed info about a node"""
        if httpx is None:
            return {"error": "httpx not installed"}

        try:
            if node.node_type == "ollama":
                # Get version info
                url = f"{node.base_url}/api/version"
                async with httpx.AsyncClient(timeout=self.timeout) as client:
                    response = await client.get(url)
                    version_data = response.json() if response.status_code == 200 else {}

                # Get models
                models = await self.get_models_from_node(node)

                return {
                    "version": version_data.get("version", "unknown"),
                    "models": models,
                    "model_count": len(models),
                    "type": node.node_type,
                    "url": node.base_url
                }

        except Exception as e:
            return {"error": str(e)}

        return {}


# Global instance
ai_client_manager = AIClientManager()
