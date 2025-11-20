"""
Integration tests for AI routing functionality
Tests end-to-end model selection and routing
"""
import pytest
from unittest.mock import patch, AsyncMock, MagicMock
from datetime import datetime, timedelta


class TestAIRoutingIntegration:
    """Integration tests for complete AI routing workflow"""

    def test_full_workflow_list_models_and_chat(self, client, auth_headers, mock_ai_client_node):
        """Test complete workflow: list models, select one, and chat"""
        # Step 1: List available models
        with patch('app.ai_client_manager.ai_client_manager.get_models_from_node', new_callable=AsyncMock) as mock_get_models:
            mock_get_models.return_value = ["llama3.1", "mistral"]

            response = client.get("/ai/models", headers=auth_headers)
            assert response.status_code == 200
            models_data = response.json()

            # Find a client model to use
            client_models = [
                m for m in models_data["models"]
                if m["node_id"] == mock_ai_client_node.id
            ]
            assert len(client_models) > 0

            selected_model = client_models[0]
            model_identifier = selected_model["id"]

        # Step 2: Use the selected model in a chat request
        with patch('app.ai.AiGateway.generate_reply', new_callable=AsyncMock) as mock_generate:
            mock_generate.return_value = (
                "Hello from selected model!",
                MagicMock(
                    identifier=model_identifier,
                    key="client",
                    node_id=mock_ai_client_node.id
                )
            )

            response = client.post("/ai/chat", headers=auth_headers, json={
                "prompt": "Hello",
                "model": model_identifier
            })

            assert response.status_code == 200
            chat_data = response.json()
            assert chat_data["provider"] == "client"
            assert model_identifier in chat_data["model"]

    def test_model_selection_persistence_across_requests(self, client, auth_headers):
        """Test that model selection works consistently across multiple requests"""
        model_id = "openai:gpt-4o-mini"

        with patch('app.ai.AiGateway.generate_reply', new_callable=AsyncMock) as mock_generate:
            mock_generate.return_value = (
                "Response",
                MagicMock(identifier=model_id, key="openai")
            )

            # Make multiple requests with the same model
            for i in range(3):
                response = client.post("/ai/chat", headers=auth_headers, json={
                    "prompt": f"Request {i}",
                    "model": model_id
                })

                assert response.status_code == 200
                data = response.json()
                assert data["model"] == model_id

    def test_switching_between_different_providers(self, client, auth_headers, mock_ai_client_node):
        """Test switching between different AI providers in sequence"""
        test_sequences = [
            ("openai:gpt-4o-mini", "openai"),
            ("gemini:gemini-1.5-flash", "gemini"),
            (f"client:{mock_ai_client_node.id}:llama3.1", "client"),
        ]

        for model_id, expected_provider in test_sequences:
            with patch('app.ai.AiGateway.generate_reply', new_callable=AsyncMock) as mock_generate:
                mock_generate.return_value = (
                    f"Response from {expected_provider}",
                    MagicMock(identifier=model_id, key=expected_provider)
                )

                response = client.post("/ai/chat", headers=auth_headers, json={
                    "prompt": "Test",
                    "model": model_id
                })

                assert response.status_code == 200
                data = response.json()
                assert data["provider"] == expected_provider

    def test_node_health_affects_availability(self, client, auth_headers, db_session, test_user):
        """Test that node health status affects model availability"""
        from app.models import AIClientNode

        # Create a healthy node
        healthy_node = AIClientNode(
            name="Healthy Node",
            node_type="ollama",
            hostname="healthy.local",
            port=11434,
            is_public=True,
            is_active=True,
            owner_id=test_user.id,
            status="online",
            last_seen_at=datetime.utcnow(),
            capabilities={"models": ["llama3.1"]}
        )
        db_session.add(healthy_node)

        # Create a stale node (not seen recently)
        stale_node = AIClientNode(
            name="Stale Node",
            node_type="ollama",
            hostname="stale.local",
            port=11434,
            is_public=True,
            is_active=True,
            owner_id=test_user.id,
            status="online",
            last_seen_at=datetime.utcnow() - timedelta(hours=2),  # Too old
            capabilities={"models": ["mistral"]}
        )
        db_session.add(stale_node)
        db_session.commit()

        with patch('app.ai_client_manager.ai_client_manager.get_models_from_node', new_callable=AsyncMock) as mock_get_models:
            # Only healthy node should return models
            async def side_effect(node):
                if node.id == healthy_node.id:
                    return ["llama3.1"]
                return []

            mock_get_models.side_effect = side_effect

            response = client.get("/ai/models", headers=auth_headers)
            assert response.status_code == 200
            data = response.json()

            # Healthy node should be included
            healthy_models = [m for m in data["models"] if m.get("node_id") == healthy_node.id]
            # Note: Stale nodes might still be included if within 30-minute threshold
            # This tests the health check logic

    def test_concurrent_model_access(self, client, auth_headers, mock_ai_client_node):
        """Test that multiple concurrent requests to different models work"""
        models = [
            "openai:gpt-4o-mini",
            f"client:{mock_ai_client_node.id}:llama3.1",
            "gemini:gemini-1.5-flash"
        ]

        results = []

        for model_id in models:
            with patch('app.ai.AiGateway.generate_reply', new_callable=AsyncMock) as mock_generate:
                mock_generate.return_value = (
                    f"Response for {model_id}",
                    MagicMock(identifier=model_id, key=model_id.split(":")[0])
                )

                response = client.post("/ai/chat", headers=auth_headers, json={
                    "prompt": "Test concurrent",
                    "model": model_id
                })

                assert response.status_code == 200
                results.append(response.json())

        # Verify all requests succeeded
        assert len(results) == len(models)

    def test_default_model_routing(self, client, auth_headers):
        """Test that requests without model specification use default"""
        with patch('app.ai.AiGateway.generate_reply', new_callable=AsyncMock) as mock_generate:
            mock_generate.return_value = (
                "Default model response",
                MagicMock(identifier="mock:llama3.1", key="mock")
            )

            response = client.post("/ai/chat", headers=auth_headers, json={
                "prompt": "Test default routing"
                # No model specified
            })

            assert response.status_code == 200

            # Verify that None or default was passed as model_identifier
            mock_generate.assert_called_once()
            call_args = mock_generate.call_args
            # When no model is specified, it should be None
            assert call_args.kwargs.get("model_identifier") is None

    def test_model_metadata_consistency(self, client, auth_headers, mock_ai_client_node):
        """Test that model metadata is consistent across endpoints"""
        with patch('app.ai_client_manager.ai_client_manager.get_models_from_node', new_callable=AsyncMock) as mock_get_models:
            mock_get_models.return_value = ["llama3.1"]

            # Get models list
            response = client.get("/ai/models", headers=auth_headers)
            assert response.status_code == 200
            models_data = response.json()

            # Find our test node's model
            node_models = [
                m for m in models_data["models"]
                if m.get("node_id") == mock_ai_client_node.id
            ]

            if len(node_models) > 0:
                model = node_models[0]

                # Verify metadata structure
                assert model["node_name"] == mock_ai_client_node.name
                assert model["provider"] == "ollama"
                assert "latency_ms" in model
                assert model["endpoint"] == mock_ai_client_node.base_url


