"""
Tests for Finance Budget Progress endpoints.

Target endpoints:
- GET /api/finance/budgets/progress
- GET /api/finance/budgets/{budget_id}/progress
- GET /api/finance/budgets/progress/summary
- POST /api/finance/budgets/{budget_id}/sync
- POST /api/finance/budgets/sync-all

Tests cover:
- Happy path scenarios
- Authentication requirements
- Error handling (404 for non-existent budgets)
- Response schema validation
"""

import pytest
from datetime import datetime


class TestFinanceBudgetProgressEndpoints:
    """Test suite for budget progress tracking endpoints."""

    # --- Fixture helpers ---

    @pytest.fixture
    def sample_budget(self, client, auth_headers):
        """Create a sample budget for testing."""
        response = client.post(
            "/finance/budgets",
            json={
                "name": "Groceries Budget",
                "category": "groceries",
                "limit_amount": 500.0,
                "period": "monthly",
                "emoji": "cart",
                "color_hex": "#4CAF50",
                "alert_threshold": 0.8,
                "is_active": True,
            },
            headers=auth_headers,
        )
        assert response.status_code == 201
        return response.json()

    @pytest.fixture
    def sample_account(self, client, auth_headers):
        """Create a sample finance account for transactions."""
        response = client.post(
            "/finance/accounts",
            json={
                "account_name": "Test Checking",
                "account_type": "checking",
                "balance": 1000.0,
                "currency": "USD",
            },
            headers=auth_headers,
        )
        assert response.status_code == 201
        return response.json()

    @pytest.fixture
    def sample_transaction(self, client, auth_headers, sample_account):
        """Create a sample transaction for budget progress calculation."""
        response = client.post(
            "/finance/transactions",
            json={
                "account_id": sample_account["id"],
                "amount": 150.0,
                "description": "Weekly grocery shopping",
                "category": "groceries",
                "transaction_type": "debit",
            },
            headers=auth_headers,
        )
        assert response.status_code == 201
        return response.json()

    # --- Authentication Tests ---

    def test_budget_progress_requires_authentication(self, client):
        """Verify that budget progress endpoints require authentication."""
        response = client.get("/finance/budgets/progress")
        assert response.status_code == 401

    def test_budget_progress_summary_requires_authentication(self, client):
        """Verify that budget progress summary requires authentication."""
        response = client.get("/finance/budgets/progress/summary")
        assert response.status_code == 401

    def test_single_budget_progress_requires_authentication(self, client):
        """Verify that single budget progress requires authentication."""
        response = client.get("/finance/budgets/1/progress")
        assert response.status_code == 401

    def test_budget_sync_requires_authentication(self, client):
        """Verify that budget sync requires authentication."""
        response = client.post("/finance/budgets/1/sync")
        assert response.status_code == 401

    def test_sync_all_budgets_requires_authentication(self, client):
        """Verify that sync-all budgets requires authentication."""
        response = client.post("/finance/budgets/sync-all")
        assert response.status_code == 401

    # --- GET /finance/budgets/progress Tests ---

    def test_get_budget_progress_empty_list(self, client, auth_headers):
        """Return empty list when no budgets exist."""
        response = client.get("/finance/budgets/progress", headers=auth_headers)
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        assert len(data) == 0

    def test_get_budget_progress_with_budget(self, client, auth_headers, sample_budget):
        """Return progress for existing budget."""
        response = client.get("/finance/budgets/progress", headers=auth_headers)
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        assert len(data) == 1

        progress = data[0]
        assert progress["budget_id"] == sample_budget["id"]
        assert progress["name"] == "Groceries Budget"
        assert progress["category"] == "groceries"
        assert progress["limit_amount"] == 500.0
        assert progress["period"] == "monthly"
        assert "spent" in progress
        assert "remaining" in progress
        assert "percent_used" in progress
        assert "is_over_budget" in progress
        assert "is_at_alert_threshold" in progress

    def test_get_budget_progress_with_transactions(
        self, client, auth_headers, sample_budget, sample_account, sample_transaction
    ):
        """Verify progress calculation includes transactions."""
        response = client.get("/finance/budgets/progress", headers=auth_headers)
        assert response.status_code == 200
        data = response.json()

        # Budget should show spent amount from transaction
        progress = data[0]
        assert progress["spent"] == 150.0
        assert progress["remaining"] == 350.0
        assert progress["percent_used"] == 30.0
        assert progress["transactions_count"] >= 1
        assert progress["is_over_budget"] is False

    def test_get_budget_progress_with_period_filter(
        self, client, auth_headers, sample_budget
    ):
        """Test period query parameter."""
        response = client.get(
            "/finance/budgets/progress?period=weekly", headers=auth_headers
        )
        assert response.status_code == 200
        data = response.json()
        assert len(data) == 1
        assert data[0]["period"] == "weekly"

    # --- GET /finance/budgets/{budget_id}/progress Tests ---

    def test_get_single_budget_progress(self, client, auth_headers, sample_budget):
        """Get progress for a specific budget."""
        budget_id = sample_budget["id"]
        response = client.get(
            f"/finance/budgets/{budget_id}/progress", headers=auth_headers
        )
        assert response.status_code == 200
        data = response.json()

        assert data["budget_id"] == budget_id
        assert data["name"] == "Groceries Budget"
        assert "spent" in data
        assert "remaining" in data
        assert "percent_used" in data

    def test_get_single_budget_progress_not_found(self, client, auth_headers):
        """Return 404 for non-existent budget."""
        response = client.get("/finance/budgets/99999/progress", headers=auth_headers)
        assert response.status_code == 404
        data = response.json()
        assert "detail" in data
        assert "not found" in data["detail"].lower()

    # --- GET /finance/budgets/progress/summary Tests ---

    def test_get_budget_progress_summary_empty(self, client, auth_headers):
        """Summary with no budgets returns zero totals."""
        response = client.get(
            "/finance/budgets/progress/summary", headers=auth_headers
        )
        assert response.status_code == 200
        data = response.json()

        assert "budgets" in data
        assert "total_budgeted" in data
        assert "total_spent" in data
        assert "total_remaining" in data
        assert "overall_percent_used" in data
        assert "period" in data
        assert "budgets_over_limit" in data
        assert "budgets_at_alert" in data

        assert data["total_budgeted"] == 0.0
        assert data["total_spent"] == 0.0

    def test_get_budget_progress_summary_with_budgets(
        self, client, auth_headers, sample_budget, sample_account, sample_transaction
    ):
        """Summary aggregates all budget progress."""
        response = client.get(
            "/finance/budgets/progress/summary", headers=auth_headers
        )
        assert response.status_code == 200
        data = response.json()

        assert data["total_budgeted"] == 500.0
        assert data["total_spent"] == 150.0
        assert data["total_remaining"] == 350.0
        assert data["overall_percent_used"] == 30.0
        assert data["budgets_over_limit"] == 0
        assert len(data["budgets"]) == 1

    def test_get_budget_progress_summary_period_param(
        self, client, auth_headers, sample_budget
    ):
        """Summary respects period query parameter."""
        response = client.get(
            "/finance/budgets/progress/summary?period=quarterly", headers=auth_headers
        )
        assert response.status_code == 200
        data = response.json()
        assert data["period"] == "quarterly"

    # --- POST /finance/budgets/{budget_id}/sync Tests ---

    def test_sync_budget_spent(
        self, client, auth_headers, sample_budget, sample_account, sample_transaction
    ):
        """Sync recalculates budget spent_amount from transactions."""
        budget_id = sample_budget["id"]
        response = client.post(
            f"/finance/budgets/{budget_id}/sync", headers=auth_headers
        )
        assert response.status_code == 200
        data = response.json()

        assert data["id"] == budget_id
        assert data["spent_amount"] == 150.0

    def test_sync_budget_not_found(self, client, auth_headers):
        """Return 404 when syncing non-existent budget."""
        response = client.post("/finance/budgets/99999/sync", headers=auth_headers)
        assert response.status_code == 404
        data = response.json()
        assert "not found" in data["detail"].lower()

    # --- POST /finance/budgets/sync-all Tests ---

    def test_sync_all_budgets(
        self, client, auth_headers, sample_budget, sample_account, sample_transaction
    ):
        """Sync all budgets at once."""
        response = client.post("/finance/budgets/sync-all", headers=auth_headers)
        assert response.status_code == 200
        data = response.json()

        assert isinstance(data, list)
        assert len(data) >= 1
        # Verify the budget was synced
        synced_budget = next(b for b in data if b["id"] == sample_budget["id"])
        assert synced_budget["spent_amount"] == 150.0

    def test_sync_all_budgets_empty(self, client, auth_headers):
        """Sync-all with no budgets returns empty list."""
        response = client.post("/finance/budgets/sync-all", headers=auth_headers)
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        assert len(data) == 0


