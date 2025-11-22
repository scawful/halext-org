#!/usr/bin/env python3
"""
Test script for presence API endpoints and WebSocket functionality.

Usage:
    python test_presence.py
"""

import requests
import json
import asyncio
import websockets
from datetime import datetime

# Configuration
BASE_URL = "http://localhost:8000"
WS_URL = "ws://localhost:8000"

# Test credentials
TEST_USER = {
    "username": "testuser",
    "password": "testpass123"
}


def test_rest_endpoints():
    """Test REST API presence endpoints."""
    print("\n=== Testing REST API Endpoints ===\n")

    # Login to get token
    print("1. Logging in...")
    login_response = requests.post(
        f"{BASE_URL}/api/token",
        data={
            "username": TEST_USER["username"],
            "password": TEST_USER["password"]
        }
    )

    if login_response.status_code != 200:
        print(f"Login failed: {login_response.text}")
        print("Please ensure a test user exists with the credentials above.")
        return None

    token = login_response.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}
    print(f"✓ Logged in successfully")

    # Test presence status update
    print("\n2. Testing presence status update...")
    presence_data = {
        "status": "away",
        "status_message": "In a meeting"
    }

    update_response = requests.post(
        f"{BASE_URL}/api/presence/status",
        json=presence_data,
        headers=headers
    )

    if update_response.status_code == 200:
        print(f"✓ Presence updated: {update_response.json()}")
    else:
        print(f"✗ Update failed: {update_response.text}")

    # Test getting user presence
    print("\n3. Testing get user presence...")
    get_response = requests.get(
        f"{BASE_URL}/api/users/{TEST_USER['username']}/presence",
        headers=headers
    )

    if get_response.status_code == 200:
        print(f"✓ Got presence: {get_response.json()}")
    else:
        print(f"✗ Get failed: {get_response.text}")

    # Test bulk presence fetch
    print("\n4. Testing bulk presence fetch...")
    bulk_response = requests.get(
        f"{BASE_URL}/api/users/presence?user_ids=1,2,3",
        headers=headers
    )

    if bulk_response.status_code == 200:
        print(f"✓ Got bulk presences: {bulk_response.json()}")
    else:
        print(f"✗ Bulk fetch failed: {bulk_response.text}")

    return token


async def test_websocket(user_id: int = 1):
    """Test WebSocket presence functionality."""
    print("\n=== Testing WebSocket Connection ===\n")

    uri = f"{WS_URL}/ws/presence/{user_id}"

    try:
        async with websockets.connect(uri) as websocket:
            print(f"✓ Connected to WebSocket at {uri}")

            # Listen for initial presences
            initial_msg = await websocket.recv()
            print(f"✓ Received initial message: {initial_msg}")

            # Send status update
            status_update = {
                "type": "update_status",
                "status": "busy"
            }
            await websocket.send(json.dumps(status_update))
            print(f"✓ Sent status update: {status_update}")

            # Send typing indicator
            typing_msg = {
                "type": "typing",
                "conversation_id": 1,
                "is_typing": True
            }
            await websocket.send(json.dumps(typing_msg))
            print(f"✓ Sent typing indicator: {typing_msg}")

            # Send heartbeat
            heartbeat = {"type": "heartbeat"}
            await websocket.send(json.dumps(heartbeat))
            print(f"✓ Sent heartbeat")

            # Listen for responses
            print("\n Listening for server responses (5 seconds)...")
            try:
                for _ in range(5):
                    response = await asyncio.wait_for(websocket.recv(), timeout=1)
                    print(f"  Received: {response}")
            except asyncio.TimeoutError:
                print("  No more messages received")

            print("\n✓ WebSocket test completed successfully")

    except Exception as e:
        print(f"✗ WebSocket test failed: {e}")


def main():
    """Run all presence tests."""
    print("=" * 50)
    print("PRESENCE API TEST SUITE")
    print("=" * 50)

    # Test REST endpoints
    token = test_rest_endpoints()

    if token:
        # Test WebSocket
        print("\nStarting WebSocket test...")
        asyncio.run(test_websocket())

    # Check health endpoint
    print("\n=== Checking Health Endpoint ===\n")
    health_response = requests.get(f"{BASE_URL}/ws/health")
    if health_response.status_code == 200:
        health_data = health_response.json()
        print(f"✓ Health check passed:")
        print(f"  - Presence connections: {health_data.get('presence_connections', 0)}")
        print(f"  - Online users: {health_data.get('online_users', [])}")
    else:
        print(f"✗ Health check failed: {health_response.text}")

    print("\n" + "=" * 50)
    print("TEST SUITE COMPLETED")
    print("=" * 50)


if __name__ == "__main__":
    main()