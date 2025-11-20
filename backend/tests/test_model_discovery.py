"""
Tests for AI Model Discovery Endpoints
Tests the /admin/ai/models/* endpoints and model metadata enrichment
"""
import pytest
from unittest.mock import AsyncMock, patch, MagicMock
from fastapi.testclient import TestClient


# Mock model responses
MOCK_OPENAI_MODELS = {
    "data": [
        {
            "id": "gpt-4o-mini",
            "object": "model",
            "created": 1234567890,
            "owned_by": "openai"
        },
        {
            "id": "gpt-3.5-turbo",
            "object": "model",
            "created": 1234567890,
            "owned_by": "openai"
        },
        {
            "id": "gpt-4o",
            "object": "model",
            "created": 1234567890,
            "owned_by": "openai"
        }
    ]
}

MOCK_GEMINI_MODELS = {
    "models": [
        {
            "name": "models/gemini-1.5-flash",
            "displayName": "Gemini 1.5 Flash",
            "description": "Fast and versatile performance across a variety of tasks",
            "supportedGenerationMethods": ["generateContent", "streamGenerateContent"]
        },
        {
            "name": "models/gemini-1.5-pro",
            "displayName": "Gemini 1.5 Pro",
            "description": "Most capable Gemini model, best for complex reasoning",
            "supportedGenerationMethods": ["generateContent", "streamGenerateContent"]
        },
        {
            "name": "models/gemini-embedding-001",
            "displayName": "Gemini Embedding",
            "description": "Embedding model",
            "supportedGenerationMethods": ["embedContent"]
        }
    ]
}


@pytest.mark.asyncio
async def test_openai_models_admin_endpoint_success(client: TestClient, admin_user_token: str, db_session):
    """Test successful OpenAI model fetching for admin"""
    # Mock the provider credentials
    with patch('app.crud.get_provider_secret') as mock_secret:
        mock_secret.return_value = {
            "api_key": "sk-test-key-123",
            "model": "gpt-4o-mini"
        }

        # Mock the httpx client response
        with patch('httpx.AsyncClient') as mock_client:
            mock_response = AsyncMock()
            mock_response.json.return_value = MOCK_OPENAI_MODELS
            mock_response.raise_for_status = MagicMock()

            mock_client_instance = AsyncMock()
            mock_client_instance.__aenter__.return_value.get.return_value = mock_response
            mock_client.return_value = mock_client_instance

            response = client.get(
                "/admin/ai/models/openai",
                headers={"Authorization": f"Bearer {admin_user_token}"}
            )

            assert response.status_code == 200
            data = response.json()

            assert data["provider"] == "openai"
            assert data["credentials_configured"] is True
            assert data["total_count"] == 3
            assert len(data["models"]) == 3

            # Check first model has enriched metadata
            gpt4o_mini = next(m for m in data["models"] if m["id"] == "gpt-4o-mini")
            assert gpt4o_mini["name"] == "gpt-4o-mini"
            assert gpt4o_mini["description"] == "Affordable and intelligent small model for fast, lightweight tasks"
            assert gpt4o_mini["context_window"] == 128000
            assert gpt4o_mini["max_output_tokens"] == 16384
            assert gpt4o_mini["input_cost_per_1m"] == 0.15
            assert gpt4o_mini["output_cost_per_1m"] == 0.60
            assert gpt4o_mini["supports_vision"] is True
            assert gpt4o_mini["supports_function_calling"] is True


@pytest.mark.asyncio
async def test_openai_models_no_credentials(client: TestClient, admin_user_token: str, db_session):
    """Test OpenAI endpoint when no API key is configured"""
    with patch('app.crud.get_provider_secret') as mock_secret:
        mock_secret.return_value = None

        response = client.get(
            "/admin/ai/models/openai",
            headers={"Authorization": f"Bearer {admin_user_token}"}
        )

        assert response.status_code == 200
        data = response.json()

        assert data["provider"] == "openai"
        assert data["credentials_configured"] is False
        assert data["total_count"] == 0
        assert len(data["models"]) == 0
        assert "not configured" in data["error"].lower()