class TestBudgetProgressAlertThresholds:
    """Test budget alert threshold detection."""

    @pytest.fixture
    def budget_near_limit(self, client, auth_headers):
        """Create a budget that will be near its limit."""
        response = client.post(
            "/finance/budgets",
            json={
                "name": "Tight Budget",
                "category": "entertainment",
                "limit_amount": 100.0,
                "period": "monthly",
                "alert_threshold": 0.8,
                "is_active": True,
            },
            headers=auth_headers,
        )
        return response.json()

    @pytest.fixture
    def account_for_alerts(self, client, auth_headers):
        """Create account for alert testing."""
        response = client.post(
            "/finance/accounts",
            json={
                "account_name": "Alert Test Account",
                "account_type": "checking",
                "balance": 500.0,
            },
            headers=auth_headers,
        )
        return response.json()

    def test_budget_at_alert_threshold(
        self, client, auth_headers, budget_near_limit, account_for_alerts
    ):
        """Detect when budget reaches alert threshold (80%)."""
        # Create transaction that puts budget at 85% of limit
        client.post(
            "/finance/transactions",
            json={
                "account_id": account_for_alerts["id"],
                "amount": 85.0,
                "description": "Entertainment expense",
                "category": "entertainment",
                "transaction_type": "debit",
            },
            headers=auth_headers,
        )

        response = client.get("/finance/budgets/progress", headers=auth_headers)
        data = response.json()

        progress = next(p for p in data if p["budget_id"] == budget_near_limit["id"])
        assert progress["percent_used"] == 85.0
        assert progress["is_at_alert_threshold"] is True
        assert progress["is_over_budget"] is False

    def test_budget_over_limit(
        self, client, auth_headers, budget_near_limit, account_for_alerts
    ):
        """Detect when budget exceeds its limit."""
        # Create transaction that exceeds budget
        client.post(
            "/finance/transactions",
            json={
                "account_id": account_for_alerts["id"],
                "amount": 120.0,
                "description": "Over budget expense",
                "category": "entertainment",
                "transaction_type": "debit",
            },
            headers=auth_headers,
        )

        response = client.get("/finance/budgets/progress", headers=auth_headers)
        data = response.json()

        progress = next(p for p in data if p["budget_id"] == budget_near_limit["id"])
        assert progress["spent"] == 120.0
        assert progress["is_over_budget"] is True
        assert progress["remaining"] == 0.0  # Remaining should be 0, not negative


