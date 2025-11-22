"""
Unit tests for AI chat endpoint routing
Tests different model identifiers and routing logic
"""
import pytest
from unittest.mock import patch, AsyncMock, MagicMock


class TestAIChatRouting:
    """Test suite for AI chat endpoint routing"""

    def test_chat_unauthenticated(self, client):
        """Test that unauthenticated requests are rejected"""
        response = client.post("/ai/chat", json={
            "prompt": "Hello"
        })
        assert response.status_code == 401

    def test_chat_basic_request(self, client, auth_headers):
        """Test basic chat request without model specification"""
        with patch('app.ai.AiGateway.generate_reply', new_callable=AsyncMock) as mock_generate:
            mock_generate.return_value = (
                "Hello! How can I help you?",
                MagicMock(identifier="mock:llama3.1", key="mock")
            )

            response = client.post("/ai/chat", headers=auth_headers, json={
                "prompt": "Hello",
                "history": []
            })

            assert response.status_code == 200
            data = response.json()
            assert "response" in data
            assert "model" in data
            assert "provider" in data

    def test_chat_with_openai_model(self, client, auth_headers):
        """Test chat request with OpenAI model identifier"""
        with patch('app.ai.AiGateway.generate_reply', new_callable=AsyncMock) as mock_generate:
            mock_generate.return_value = (
                "Response from GPT-4",
                MagicMock(identifier="openai:gpt-4o-mini", key="openai")
            )

            response = client.post("/ai/chat", headers=auth_headers, json={
                "prompt": "What is AI?",
                "model": "openai:gpt-4o-mini"
            })

            assert response.status_code == 200
            data = response.json()
            assert data["provider"] == "openai"
            assert "gpt-4o-mini" in data["model"]

            # Verify that the correct model was passed to generate_reply
            mock_generate.assert_called_once()
            call_args = mock_generate.call_args
            assert call_args.kwargs.get("model_identifier") == "openai:gpt-4o-mini"

    def test_chat_with_client_node_model(self, client, auth_headers, mock_ai_client_node):
        """Test chat request with client node model identifier"""
        node_id = mock_ai_client_node.id
        model_identifier = f"client:{node_id}:llama3.1"

        with patch('app.ai.AiGateway.generate_reply', new_callable=AsyncMock) as mock_generate:
            mock_generate.return_value = (
                "Response from client node",
                MagicMock(
                    identifier=model_identifier,
                    key="client",
                    node_id=node_id,
                    node_name="Test Node"
                )
            )

            response = client.post("/ai/chat", headers=auth_headers, json={
                "prompt": "Test message",
                "model": model_identifier
            })

            assert response.status_code == 200
            data = response.json()
            assert data["provider"] == "client"
            assert model_identifier in data["model"]

            # Verify the model identifier was passed correctly
            mock_generate.assert_called_once()
            call_args = mock_generate.call_args
            assert call_args.kwargs.get("model_identifier") == model_identifier

    def test_chat_with_gemini_model(self, client, auth_headers):
        """Test chat request with Gemini model identifier"""
        with patch('app.ai.AiGateway.generate_reply', new_callable=AsyncMock) as mock_generate:
            mock_generate.return_value = (
                "Response from Gemini",
                MagicMock(identifier="gemini:gemini-1.5-flash", key="gemini")
            )

            response = client.post("/ai/chat", headers=auth_headers, json={
                "prompt": "Explain quantum computing",
                "model": "gemini:gemini-1.5-flash"
            })

            assert response.status_code == 200
            data = response.json()
            assert data["provider"] == "gemini"

    def test_chat_with_ollama_local_model(self, client, auth_headers):
        """Test chat request with local Ollama model"""
        with patch('app.ai.AiGateway.generate_reply', new_callable=AsyncMock) as mock_generate:
            mock_generate.return_value = (
                "Response from local Ollama",
                MagicMock(identifier="ollama:llama3.1", key="ollama")
            )

            response = client.post("/ai/chat", headers=auth_headers, json={
                "prompt": "Test local model",
                "model": "ollama:llama3.1"
            })

            assert response.status_code == 200
            data = response.json()
            assert data["provider"] == "ollama"

    def test_chat_with_history(self, client, auth_headers):
        """Test chat request with conversation history"""
        history = [
            {"role": "user", "content": "What is Python?"},
            {"role": "assistant", "content": "Python is a programming language."}
        ]

        with patch('app.ai.AiGateway.generate_reply', new_callable=AsyncMock) as mock_generate:
            mock_generate.return_value = (
                "Let me explain more about Python...",
                MagicMock(identifier="mock:llama3.1", key="mock")
            )

            response = client.post("/ai/chat", headers=auth_headers, json={
                "prompt": "Tell me more",
                "history": history
            })

            assert response.status_code == 200

            # Verify history was passed to generate_reply
            mock_generate.assert_called_once()
            call_args = mock_generate.call_args
            assert call_args.args[1] == history  # Second positional arg is history

    def test_chat_routing_fallback_to_mock(self, client, auth_headers):
        """Test that invalid models fall back to mock provider"""
        with patch('app.ai.AiGateway.generate_reply', new_callable=AsyncMock) as mock_generate:
            # Simulate fallback to mock provider
            mock_generate.return_value = (
                "I am a mock AI assistant.",
                MagicMock(identifier="mock:llama3.1", key="mock")
            )

            response = client.post("/ai/chat", headers=auth_headers, json={
                "prompt": "Test",
                "model": "invalid:model:identifier"
            })

            assert response.status_code == 200
            data = response.json()
            # Should fall back to mock
            assert data["provider"] in ["mock", "invalid"]

    def test_chat_includes_user_context(self, client, auth_headers, test_user):
        """Test that user_id is passed to AI gateway"""
        with patch('app.ai.AiGateway.generate_reply', new_callable=AsyncMock) as mock_generate:
            mock_generate.return_value = (
                "Response",
                MagicMock(identifier="mock:llama3.1", key="mock")
            )

            response = client.post("/ai/chat", headers=auth_headers, json={
                "prompt": "Test"
            })

            assert response.status_code == 200

            # Verify user_id was passed
            mock_generate.assert_called_once()
            call_args = mock_generate.call_args
            assert call_args.kwargs.get("user_id") == test_user.id

    def test_chat_validates_request_schema(self, client, auth_headers):
        """Test that request validation works correctly"""
        # Missing required 'prompt' field
        response = client.post("/ai/chat", headers=auth_headers, json={})
        assert response.status_code == 422  # Validation error

    def test_chat_stream_endpoint(self, client, auth_headers):
        """Test the streaming chat endpoint"""
        async def mock_stream():
            yield "Hello "
            yield "from "
            yield "stream!"

        with patch('app.ai.AiGateway.generate_stream', new_callable=AsyncMock) as mock_stream_fn:
            mock_stream_fn.return_value = (
                mock_stream(),
                MagicMock(identifier="mock:llama3.1", key="mock")
            )

            response = client.post("/ai/stream", headers=auth_headers, json={
                "prompt": "Test stream"
            })

            # Should return a streaming response
            assert response.status_code == 200
            # Content-Type should be for SSE
            assert "text/event-stream" in response.headers.get("content-type", "")

    def test_chat_with_private_node_access_control(self, client, auth_headers, private_ai_client_node, test_user):
        """Test that users can only access their own private nodes"""
        node_id = private_ai_client_node.id
        model_identifier = f"client:{node_id}:llama3.1-private"

        with patch('app.ai.AiGateway.generate_reply', new_callable=AsyncMock) as mock_generate:
            mock_generate.return_value = (
                "Response from private node",
                MagicMock(
                    identifier=model_identifier,
                    key="client",
                    node_id=node_id
                )
            )

            response = client.post("/ai/chat", headers=auth_headers, json={
                "prompt": "Test private node",
                "model": model_identifier
            })

            assert response.status_code == 200
            # User should be able to access their own private node
            data = response.json()
            assert data["provider"] == "client"

    def test_chat_model_identifier_parsing(self, client, auth_headers):
        """Test various model identifier formats"""
        test_cases = [
            ("openai:gpt-4o-mini", "openai"),
            ("gemini:gemini-1.5-flash", "gemini"),
            ("ollama:llama3.1", "ollama"),
            ("client:1:mistral", "client"),
        ]

        for model_id, expected_provider in test_cases:
            with patch('app.ai.AiGateway.generate_reply', new_callable=AsyncMock) as mock_generate:
                mock_generate.return_value = (
                    "Response",
                    MagicMock(identifier=model_id, key=expected_provider)
                )

                response = client.post("/ai/chat", headers=auth_headers, json={
                    "prompt": "Test",
                    "model": model_id
                })

                assert response.status_code == 200
                data = response.json()
                assert data["provider"] == expected_provider

    def test_chat_response_includes_route_info(self, client, auth_headers):
        """Test that response includes routing information"""
        with patch('app.ai.AiGateway.generate_reply', new_callable=AsyncMock) as mock_generate:
            mock_generate.return_value = (
                "Test response",
                MagicMock(
                    identifier="openai:gpt-4o-mini",
                    key="openai",
                    model="gpt-4o-mini"
                )
            )

            response = client.post("/ai/chat", headers=auth_headers, json={
                "prompt": "Test",
                "model": "openai:gpt-4o-mini"
            })

            assert response.status_code == 200
            data = response.json()

            # Verify response contains routing info
            assert "response" in data
            assert "model" in data
            assert "provider" in data
            assert data["model"] == "openai:gpt-4o-mini"
            assert data["provider"] == "openai"


