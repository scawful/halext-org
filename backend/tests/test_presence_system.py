"""
Tests for Presence System endpoints.

Target endpoints:
- POST /api/presence/status
- GET /api/users/presence
- GET /api/users/{username}/presence
- POST /api/users/me/presence

Tests cover:
- Happy path scenarios
- Authentication requirements
- Error handling (404 for non-existent users)
- Response schema validation
- Status state transitions
"""

import pytest
from datetime import datetime


class TestPresenceStatusEndpoint:
    """Test suite for POST /presence/status endpoint."""

    # --- Authentication Tests ---

    def test_presence_status_requires_authentication(self, client):
        """Verify that presence status update requires authentication."""
        response = client.post(
            "/presence/status",
            json={"status": "online"},
        )
        assert response.status_code == 401

    # --- Happy Path Tests ---

    def test_update_presence_status_online(self, client, auth_headers, test_user):
        """Update presence status to online."""
        response = client.post(
            "/presence/status",
            json={
                "status": "online",
                "is_online": True,
            },
            headers=auth_headers,
        )
        assert response.status_code == 200
        data = response.json()

        assert data["username"] == test_user.username
        assert data["is_online"] is True
        assert data["status"] == "online"
        assert "last_seen" in data

    def test_update_presence_status_away(self, client, auth_headers, test_user):
        """Update presence status to away."""
        response = client.post(
            "/presence/status",
            json={
                "status": "away",
                "status_message": "Be right back",
            },
            headers=auth_headers,
        )
        assert response.status_code == 200
        data = response.json()

        assert data["status"] == "away"
        assert data["status_message"] == "Be right back"

    def test_update_presence_status_busy(self, client, auth_headers, test_user):
        """Update presence status to busy."""
        response = client.post(
            "/presence/status",
            json={
                "status": "busy",
                "current_activity": "In a meeting",
            },
            headers=auth_headers,
        )
        assert response.status_code == 200
        data = response.json()

        assert data["status"] == "busy"
        assert data["current_activity"] == "In a meeting"

    def test_update_presence_status_offline(self, client, auth_headers, test_user):
        """Update presence status to offline."""
        response = client.post(
            "/presence/status",
            json={
                "status": "offline",
            },
            headers=auth_headers,
        )
        assert response.status_code == 200
        data = response.json()

        assert data["status"] == "offline"
        # When status is offline, is_online should be False
        assert data["is_online"] is False

    def test_update_presence_with_activity(self, client, auth_headers, test_user):
        """Update presence with current activity."""
        response = client.post(
            "/presence/status",
            json={
                "status": "online",
                "current_activity": "Working on project",
                "status_message": "Deep focus mode",
            },
            headers=auth_headers,
        )
        assert response.status_code == 200
        data = response.json()

        assert data["current_activity"] == "Working on project"
        assert data["status_message"] == "Deep focus mode"


class TestUserMePresenceEndpoint:
    """Test suite for POST /users/me/presence endpoint (alternative presence endpoint)."""

    def test_users_me_presence_requires_auth(self, client):
        """Verify users/me/presence requires authentication."""
        response = client.post(
            "/users/me/presence",
            json={"status": "online"},
        )
        assert response.status_code == 401

    def test_users_me_presence_update(self, client, auth_headers, test_user):
        """Update presence via users/me/presence endpoint."""
        response = client.post(
            "/users/me/presence",
            json={
                "status": "online",
                "is_online": True,
                "current_activity": "Testing",
            },
            headers=auth_headers,
        )
        assert response.status_code == 200
        data = response.json()

        assert data["username"] == test_user.username
        assert data["is_online"] is True


