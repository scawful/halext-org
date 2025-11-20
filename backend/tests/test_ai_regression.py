"""
Regression tests for AI routing
Tests backward compatibility and edge cases
"""
import pytest
from unittest.mock import patch, AsyncMock, MagicMock


class TestBackwardCompatibility:
    """Tests to ensure backward compatibility with existing AI requests"""

    def test_legacy_chat_without_model_param(self, client, auth_headers):
        """Test that legacy chat requests without model parameter still work"""
        with patch('app.ai.AiGateway.generate_reply', new_callable=AsyncMock) as mock_generate:
            mock_generate.return_value = (
                "Response",
                MagicMock(identifier="mock:llama3.1", key="mock")
            )

            # Old-style request without model parameter
            response = client.post("/ai/chat", headers=auth_headers, json={
                "prompt": "Hello",
                "history": []
            })

            assert response.status_code == 200
            data = response.json()
            assert "response" in data
            assert "model" in data
            assert "provider" in data

    def test_legacy_embeddings_request(self, client, auth_headers):
        """Test that legacy embeddings requests still work"""
        with patch('app.ai.AiGateway.generate_embeddings', new_callable=AsyncMock) as mock_embeddings:
            mock_embeddings.return_value = [0.1] * 384

            response = client.post("/ai/embeddings", headers=auth_headers, json={
                "text": "Test text"
                # No model specified
            })

            assert response.status_code == 200
            data = response.json()
            assert "embeddings" in data

    def test_existing_conversation_flow(self, client, auth_headers, db_session, test_user):
        """Test that existing conversation workflows are not broken"""
        from app import crud, schemas

        # Create a conversation
        conv_data = schemas.ConversationCreate(
            title="Test Chat",
            mode="solo",
            with_ai=True
        )
        conversation = crud.create_conversation(db_session, conv_data, test_user.id)

        # Post a message
        with patch('app.ai.AiGateway.generate_reply', new_callable=AsyncMock) as mock_generate:
            mock_generate.return_value = (
                "AI response",
                MagicMock(identifier="mock:llama3.1", key="mock")
            )

            response = client.post(
                f"/conversations/{conversation.id}/messages",
                headers=auth_headers,
                json={"content": "Hello AI"}
            )

            assert response.status_code == 200

    def test_response_schema_compatibility(self, client, auth_headers):
        """Test that response schema matches expected format"""
        with patch('app.ai.AiGateway.generate_reply', new_callable=AsyncMock) as mock_generate:
            mock_generate.return_value = (
                "Test response",
                MagicMock(identifier="mock:llama3.1", key="mock")
            )

            response = client.post("/ai/chat", headers=auth_headers, json={
                "prompt": "Test"
            })

            assert response.status_code == 200
            data = response.json()

            # Verify expected fields exist
            required_fields = ["response", "model", "provider"]
            for field in required_fields:
                assert field in data, f"Missing required field: {field}"


