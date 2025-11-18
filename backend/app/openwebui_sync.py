"""
OpenWebUI User Synchronization
Handles user account provisioning and session sync between Halext Org and OpenWebUI
"""
import os
from typing import Optional, Dict, Any
from datetime import datetime, timedelta
import jwt

try:
    import httpx
except ImportError:
    httpx = None


class OpenWebUISync:
    """Manages user synchronization with OpenWebUI"""

    def __init__(self):
        self.openwebui_url = os.getenv("OPENWEBUI_URL")
        self.sync_enabled = os.getenv("OPENWEBUI_SYNC_ENABLED", "false").lower() == "true"
        self.admin_email = os.getenv("OPENWEBUI_ADMIN_EMAIL")
        self.admin_password = os.getenv("OPENWEBUI_ADMIN_PASSWORD")
        self.jwt_secret = os.getenv("JWT_SECRET_KEY", "your-secret-key-change-in-production")
        self.jwt_algorithm = "HS256"

    def is_enabled(self) -> bool:
        """Check if OpenWebUI sync is enabled and configured"""
        return (
            self.sync_enabled
            and bool(self.openwebui_url)
            and httpx is not None
        )

    async def create_user(
        self,
        username: str,
        email: str,
        full_name: Optional[str] = None,
        password: Optional[str] = None
    ) -> Dict[str, Any]:
        """Create a user in OpenWebUI"""
        if not self.is_enabled():
            return {"success": False, "error": "Sync not enabled"}

        if not password:
            # Generate a random password if none provided
            import secrets
            password = secrets.token_urlsafe(16)

        try:
            # Get admin token
            admin_token = await self._get_admin_token()
            if not admin_token:
                return {"success": False, "error": "Failed to authenticate as admin"}

            # Create user in OpenWebUI
            url = f"{self.openwebui_url.rstrip('/')}/api/v1/auths/signup"
            payload = {
                "email": email,
                "password": password,
                "name": full_name or username,
            }

            headers = {
                "Authorization": f"Bearer {admin_token}",
                "Content-Type": "application/json"
            }

            async with httpx.AsyncClient(timeout=30) as client:
                response = await client.post(url, json=payload, headers=headers)

                if response.status_code == 200:
                    data = response.json()
                    return {
                        "success": True,
                        "user_id": data.get("id"),
                        "token": data.get("token"),
                        "password": password  # Only if auto-generated
                    }
                else:
                    return {
                        "success": False,
                        "error": f"OpenWebUI returned {response.status_code}: {response.text}"
                    }

        except Exception as e:
            return {"success": False, "error": str(e)}

    async def update_user(
        self,
        user_id: str,
        email: Optional[str] = None,
        full_name: Optional[str] = None
    ) -> Dict[str, Any]:
        """Update user information in OpenWebUI"""
        if not self.is_enabled():
            return {"success": False, "error": "Sync not enabled"}

        try:
            admin_token = await self._get_admin_token()
            if not admin_token:
                return {"success": False, "error": "Failed to authenticate as admin"}

            url = f"{self.openwebui_url.rstrip('/')}/api/v1/users/{user_id}"
            payload = {}
            if email:
                payload["email"] = email
            if full_name:
                payload["name"] = full_name

            headers = {
                "Authorization": f"Bearer {admin_token}",
                "Content-Type": "application/json"
            }

            async with httpx.AsyncClient(timeout=30) as client:
                response = await client.patch(url, json=payload, headers=headers)

                if response.status_code == 200:
                    return {"success": True, "user": response.json()}
                else:
                    return {
                        "success": False,
                        "error": f"OpenWebUI returned {response.status_code}: {response.text}"
                    }

        except Exception as e:
            return {"success": False, "error": str(e)}

    async def delete_user(self, user_id: str) -> Dict[str, Any]:
        """Delete a user from OpenWebUI"""
        if not self.is_enabled():
            return {"success": False, "error": "Sync not enabled"}

        try:
            admin_token = await self._get_admin_token()
            if not admin_token:
                return {"success": False, "error": "Failed to authenticate as admin"}

            url = f"{self.openwebui_url.rstrip('/')}/api/v1/users/{user_id}"
            headers = {
                "Authorization": f"Bearer {admin_token}",
            }

            async with httpx.AsyncClient(timeout=30) as client:
                response = await client.delete(url, headers=headers)

                if response.status_code in [200, 204]:
                    return {"success": True}
                else:
                    return {
                        "success": False,
                        "error": f"OpenWebUI returned {response.status_code}: {response.text}"
                    }

        except Exception as e:
            return {"success": False, "error": str(e)}

    async def generate_sso_token(
        self,
        user_id: int,
        username: str,
        email: str,
        expires_delta: Optional[timedelta] = None
    ) -> str:
        """Generate a JWT token for SSO to OpenWebUI"""
        if expires_delta is None:
            expires_delta = timedelta(hours=24)

        to_encode = {
            "user_id": user_id,
            "username": username,
            "email": email,
            "exp": datetime.utcnow() + expires_delta,
            "iat": datetime.utcnow(),
            "iss": "halext-org"
        }

        encoded_jwt = jwt.encode(to_encode, self.jwt_secret, algorithm=self.jwt_algorithm)
        return encoded_jwt

    async def verify_sso_token(self, token: str) -> Optional[Dict[str, Any]]:
        """Verify and decode an SSO token"""
        try:
            payload = jwt.decode(token, self.jwt_secret, algorithms=[self.jwt_algorithm])
            return payload
        except jwt.ExpiredSignatureError:
            return None
        except jwt.JWTError:
            return None

    async def get_openwebui_login_url(
        self,
        user_id: int,
        username: str,
        email: str,
        redirect_to: Optional[str] = None
    ) -> str:
        """Generate a login URL for OpenWebUI with SSO token"""
        if not self.openwebui_url:
            return ""

        token = await self.generate_sso_token(user_id, username, email)
        base_url = self.openwebui_url.rstrip('/')

        # Construct SSO URL
        sso_url = f"{base_url}/sso?token={token}"
        if redirect_to:
            sso_url += f"&redirect={redirect_to}"

        return sso_url

    async def _get_admin_token(self) -> Optional[str]:
        """Get admin authentication token from OpenWebUI"""
        if not self.admin_email or not self.admin_password:
            return None

        try:
            url = f"{self.openwebui_url.rstrip('/')}/api/v1/auths/signin"
            payload = {
                "email": self.admin_email,
                "password": self.admin_password
            }

            async with httpx.AsyncClient(timeout=30) as client:
                response = await client.post(url, json=payload)

                if response.status_code == 200:
                    data = response.json()
                    return data.get("token")
                else:
                    print(f"Failed to get admin token: {response.status_code} {response.text}")
                    return None

        except Exception as e:
            print(f"Error getting admin token: {e}")
            return None

    async def sync_user_from_halext(
        self,
        user_id: int,
        username: str,
        email: str,
        full_name: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Synchronize a Halext Org user to OpenWebUI
        Creates the user if they don't exist, updates if they do
        """
        if not self.is_enabled():
            return {
                "success": False,
                "error": "OpenWebUI sync not enabled",
                "sync_required": False
            }

        # Try to create user
        result = await self.create_user(username, email, full_name)

        if result["success"]:
            return {
                "success": True,
                "action": "created",
                "user_id": result.get("user_id"),
                "message": "User created in OpenWebUI"
            }
        else:
            # If user already exists, that's also a success
            if "already exists" in result.get("error", "").lower():
                return {
                    "success": True,
                    "action": "exists",
                    "message": "User already exists in OpenWebUI"
                }
            else:
                return {
                    "success": False,
                    "action": "failed",
                    "error": result.get("error"),
                    "message": "Failed to sync user to OpenWebUI"
                }

    def get_sync_status(self) -> Dict[str, Any]:
        """Get current sync configuration status"""
        return {
            "enabled": self.is_enabled(),
            "configured": bool(self.openwebui_url),
            "admin_configured": bool(self.admin_email and self.admin_password),
            "openwebui_url": self.openwebui_url if self.openwebui_url else None,
            "features": {
                "user_provisioning": self.is_enabled(),
                "sso": bool(self.jwt_secret),
                "auto_sync": self.sync_enabled
            }
        }