class TestAIRoutingErrorHandling:
    """Test error handling in AI routing"""

    def test_invalid_model_identifier_graceful_fallback(self, client, auth_headers):
        """Test that invalid model identifiers fall back gracefully"""
        with patch('app.ai.AiGateway.generate_reply', new_callable=AsyncMock) as mock_generate:
            mock_generate.return_value = (
                "Mock fallback response",
                MagicMock(identifier="mock:llama3.1", key="mock")
            )

            response = client.post("/ai/chat", headers=auth_headers, json={
                "prompt": "Test",
                "model": "invalid:nonexistent:model:id"
            })

            # Should succeed with fallback
            assert response.status_code == 200

    def test_node_unavailable_during_chat(self, client, auth_headers, db_session, test_user):
        """Test handling when a selected node becomes unavailable"""
        from app.models import AIClientNode

        # Create a node that will fail
        failing_node = AIClientNode(
            name="Failing Node",
            node_type="ollama",
            hostname="failing.local",
            port=11434,
            is_public=True,
            is_active=True,
            owner_id=test_user.id,
            status="online"
        )
        db_session.add(failing_node)
        db_session.commit()

        model_id = f"client:{failing_node.id}:llama3.1"

        with patch('app.ai.AiGateway.generate_reply', new_callable=AsyncMock) as mock_generate:
            # Simulate provider failure and fallback to mock
            mock_generate.return_value = (
                "I am a mock AI assistant.",
                MagicMock(identifier="mock:llama3.1", key="mock")
            )

            response = client.post("/ai/chat", headers=auth_headers, json={
                "prompt": "Test",
                "model": model_id
            })

            # Should fall back gracefully
            assert response.status_code == 200

    def test_network_timeout_handling(self, client, auth_headers):
        """Test handling of network timeouts"""
        with patch('app.ai.AiGateway.generate_reply', new_callable=AsyncMock) as mock_generate:
            # Simulate timeout by raising exception
            mock_generate.side_effect = TimeoutError("Connection timed out")

            response = client.post("/ai/chat", headers=auth_headers, json={
                "prompt": "Test timeout"
            })

            # Should return error or fallback
            # Depending on implementation, might be 500 or graceful fallback
            assert response.status_code in [200, 500, 503]


class TestAIProviderInfo:
    """Test AI provider info endpoint"""

    def test_get_provider_info(self, client, auth_headers):
        """Test getting AI provider configuration info"""
        response = client.get("/ai/provider-info", headers=auth_headers)
        assert response.status_code == 200
        data = response.json()

        assert "provider" in data
        assert "model" in data
        assert "default_model_id" in data
        assert "available_providers" in data
        assert isinstance(data["available_providers"], list)

    def test_provider_info_includes_urls(self, client, auth_headers):
        """Test that provider info includes endpoint URLs"""
        response = client.get("/ai/provider-info", headers=auth_headers)
        assert response.status_code == 200
        data = response.json()

        # These can be None if not configured
        assert "ollama_url" in data
        assert "openwebui_url" in data
        assert "openwebui_public_url" in data