class TestNoProvidersConfigured:
    """Tests for when no AI providers are configured"""

    def test_models_list_shows_mock_when_no_providers(self, client, auth_headers):
        """Test that mock models are shown when no real providers are available"""
        with patch('app.ai.AiGateway.get_models', new_callable=AsyncMock) as mock_get_models:
            # Return only mock models
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
                },
                {
                    "id": "mock:mistral",
                    "name": "mistral",
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

            # Should have mock models
            assert len(data["models"]) > 0
            assert any(m["provider"] == "mock" for m in data["models"])

    def test_chat_works_with_mock_provider(self, client, auth_headers):
        """Test that chat still works with only mock provider"""
        with patch('app.ai.AiGateway.generate_reply', new_callable=AsyncMock) as mock_generate:
            mock_generate.return_value = (
                "I am a mock AI assistant. Connect me to a real backend to get started!",
                MagicMock(identifier="mock:llama3.1", key="mock")
            )

            response = client.post("/ai/chat", headers=auth_headers, json={
                "prompt": "Hello"
            })

            assert response.status_code == 200
            data = response.json()
            assert "mock" in data["response"].lower()

    def test_provider_info_with_no_providers(self, client, auth_headers):
        """Test provider info endpoint when no providers configured"""
        response = client.get("/ai/provider-info", headers=auth_headers)
        assert response.status_code == 200
        data = response.json()

        # Should return info even with no providers
        assert "provider" in data
        assert "available_providers" in data
        # May be empty or contain only 'mock'
        assert isinstance(data["available_providers"], list)


class TestEdgeCases:
    """Test edge cases and unusual scenarios"""

    def test_empty_prompt(self, client, auth_headers):
        """Test handling of empty prompt"""
        response = client.post("/ai/chat", headers=auth_headers, json={
            "prompt": ""
        })

        # Should either reject or handle gracefully
        assert response.status_code in [200, 422]

    def test_very_long_prompt(self, client, auth_headers):
        """Test handling of very long prompts"""
        long_prompt = "Test " * 10000  # Very long prompt

        with patch('app.ai.AiGateway.generate_reply', new_callable=AsyncMock) as mock_generate:
            mock_generate.return_value = (
                "Response to long prompt",
                MagicMock(identifier="mock:llama3.1", key="mock")
            )

            response = client.post("/ai/chat", headers=auth_headers, json={
                "prompt": long_prompt
            })

            # Should handle gracefully (might truncate or reject)
            assert response.status_code in [200, 413, 422]

    def test_special_characters_in_prompt(self, client, auth_headers):
        """Test handling of special characters in prompts"""
        special_prompts = [
            "Test with emoji: 🚀🌟",
            "Test with unicode: こんにちは",
            "Test with symbols: <>&\"'",
            "Test\nwith\nnewlines",
            "Test\twith\ttabs"
        ]

        for prompt in special_prompts:
            with patch('app.ai.AiGateway.generate_reply', new_callable=AsyncMock) as mock_generate:
                mock_generate.return_value = (
                    "Response",
                    MagicMock(identifier="mock:llama3.1", key="mock")
                )

                response = client.post("/ai/chat", headers=auth_headers, json={
                    "prompt": prompt
                })

                assert response.status_code == 200

    def test_malformed_model_identifier(self, client, auth_headers):
        """Test handling of malformed model identifiers"""
        malformed_ids = [
            ":",
            ":::",
            "client:",
            "client:abc:model",  # Invalid node ID
            "client:-1:model",  # Negative node ID
        ]

        for model_id in malformed_ids:
            with patch('app.ai.AiGateway.generate_reply', new_callable=AsyncMock) as mock_generate:
                mock_generate.return_value = (
                    "Fallback response",
                    MagicMock(identifier="mock:llama3.1", key="mock")
                )

                response = client.post("/ai/chat", headers=auth_headers, json={
                    "prompt": "Test",
                    "model": model_id
                })

                # Should fall back gracefully
                assert response.status_code == 200

    def test_nonexistent_node_id(self, client, auth_headers):
        """Test handling of requests for non-existent nodes"""
        with patch('app.ai.AiGateway.generate_reply', new_callable=AsyncMock) as mock_generate:
            mock_generate.return_value = (
                "Mock fallback",
                MagicMock(identifier="mock:llama3.1", key="mock")
            )

            response = client.post("/ai/chat", headers=auth_headers, json={
                "prompt": "Test",
                "model": "client:99999:llama3.1"  # Non-existent node
            })

            # Should fall back to mock
            assert response.status_code == 200
            data = response.json()
            assert data["provider"] in ["mock", "client"]

    def test_history_with_invalid_format(self, client, auth_headers):
        """Test handling of invalid history format"""
        invalid_histories = [
            [{"invalid": "format"}],
            [{"role": "user"}],  # Missing content
            [{"content": "test"}],  # Missing role
        ]

        for history in invalid_histories:
            with patch('app.ai.AiGateway.generate_reply', new_callable=AsyncMock) as mock_generate:
                mock_generate.return_value = (
                    "Response",
                    MagicMock(identifier="mock:llama3.1", key="mock")
                )

                response = client.post("/ai/chat", headers=auth_headers, json={
                    "prompt": "Test",
                    "history": history
                })

                # May accept or reject depending on validation
                assert response.status_code in [200, 422]

    def test_concurrent_requests_same_user(self, client, auth_headers):
        """Test multiple concurrent requests from same user"""
        with patch('app.ai.AiGateway.generate_reply', new_callable=AsyncMock) as mock_generate:
            mock_generate.return_value = (
                "Response",
                MagicMock(identifier="mock:llama3.1", key="mock")
            )

            # Make multiple requests quickly
            responses = []
            for i in range(5):
                response = client.post("/ai/chat", headers=auth_headers, json={
                    "prompt": f"Request {i}"
                })
                responses.append(response)

            # All should succeed
            assert all(r.status_code == 200 for r in responses)

    def test_node_with_empty_models_list(self, client, auth_headers, db_session, test_user):
        """Test handling of nodes that report no models"""
        from app.models import AIClientNode

        empty_node = AIClientNode(
            name="Empty Node",
            node_type="ollama",
            hostname="empty.local",
            port=11434,
            is_public=True,
            is_active=True,
            owner_id=test_user.id,
            status="online",
            capabilities={"models": [], "model_count": 0}
        )
        db_session.add(empty_node)
        db_session.commit()

        with patch('app.ai_client_manager.ai_client_manager.get_models_from_node', new_callable=AsyncMock) as mock_get_models:
            mock_get_models.return_value = []

            response = client.get("/ai/models", headers=auth_headers)
            assert response.status_code == 200
            data = response.json()

            # Should still return successfully (with mock models if nothing else)
            assert len(data["models"]) > 0