class TestGetUserPresenceEndpoint:
    """Test suite for GET /users/{username}/presence endpoint."""

    def test_get_user_presence_requires_auth(self, client):
        """Verify get user presence requires authentication."""
        response = client.get("/users/someuser/presence")
        assert response.status_code == 401

    def test_get_user_presence_success(self, client, auth_headers, test_user):
        """Get presence for an existing user."""
        # First set presence
        client.post(
            "/presence/status",
            json={"status": "online"},
            headers=auth_headers,
        )

        # Then get presence
        response = client.get(
            f"/users/{test_user.username}/presence",
            headers=auth_headers,
        )
        assert response.status_code == 200
        data = response.json()

        assert data["username"] == test_user.username
        assert "is_online" in data
        assert "status" in data
        assert "last_seen" in data

    def test_get_user_presence_default_values(self, client, auth_headers, test_user):
        """Get presence for user with no presence record returns defaults."""
        # Get presence without setting it first
        # Should return default values
        response = client.get(
            f"/users/{test_user.username}/presence",
            headers=auth_headers,
        )
        assert response.status_code == 200
        data = response.json()

        # Default values per implementation
        assert data["username"] == test_user.username
        assert data["is_online"] is True  # Default is online
        assert data["status"] == "online"

    def test_get_user_presence_not_found(self, client, auth_headers):
        """Return 404 for non-existent user."""
        response = client.get(
            "/users/nonexistent_user_12345/presence",
            headers=auth_headers,
        )
        assert response.status_code == 404
        data = response.json()
        assert "detail" in data
        assert "not found" in data["detail"].lower()


class TestGetMultiplePresencesEndpoint:
    """Test suite for GET /users/presence endpoint."""

    def test_get_multiple_presences_requires_auth(self, client):
        """Verify get multiple presences requires authentication."""
        response = client.get("/users/presence")
        assert response.status_code == 401

    def test_get_multiple_presences_no_ids(self, client, auth_headers, test_user):
        """Get presences without specifying IDs returns all users."""
        # Set presence for test user
        client.post(
            "/presence/status",
            json={"status": "online"},
            headers=auth_headers,
        )

        response = client.get("/users/presence", headers=auth_headers)
        assert response.status_code == 200
        data = response.json()

        assert isinstance(data, list)
        # Should contain at least the test user
        assert len(data) >= 1

        # Verify schema
        presence = data[0]
        assert "user_id" in presence
        assert "status" in presence
        assert "last_seen" in presence
        assert "is_typing" in presence

    def test_get_multiple_presences_with_ids(self, client, auth_headers, test_user):
        """Get presences for specific user IDs."""
        # Set presence for test user
        client.post(
            "/presence/status",
            json={"status": "online"},
            headers=auth_headers,
        )

        user_id = test_user.id
        response = client.get(
            f"/users/presence?user_ids={user_id}",
            headers=auth_headers,
        )
        assert response.status_code == 200
        data = response.json()

        assert isinstance(data, list)
        assert len(data) == 1
        assert data[0]["user_id"] == user_id

    def test_get_multiple_presences_comma_separated(
        self, client, auth_headers, test_user, db_session
    ):
        """Get presences for multiple comma-separated IDs."""
        from app import crud, schemas

        # Create another user
        user2_data = schemas.UserCreate(
            username="presence_test_user2",
            email="presence2@example.com",
            password="testpassword",
            full_name="Presence Test User 2",
        )
        user2 = crud.create_user(db=db_session, user=user2_data)

        response = client.get(
            f"/users/presence?user_ids={test_user.id},{user2.id}",
            headers=auth_headers,
        )
        assert response.status_code == 200
        data = response.json()

        assert isinstance(data, list)
        assert len(data) == 2
        user_ids = [p["user_id"] for p in data]
        assert test_user.id in user_ids
        assert user2.id in user_ids

    def test_get_presence_for_user_without_presence_record(
        self, client, auth_headers, db_session
    ):
        """Users without presence records should return offline status."""
        from app import crud, schemas

        # Create a user but don't set their presence
        new_user_data = schemas.UserCreate(
            username="no_presence_user",
            email="nopresence@example.com",
            password="testpassword",
            full_name="No Presence User",
        )
        new_user = crud.create_user(db=db_session, user=new_user_data)

        response = client.get(
            f"/users/presence?user_ids={new_user.id}",
            headers=auth_headers,
        )
        assert response.status_code == 200
        data = response.json()

        assert len(data) == 1
        assert data[0]["user_id"] == new_user.id
        assert data[0]["status"] == "offline"