@pytest.mark.asyncio
async def test_gemini_models_admin_endpoint_success(client: TestClient, admin_user_token: str, db_session):
    """Test successful Gemini model fetching for admin"""
    with patch('app.crud.get_provider_secret') as mock_secret:
        mock_secret.return_value = {
            "api_key": "gemini-test-key-123",
            "model": "gemini-1.5-flash"
        }

        with patch('httpx.AsyncClient') as mock_client:
            mock_response = AsyncMock()
            mock_response.json.return_value = MOCK_GEMINI_MODELS
            mock_response.raise_for_status = MagicMock()

            mock_client_instance = AsyncMock()
            mock_client_instance.__aenter__.return_value.get.return_value = mock_response
            mock_client.return_value = mock_client_instance

            response = client.get(
                "/admin/ai/models/gemini",
                headers={"Authorization": f"Bearer {admin_user_token}"}
            )

            assert response.status_code == 200
            data = response.json()

            assert data["provider"] == "gemini"
            assert data["credentials_configured"] is True
            # Should only include models with generateContent support (2 out of 3)
            assert data["total_count"] == 2
            assert len(data["models"]) == 2

            # Check flash model metadata
            flash = next(m for m in data["models"] if "flash" in m["id"])
            assert flash["description"] == "Fast and versatile performance across a variety of tasks"
            assert flash["context_window"] == 1000000
            assert flash["max_output_tokens"] == 8192
            assert flash["input_cost_per_1m"] == 0.075
            assert flash["output_cost_per_1m"] == 0.30
            assert flash["supports_vision"] is True
            assert flash["supports_function_calling"] is True


@pytest.mark.asyncio
async def test_models_endpoint_includes_enriched_metadata(client: TestClient, user_token: str, db_session):
    """Test that the regular /ai/models endpoint includes enriched metadata"""
    with patch('app.crud.get_provider_secret') as mock_secret:
        # Mock both OpenAI and Gemini credentials
        def get_secret(db, provider):
            if provider == "openai":
                return {"api_key": "sk-test", "model": "gpt-4o-mini"}
            elif provider == "gemini":
                return {"api_key": "gem-test", "model": "gemini-1.5-flash"}
            return None

        mock_secret.side_effect = get_secret

        with patch('httpx.AsyncClient') as mock_client:
            # Mock responses for both providers
            mock_openai_response = AsyncMock()
            mock_openai_response.json.return_value = MOCK_OPENAI_MODELS
            mock_openai_response.raise_for_status = MagicMock()

            mock_gemini_response = AsyncMock()
            mock_gemini_response.json.return_value = MOCK_GEMINI_MODELS
            mock_gemini_response.raise_for_status = MagicMock()

            # Setup mock client to return different responses based on URL
            async def mock_get(url, **kwargs):
                if "openai" in url:
                    return mock_openai_response
                elif "generativelanguage" in url:
                    return mock_gemini_response
                return AsyncMock()

            mock_client_instance = AsyncMock()
            mock_client_instance.get = mock_get
            mock_client.return_value.__aenter__.return_value = mock_client_instance

            response = client.get(
                "/ai/models",
                headers={"Authorization": f"Bearer {user_token}"}
            )

            assert response.status_code == 200
            data = response.json()

            assert "models" in data
            models = data["models"]

            # Should have both OpenAI and Gemini models
            openai_models = [m for m in models if m["provider"] == "openai"]
            gemini_models = [m for m in models if m["provider"] == "gemini"]

            assert len(openai_models) > 0
            assert len(gemini_models) > 0

            # Verify enrichment
            for model in openai_models:
                assert "description" in model
                assert "context_window" in model
                assert "input_cost_per_1m" in model
                assert "output_cost_per_1m" in model

            for model in gemini_models:
                assert "description" in model
                assert "context_window" in model
                assert "supports_vision" in model


def test_openai_models_requires_admin(client: TestClient, user_token: str):
    """Test that regular users cannot access admin model endpoints"""
    response = client.get(
        "/admin/ai/models/openai",
        headers={"Authorization": f"Bearer {user_token}"}
    )

    assert response.status_code == 403  # Forbidden


def test_gemini_models_requires_admin(client: TestClient, user_token: str):
    """Test that regular users cannot access admin model endpoints"""
    response = client.get(
        "/admin/ai/models/gemini",
        headers={"Authorization": f"Bearer {user_token}"}
    )

    assert response.status_code == 403  # Forbidden