class TestBudgetProgressIsolation:
    """Test that budget progress is isolated per user."""

    @pytest.fixture
    def second_user(self, db_session):
        """Create a second user for isolation testing."""
        from app import crud, schemas, auth

        user_data = schemas.UserCreate(
            username="otheruser",
            email="other@example.com",
            password="otherpassword",
            full_name="Other User",
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

    def test_budget_progress_user_isolation(
        self, client, auth_headers, second_user_headers
    ):
        """Users should only see their own budget progress."""
        # First user creates a budget
        client.post(
            "/finance/budgets",
            json={
                "name": "User 1 Budget",
                "category": "food",
                "limit_amount": 200.0,
                "period": "monthly",
            },
            headers=auth_headers,
        )

        # Second user creates a budget
        client.post(
            "/finance/budgets",
            json={
                "name": "User 2 Budget",
                "category": "travel",
                "limit_amount": 300.0,
                "period": "monthly",
            },
            headers=second_user_headers,
        )

        # First user should only see their budget
        response1 = client.get("/finance/budgets/progress", headers=auth_headers)
        data1 = response1.json()
        assert len(data1) == 1
        assert data1[0]["name"] == "User 1 Budget"

        # Second user should only see their budget
        response2 = client.get("/finance/budgets/progress", headers=second_user_headers)
        data2 = response2.json()
        assert len(data2) == 1
        assert data2[0]["name"] == "User 2 Budget"

    def test_cannot_access_other_users_budget_progress(
        self, client, auth_headers, second_user_headers
    ):
        """Cannot access another user's specific budget progress."""
        # First user creates a budget
        response = client.post(
            "/finance/budgets",
            json={
                "name": "Private Budget",
                "category": "personal",
                "limit_amount": 100.0,
                "period": "monthly",
            },
            headers=auth_headers,
        )
        budget_id = response.json()["id"]

        # Second user tries to access first user's budget
        response = client.get(
            f"/finance/budgets/{budget_id}/progress", headers=second_user_headers
        )
        assert response.status_code == 404