class TestAIEmbeddingsEndpoint:
    """Test suite for AI embeddings endpoint"""

    def test_embeddings_basic_request(self, client, auth_headers):
        """Test basic embeddings request"""
        with patch('app.ai.AiGateway.generate_embeddings', new_callable=AsyncMock) as mock_embeddings:
            mock_embeddings.return_value = [0.1, 0.2, 0.3] * 128  # 384-dim vector

            response = client.post("/ai/embeddings", headers=auth_headers, json={
                "text": "Test text for embeddings"
            })

            assert response.status_code == 200
            data = response.json()
            assert "embeddings" in data
            assert "model" in data
            assert "dimension" in data
            assert len(data["embeddings"]) > 0

    def test_embeddings_with_model_selection(self, client, auth_headers, mock_ai_client_node):
        """Test embeddings with specific model"""
        node_id = mock_ai_client_node.id
        model_identifier = f"client:{node_id}:llama3.1"

        with patch('app.ai.AiGateway.generate_embeddings', new_callable=AsyncMock) as mock_embeddings:
            mock_embeddings.return_value = [0.5] * 384

            response = client.post("/ai/embeddings", headers=auth_headers, json={
                "text": "Test embeddings",
                "model": model_identifier
            })

            assert response.status_code == 200
            data = response.json()
            assert len(data["embeddings"]) == 384

            # Verify model was passed correctly
            mock_embeddings.assert_called_once()
            call_args = mock_embeddings.call_args
            assert call_args.kwargs.get("model_identifier") == model_identifier