def test_model_metadata_helpers():
    """Test model metadata helper functions"""
    from app.model_metadata import (
        get_openai_context_window,
        get_gemini_context_window,
        get_openai_input_cost,
        get_gemini_input_cost,
        openai_supports_vision,
        gemini_supports_vision,
        get_model_tier,
        get_recommended_test_models,
        get_recommended_production_models
    )

    # Test OpenAI metadata
    assert get_openai_context_window("gpt-4o") == 128000
    assert get_openai_context_window("gpt-3.5-turbo") == 16385
    assert get_openai_input_cost("gpt-4o-mini") == 0.15
    assert openai_supports_vision("gpt-4o") is True
    assert openai_supports_vision("gpt-3.5-turbo") is False

    # Test Gemini metadata
    assert get_gemini_context_window("gemini-1.5-pro") == 2000000
    assert get_gemini_context_window("gemini-1.5-flash") == 1000000
    assert get_gemini_input_cost("gemini-1.5-flash") == 0.075
    assert get_gemini_input_cost("gemini-2.0-flash-exp") == 0.0  # Free during preview
    assert gemini_supports_vision("gemini-1.5-pro") is True

    # Test tier categorization
    assert get_model_tier("gpt-3.5-turbo") == "lightweight"
    assert get_model_tier("gemini-1.5-flash") == "lightweight"
    assert get_model_tier("gpt-4o-mini") == "standard"
    assert get_model_tier("gpt-4o") == "premium"

    # Test recommendations
    test_models = get_recommended_test_models()
    assert test_models["openai"] == "gpt-3.5-turbo"
    assert test_models["gemini"] == "gemini-1.5-flash"

    prod_models = get_recommended_production_models()
    assert prod_models["openai"] == "gpt-4o-mini"
    assert prod_models["gemini"] == "gemini-1.5-pro"


@pytest.mark.asyncio
async def test_invalid_api_key_error_handling(client: TestClient, admin_user_token: str, db_session):
    """Test proper error handling when API key is invalid"""
    with patch('app.crud.get_provider_secret') as mock_secret:
        mock_secret.return_value = {
            "api_key": "invalid-key",
            "model": "gpt-4o-mini"
        }

        with patch('httpx.AsyncClient') as mock_client:
            # Mock 401 Unauthorized response
            mock_response = AsyncMock()
            mock_response.raise_for_status.side_effect = Exception("Incorrect API key provided")

            mock_client_instance = AsyncMock()
            mock_client_instance.__aenter__.return_value.get.return_value = mock_response
            mock_client.return_value = mock_client_instance

            response = client.get(
                "/admin/ai/models/openai",
                headers={"Authorization": f"Bearer {admin_user_token}"}
            )

            assert response.status_code == 200  # Still returns 200
            data = response.json()

            assert data["credentials_configured"] is True
            assert data["total_count"] == 0
            assert "error" in data
            assert "Incorrect API key" in data["error"]


def test_model_enrichment():
    """Test that model enrichment adds all required fields"""
    from app.model_metadata import enrich_openai_model, enrich_gemini_model

    # Test OpenAI enrichment
    openai_model = {
        "id": "gpt-4o-mini",
        "name": "gpt-4o-mini",
        "provider": "openai"
    }
    enriched = enrich_openai_model("gpt-4o-mini", openai_model)

    assert enriched["description"] is not None
    assert enriched["context_window"] == 128000
    assert enriched["max_output_tokens"] == 16384
    assert enriched["input_cost_per_1m"] == 0.15
    assert enriched["output_cost_per_1m"] == 0.60
    assert enriched["supports_vision"] is True
    assert enriched["supports_function_calling"] is True

    # Test Gemini enrichment
    gemini_model = {
        "id": "gemini-1.5-flash",
        "name": "gemini-1.5-flash",
        "provider": "gemini",
        "description": "Fast model"
    }
    enriched = enrich_gemini_model("gemini-1.5-flash", gemini_model)

    assert enriched["description"] == "Fast model"  # Keeps existing description
    assert enriched["context_window"] == 1000000
    assert enriched["max_output_tokens"] == 8192
    assert enriched["input_cost_per_1m"] == 0.075
    assert enriched["output_cost_per_1m"] == 0.30
    assert enriched["supports_vision"] is True
    assert enriched["supports_function_calling"] is True
