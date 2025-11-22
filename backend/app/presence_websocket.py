from fastapi import WebSocket, WebSocketDisconnect
from typing import Dict, Set, Optional
import json
from datetime import datetime
import asyncio

class PresenceConnectionManager:
    """
    WebSocket connection manager for real-time presence updates.
    Tracks active WebSocket connections and broadcasts presence changes.
    """

    def __init__(self):
        # Maps user_id to their WebSocket connections
        self.active_connections: Dict[int, Set[WebSocket]] = {}
        # Maps WebSocket to user_id for reverse lookup
        self.connection_users: Dict[WebSocket, int] = {}
        # Stores current presence status for each user
        self.user_presence: Dict[int, dict] = {}

    async def connect(self, websocket: WebSocket, user_id: int):
        """Accept WebSocket connection and register user."""
        await websocket.accept()

        # Add connection to user's connection set
        if user_id not in self.active_connections:
            self.active_connections[user_id] = set()
        self.active_connections[user_id].add(websocket)

        # Map connection to user
        self.connection_users[websocket] = user_id

        # Mark user as online
        await self.update_user_presence(user_id, {
            "status": "online",
            "last_seen": datetime.utcnow().isoformat()
        })

        # Send current presence status to newly connected client
        await self.send_initial_presences(websocket, user_id)

    def disconnect(self, websocket: WebSocket):
        """Remove WebSocket connection and update presence if needed."""
        if websocket not in self.connection_users:
            return

        user_id = self.connection_users[websocket]

        # Remove connection from user's set
        if user_id in self.active_connections:
            self.active_connections[user_id].discard(websocket)

            # If no more connections for this user, mark as offline
            if not self.active_connections[user_id]:
                del self.active_connections[user_id]
                asyncio.create_task(self.update_user_presence(user_id, {
                    "status": "offline",
                    "last_seen": datetime.utcnow().isoformat()
                }))

        # Remove connection mapping
        del self.connection_users[websocket]

    async def update_user_presence(self, user_id: int, presence_data: dict):
        """Update user presence and broadcast to all connected clients."""
        # Store presence data
        self.user_presence[user_id] = {
            **presence_data,
            "user_id": user_id,
            "timestamp": datetime.utcnow().isoformat()
        }

        # Broadcast presence update to all connected users
        message = {
            "type": "presence_update",
            "data": self.user_presence[user_id]
        }

        await self.broadcast_to_all(json.dumps(message))

    async def send_initial_presences(self, websocket: WebSocket, user_id: int):
        """Send current presence status of all users to newly connected client."""
        presences = []
        for uid, presence in self.user_presence.items():
            if uid != user_id:  # Don't send user's own presence
                presences.append(presence)

        message = {
            "type": "initial_presences",
            "data": presences
        }

        await websocket.send_text(json.dumps(message))

    async def broadcast_to_all(self, message: str):
        """Broadcast message to all connected clients."""
        disconnected = []

        for user_id, connections in self.active_connections.items():
            for connection in connections:
                try:
                    await connection.send_text(message)
                except:
                    # Connection is broken, mark for removal
                    disconnected.append(connection)

        # Clean up broken connections
        for connection in disconnected:
            self.disconnect(connection)

    async def broadcast_to_users(self, user_ids: list, message: str):
        """Broadcast message to specific users."""
        for user_id in user_ids:
            if user_id in self.active_connections:
                disconnected = []
                for connection in self.active_connections[user_id]:
                    try:
                        await connection.send_text(message)
                    except:
                        disconnected.append(connection)

                # Clean up broken connections
                for connection in disconnected:
                    self.disconnect(connection)

    async def handle_presence_message(self, websocket: WebSocket, data: dict):
        """Handle incoming presence-related messages from clients."""
        if websocket not in self.connection_users:
            return

        user_id = self.connection_users[websocket]
        message_type = data.get("type")

        if message_type == "update_status":
            # User is updating their status
            status = data.get("status", "online")
            await self.update_user_presence(user_id, {
                "status": status,
                "last_seen": datetime.utcnow().isoformat()
            })

        elif message_type == "typing":
            # User typing indicator
            conversation_id = data.get("conversation_id")
            is_typing = data.get("is_typing", False)

            # Broadcast typing status to other users in conversation
            typing_message = {
                "type": "typing_indicator",
                "data": {
                    "user_id": user_id,
                    "conversation_id": conversation_id,
                    "is_typing": is_typing
                }
            }

            # You would need to get conversation participants from DB
            # For now, broadcast to all
            await self.broadcast_to_all(json.dumps(typing_message))

        elif message_type == "heartbeat":
            # Keep-alive heartbeat
            await self.update_user_presence(user_id, {
                "status": self.user_presence.get(user_id, {}).get("status", "online"),
                "last_seen": datetime.utcnow().isoformat()
            })

            # Send heartbeat acknowledgment
            await websocket.send_text(json.dumps({
                "type": "heartbeat_ack",
                "timestamp": datetime.utcnow().isoformat()
            }))

    def get_online_users(self) -> list:
        """Get list of currently online user IDs."""
        return list(self.active_connections.keys())

    def get_user_presence(self, user_id: int) -> Optional[dict]:
        """Get current presence data for a user."""
        return self.user_presence.get(user_id)


# Global instance
presence_manager = PresenceConnectionManager()