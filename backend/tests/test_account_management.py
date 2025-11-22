"""
Tests for Account Management endpoints.

Target endpoint:
- DELETE /api/users/me/

Tests cover:
- Happy path scenarios
- Authentication requirements
- Cascading data deletion verification
- Response code validation
"""

import pytest


class TestDeleteUserAccount:
    """Test suite for DELETE /users/me/ endpoint."""

    # --- Authentication Tests ---

    def test_delete_account_requires_authentication(self, client):
        """Verify that account deletion requires authentication."""
        response = client.delete("/users/me/")
        assert response.status_code == 401

    # --- Happy Path Tests ---

    def test_delete_account_success(self, client, db_session):
        """Successfully delete user account."""
        from app import crud, schemas, auth
        from datetime import timedelta

        # Create a dedicated user for deletion
        user_data = schemas.UserCreate(
            username="delete_test_user",
            email="delete@example.com",
            password="testpassword",
            full_name="Delete Test User",
        )
        user = crud.create_user(db=db_session, user=user_data)

        # Generate auth headers
        access_token = auth.create_access_token(
            data={"sub": user.username}, expires_delta=timedelta(minutes=30)
        )
        headers = {"Authorization": f"Bearer {access_token}"}

        # Delete the account
        response = client.delete("/users/me/", headers=headers)
        assert response.status_code == 204

        # Verify user no longer exists
        deleted_user = crud.get_user(db_session, user.id)
        assert deleted_user is None

    def test_delete_account_returns_no_content(self, client, db_session):
        """Verify DELETE returns 204 No Content."""
        from app import crud, schemas, auth
        from datetime import timedelta

        user_data = schemas.UserCreate(
            username="nocontent_test_user",
            email="nocontent@example.com",
            password="testpassword",
            full_name="No Content Test User",
        )
        user = crud.create_user(db=db_session, user=user_data)

        access_token = auth.create_access_token(
            data={"sub": user.username}, expires_delta=timedelta(minutes=30)
        )
        headers = {"Authorization": f"Bearer {access_token}"}

        response = client.delete("/users/me/", headers=headers)

        # 204 No Content should have no response body
        assert response.status_code == 204
        assert response.text == "" or response.content == b""


class TestDeleteAccountCascadingData:
    """Test that user deletion properly cascades to related data."""

    @pytest.fixture
    def user_with_data(self, client, db_session):
        """Create a user with associated data for cascade testing."""
        from app import crud, schemas, auth, models
        from datetime import timedelta

        # Create user
        user_data = schemas.UserCreate(
            username="cascade_test_user",
            email="cascade@example.com",
            password="testpassword",
            full_name="Cascade Test User",
        )
        user = crud.create_user(db=db_session, user=user_data)

        # Generate auth headers
        access_token = auth.create_access_token(
            data={"sub": user.username}, expires_delta=timedelta(minutes=30)
        )
        headers = {"Authorization": f"Bearer {access_token}"}

        # Create associated data
        # Task
        task_response = client.post(
            "/tasks/",
            json={"title": "Test Task", "description": "Will be deleted"},
            headers=headers,
        )
        task_id = task_response.json()["id"]

        # Page
        page_response = client.post(
            "/pages/",
            json={"title": "Test Page"},
            headers=headers,
        )
        page_id = page_response.json()["id"]

        # Finance account
        account_response = client.post(
            "/finance/accounts",
            json={
                "account_name": "Test Account",
                "account_type": "checking",
                "balance": 100.0,
            },
            headers=headers,
        )
        account_id = account_response.json()["id"]

        # Budget
        budget_response = client.post(
            "/finance/budgets",
            json={
                "name": "Test Budget",
                "category": "food",
                "limit_amount": 200.0,
            },
            headers=headers,
        )
        budget_id = budget_response.json()["id"]

        # Set presence
        client.post(
            "/presence/status",
            json={"status": "online"},
            headers=headers,
        )

        return {
            "user": user,
            "headers": headers,
            "task_id": task_id,
            "page_id": page_id,
            "account_id": account_id,
            "budget_id": budget_id,
        }

    def test_delete_account_removes_tasks(self, client, db_session, user_with_data):
        """Verify tasks are deleted with user account."""
        from app import models

        user_id = user_with_data["user"].id

        # Delete account
        response = client.delete("/users/me/", headers=user_with_data["headers"])
        assert response.status_code == 204

        # Verify tasks are gone
        tasks = (
            db_session.query(models.Task)
            .filter(models.Task.owner_id == user_id)
            .all()
        )
        assert len(tasks) == 0

    def test_delete_account_removes_pages(self, client, db_session, user_with_data):
        """Verify pages are deleted with user account."""
        from app import models

        user_id = user_with_data["user"].id

        response = client.delete("/users/me/", headers=user_with_data["headers"])
        assert response.status_code == 204

        pages = (
            db_session.query(models.Page)
            .filter(models.Page.owner_id == user_id)
            .all()
        )
        assert len(pages) == 0

    def test_delete_account_removes_finance_data(
        self, client, db_session, user_with_data
    ):
        """Verify finance accounts and budgets are deleted."""
        from app import models

        user_id = user_with_data["user"].id

        response = client.delete("/users/me/", headers=user_with_data["headers"])
        assert response.status_code == 204

        accounts = (
            db_session.query(models.FinanceAccount)
            .filter(models.FinanceAccount.owner_id == user_id)
            .all()
        )
        assert len(accounts) == 0

        budgets = (
            db_session.query(models.FinanceBudget)
            .filter(models.FinanceBudget.owner_id == user_id)
            .all()
        )
        assert len(budgets) == 0

    def test_delete_account_removes_presence(self, client, db_session, user_with_data):
        """Verify presence record is deleted."""
        from app import models

        user_id = user_with_data["user"].id

        response = client.delete("/users/me/", headers=user_with_data["headers"])
        assert response.status_code == 204

        presence = (
            db_session.query(models.UserPresence)
            .filter(models.UserPresence.user_id == user_id)
            .first()
        )
        assert presence is None


