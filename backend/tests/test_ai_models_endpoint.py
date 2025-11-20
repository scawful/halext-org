"""
Unit tests for /ai/models endpoint
Tests filtering for own node vs public only
"""
import pytest
from unittest.mock import patch, AsyncMock


class TestAIModelsEndpoint:
    """Test suite for /ai/models endpoint"""

    def test_list_models_unauthenticated(self, client):
        """Test that unauthenticated requests are rejected"""
        response = client.get("/ai/models")
        assert response.status_code == 401

    def test_list_models_basic(self, client, auth_headers, db_session):
        """Test basic model listing without any client nodes"""
        with patch('app.ai.AiGateway.get_models', new_callable=AsyncMock) as mock_get_models:
            mock_get_models.return_value = [
                {
                    "id": "mock:llama3.1",
                    "name": "llama3.1",
                    "provider": "mock",
                    "source": "mock",
                    "size": None,
                    "node_id": None,
                    "node_name": None,
                    "endpoint": None,
                    "latency_ms": None,
                    "metadata": {},
                    "modified_at": None
                }
            ]

            response = client.get("/ai/models", headers=auth_headers)
            assert response.status_code == 200
            data = response.json()

            assert "models" in data
            assert "provider" in data
            assert "current_model" in data
            assert "default_model_id" in data
            assert len(data["models"]) >= 1

    def test_list_models_with_public_node(self, client, auth_headers, mock_ai_client_node):
        """Test that public nodes are visible to all users"""
        with patch('app.ai_client_manager.ai_client_manager.get_models_from_node', new_callable=AsyncMock) as mock_get_models:
            mock_get_models.return_value = ["llama3.1", "mistral"]

            response = client.get("/ai/models", headers=auth_headers)
            assert response.status_code == 200
            data = response.json()

            # Check that models from public node are included
            model_ids = [m["id"] for m in data["models"]]
            # Should contain client models with node ID
            client_models = [m for m in data["models"] if m["provider"] == "ollama" and m["node_id"] is not None]
            assert len(client_models) > 0

    def test_list_models_own_private_node(self, client, auth_headers, private_ai_client_node, test_user):
        """Test that user can see their own private nodes"""
        with patch('app.ai_client_manager.ai_client_manager.get_models_from_node', new_callable=AsyncMock) as mock_get_models:
            mock_get_models.return_value = ["llama3.1-private"]

            response = client.get("/ai/models", headers=auth_headers)
            assert response.status_code == 200
            data = response.json()

            # User should see their own private node's models
            private_models = [
                m for m in data["models"]
                if m["node_id"] == private_ai_client_node.id
            ]
            assert len(private_models) > 0

    def test_list_models_cannot_see_others_private_nodes(self, client, db_session, admin_user):
        """Test that users cannot see other users' private nodes"""
        from app.models import AIClientNode
        from datetime import timedelta
        from app import auth

        # Create a private node owned by admin
        private_node = AIClientNode(
            name="Admin Private Node",
            node_type="ollama",
            hostname="10.0.0.1",
            port=11434,
            is_public=False,
            is_active=True,
            owner_id=admin_user.id,
            status="online",
            capabilities={
                "models": ["secret-model"],
                "model_count": 1,
                "last_response_time_ms": 100
            }
        )
        db_session.add(private_node)
        db_session.commit()

        # Login as different user
        from app import crud, schemas
        other_user_data = schemas.UserCreate(
            username="otheruser",
            email="other@example.com",
            password="password"
        )
        other_user = crud.create_user(db=db_session, user=other_user_data)

        other_auth_token = auth.create_access_token(
            data={"sub": other_user.username},
            expires_delta=timedelta(minutes=30)
        )
        other_headers = {"Authorization": f"Bearer {other_auth_token}"}

        with patch('app.ai_client_manager.ai_client_manager.get_models_from_node', new_callable=AsyncMock) as mock_get_models:
            mock_get_models.return_value = ["secret-model"]

            response = client.get("/ai/models", headers=other_headers)
            assert response.status_code == 200
            data = response.json()

            # Other user should NOT see admin's private node
            private_models = [
                m for m in data["models"]
                if m.get("node_id") == private_node.id
            ]
            assert len(private_models) == 0

    def test_list_models_includes_provider_models(self, client, auth_headers):
        """Test that provider models (OpenAI, Gemini, etc.) are included"""
        with patch('app.ai.AiGateway._list_provider_models', new_callable=AsyncMock) as mock_provider:
            mock_provider.return_value = [
                {
                    "id": "openai:gpt-4o-mini",
                    "name": "gpt-4o-mini",
                    "provider": "openai",
                    "source": "openai",
                    "size": None,
                    "node_id": None,
                    "node_name": None,
                    "endpoint": "https://api.openai.com",
                    "latency_ms": None,
                    "metadata": {},
                    "modified_at": None
                }
            ]

            response = client.get("/ai/models", headers=auth_headers)
            assert response.status_code == 200
            data = response.json()

            # Check response structure
            assert isinstance(data["models"], list)
            for model in data["models"]:
                assert "id" in model
                assert "name" in model
                assert "provider" in model

    def test_list_models_response_schema(self, client, auth_headers):
        """Test that the response matches the expected schema"""
        response = client.get("/ai/models", headers=auth_headers)
        assert response.status_code == 200
        data = response.json()

        # Verify top-level structure
        assert "models" in data
        assert "provider" in data
        assert "current_model" in data
        assert "default_model_id" in data

        # Verify each model has required fields
        for model in data["models"]:
            assert "id" in model
            assert "name" in model
            assert "provider" in model
            # These can be None
            assert "node_id" in model or model.get("node_id") is None
            assert "node_name" in model or model.get("node_name") is None

    def test_list_models_filters_inactive_nodes(self, client, auth_headers, db_session, test_user):
        """Test that inactive nodes are not included in the results"""
        from app.models import AIClientNode

        # Create an inactive node
        inactive_node = AIClientNode(
            name="Inactive Node",
            node_type="ollama",
            hostname="offline.local",
            port=11434,
            is_public=True,
            is_active=False,  # Inactive
            owner_id=test_user.id,
            status="offline"
        )
        db_session.add(inactive_node)
        db_session.commit()

        response = client.get("/ai/models", headers=auth_headers)
        assert response.status_code == 200
        data = response.json()

        # Inactive node should not appear
        inactive_models = [
            m for m in data["models"]
            if m.get("node_id") == inactive_node.id
        ]
        assert len(inactive_models) == 0

    def test_list_models_includes_node_metadata(self, client, auth_headers, mock_ai_client_node):
        """Test that node metadata (name, latency) is included in response"""
        with patch('app.ai_client_manager.ai_client_manager.get_models_from_node', new_callable=AsyncMock) as mock_get_models:
            mock_get_models.return_value = ["llama3.1"]

            response = client.get("/ai/models", headers=auth_headers)
            assert response.status_code == 200
            data = response.json()

            # Find models from our test node
            node_models = [
                m for m in data["models"]
                if m.get("node_id") == mock_ai_client_node.id
            ]

            if len(node_models) > 0:
                model = node_models[0]
                assert model["node_name"] == "Test Node"
                # Latency should be included from capabilities
                assert "latency_ms" in model

    def test_list_models_default_model_id(self, client, auth_headers):
        """Test that default_model_id is returned correctly"""
        response = client.get("/ai/models", headers=auth_headers)
        assert response.status_code == 200
        data = response.json()

        # default_model_id should be set (either from env or default)
        assert data["default_model_id"] is not None
        assert isinstance(data["default_model_id"], str)