class TestPresenceSchemaValidation:
    """Test response schema validation for presence endpoints."""

    def test_presence_status_response_schema(self, client, auth_headers, test_user):
        """Verify PartnerPresence schema in response."""
        response = client.post(
            "/presence/status",
            json={
                "status": "online",
                "current_activity": "Testing schema",
                "status_message": "Validating response",
            },
            headers=auth_headers,
        )
        data = response.json()

        # Required fields
        assert "username" in data
        assert "is_online" in data
        assert isinstance(data["is_online"], bool)

        # Optional fields with proper types
        assert "status" in data
        assert data["status"] in ["online", "away", "busy", "offline"]

        if data.get("current_activity"):
            assert isinstance(data["current_activity"], str)

        if data.get("status_message"):
            assert isinstance(data["status_message"], str)

        if data.get("last_seen"):
            # Should be ISO format datetime string
            assert isinstance(data["last_seen"], str)

    def test_user_presence_response_schema(self, client, auth_headers, test_user):
        """Verify UserPresenceResponse schema."""
        client.post(
            "/presence/status",
            json={"status": "online"},
            headers=auth_headers,
        )

        response = client.get(
            f"/users/presence?user_ids={test_user.id}",
            headers=auth_headers,
        )
        data = response.json()

        assert len(data) == 1
        presence = data[0]

        # Required fields per UserPresenceResponse
        assert "user_id" in presence
        assert isinstance(presence["user_id"], int)

        assert "status" in presence
        assert isinstance(presence["status"], str)

        assert "last_seen" in presence
        assert isinstance(presence["last_seen"], str)

        assert "is_typing" in presence
        assert isinstance(presence["is_typing"], bool)


class TestPresenceStateTransitions:
    """Test presence status state transitions."""

    def test_online_to_away_transition(self, client, auth_headers):
        """Test transition from online to away."""
        # Set online
        client.post(
            "/presence/status",
            json={"status": "online"},
            headers=auth_headers,
        )

        # Transition to away
        response = client.post(
            "/presence/status",
            json={"status": "away"},
            headers=auth_headers,
        )
        assert response.status_code == 200
        assert response.json()["status"] == "away"

    def test_away_to_busy_transition(self, client, auth_headers):
        """Test transition from away to busy."""
        # Set away
        client.post(
            "/presence/status",
            json={"status": "away"},
            headers=auth_headers,
        )

        # Transition to busy
        response = client.post(
            "/presence/status",
            json={"status": "busy"},
            headers=auth_headers,
        )
        assert response.status_code == 200
        assert response.json()["status"] == "busy"

    def test_busy_to_offline_transition(self, client, auth_headers):
        """Test transition from busy to offline."""
        # Set busy
        client.post(
            "/presence/status",
            json={"status": "busy"},
            headers=auth_headers,
        )

        # Transition to offline
        response = client.post(
            "/presence/status",
            json={"status": "offline"},
            headers=auth_headers,
        )
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "offline"
        assert data["is_online"] is False

    def test_offline_to_online_transition(self, client, auth_headers):
        """Test transition from offline back to online."""
        # Set offline
        client.post(
            "/presence/status",
            json={"status": "offline"},
            headers=auth_headers,
        )

        # Transition back to online
        response = client.post(
            "/presence/status",
            json={"status": "online"},
            headers=auth_headers,
        )
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "online"
        assert data["is_online"] is True


class TestPresenceIsolation:
    """Test that presence is isolated per user."""

    @pytest.fixture
    def second_user(self, db_session):
        """Create a second user for isolation testing."""
        from app import crud, schemas

        user_data = schemas.UserCreate(
            username="presence_other_user",
            email="presenceother@example.com",
            password="otherpassword",
            full_name="Presence Other User",
        )
        return crud.create_user(db=db_session, user=user_data)

    @pytest.fixture
    def second_user_headers(self, second_user):
        """Generate auth headers for second user."""
        from datetime import timedelta
        from app import auth

        access_token = auth.create_access_token(
            data={"sub": second_user.username}, expires_delta=timedelta(minutes=30)
        )
        return {"Authorization": f"Bearer {access_token}"}

    def test_presence_update_affects_only_current_user(
        self, client, auth_headers, second_user_headers, test_user, second_user
    ):
        """Updating presence only affects the authenticated user."""
        # First user sets status to busy
        client.post(
            "/presence/status",
            json={"status": "busy"},
            headers=auth_headers,
        )

        # Second user sets status to online
        client.post(
            "/presence/status",
            json={"status": "online"},
            headers=second_user_headers,
        )

        # Verify first user's presence
        response1 = client.get(
            f"/users/{test_user.username}/presence",
            headers=auth_headers,
        )
        assert response1.json()["status"] == "busy"

        # Verify second user's presence
        response2 = client.get(
            f"/users/{second_user.username}/presence",
            headers=second_user_headers,
        )
        assert response2.json()["status"] == "online"