class TestDeleteAccountTokenInvalidation:
    """Test that tokens are invalidated after account deletion."""

    def test_token_invalid_after_deletion(self, client, db_session):
        """Verify that the auth token no longer works after account deletion."""
        from app import crud, schemas, auth
        from datetime import timedelta

        # Create user
        user_data = schemas.UserCreate(
            username="token_test_user",
            email="token@example.com",
            password="testpassword",
            full_name="Token Test User",
        )
        user = crud.create_user(db=db_session, user=user_data)

        access_token = auth.create_access_token(
            data={"sub": user.username}, expires_delta=timedelta(minutes=30)
        )
        headers = {"Authorization": f"Bearer {access_token}"}

        # Delete account
        response = client.delete("/users/me/", headers=headers)
        assert response.status_code == 204

        # Try to use the same token - should fail
        response = client.get("/users/me/", headers=headers)
        # The user doesn't exist anymore, so auth should fail
        assert response.status_code in [401, 404]


class TestDeleteAccountEdgeCases:
    """Test edge cases for account deletion."""

    def test_cannot_delete_other_users_account(self, client, db_session):
        """Users cannot delete other users' accounts via /users/me/."""
        from app import crud, schemas, auth
        from datetime import timedelta

        # Create two users
        user1_data = schemas.UserCreate(
            username="user1_delete_test",
            email="user1delete@example.com",
            password="testpassword",
            full_name="User 1",
        )
        user1 = crud.create_user(db=db_session, user=user1_data)

        user2_data = schemas.UserCreate(
            username="user2_delete_test",
            email="user2delete@example.com",
            password="testpassword",
            full_name="User 2",
        )
        user2 = crud.create_user(db=db_session, user=user2_data)

        # User 1's token
        token1 = auth.create_access_token(
            data={"sub": user1.username}, expires_delta=timedelta(minutes=30)
        )
        headers1 = {"Authorization": f"Bearer {token1}"}

        # User 1 deletes their own account
        response = client.delete("/users/me/", headers=headers1)
        assert response.status_code == 204

        # User 2 should still exist
        user2_check = crud.get_user(db_session, user2.id)
        assert user2_check is not None
        assert user2_check.username == "user2_delete_test"

    def test_delete_account_with_no_associated_data(self, client, db_session):
        """Deletion works for users with no associated data."""
        from app import crud, schemas, auth
        from datetime import timedelta

        # Create user with no additional data
        user_data = schemas.UserCreate(
            username="empty_user",
            email="empty@example.com",
            password="testpassword",
            full_name="Empty User",
        )
        user = crud.create_user(db=db_session, user=user_data)

        access_token = auth.create_access_token(
            data={"sub": user.username}, expires_delta=timedelta(minutes=30)
        )
        headers = {"Authorization": f"Bearer {access_token}"}

        # Delete should succeed even with no data
        response = client.delete("/users/me/", headers=headers)
        assert response.status_code == 204

        # Verify deletion
        deleted_user = crud.get_user(db_session, user.id)
        assert deleted_user is None


class TestDeleteAdminAccount:
    """Test deletion of admin accounts."""

    def test_admin_can_delete_own_account(self, client, db_session):
        """Admin users can delete their own accounts."""
        from app import crud, schemas, auth
        from datetime import timedelta

        # Create admin user
        admin_data = schemas.UserCreate(
            username="admin_delete_test",
            email="admindelete@example.com",
            password="adminpassword",
            full_name="Admin Delete Test",
            is_admin=True,
        )
        admin = crud.create_user(db=db_session, user=admin_data)

        access_token = auth.create_access_token(
            data={"sub": admin.username}, expires_delta=timedelta(minutes=30)
        )
        headers = {"Authorization": f"Bearer {access_token}"}

        # Admin deletes their own account
        response = client.delete("/users/me/", headers=headers)
        assert response.status_code == 204

        # Verify deletion
        deleted_admin = crud.get_user(db_session, admin.id)
        assert deleted_admin is None
