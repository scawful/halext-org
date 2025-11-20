# AI Routing Test Suite

Quick reference for running AI routing tests.

## Quick Start

```bash
# Install dependencies (from backend directory)
pip install -r requirements.txt

# Run all tests
pytest

# Run specific test file
pytest tests/test_ai_models_endpoint.py
pytest tests/test_ai_chat_routing.py
pytest tests/test_ai_routing_integration.py
pytest tests/test_ai_regression.py

# Run with coverage
pytest --cov=app --cov-report=html
```

## Test Files

| File | Purpose | Test Count |
|------|---------|------------|
| `test_ai_models_endpoint.py` | `/ai/models` endpoint tests | 13 |
| `test_ai_chat_routing.py` | Chat routing tests | 20+ |
| `test_ai_routing_integration.py` | Integration tests | 15+ |
| `test_ai_regression.py` | Regression & edge cases | 20+ |
| `conftest.py` | Shared fixtures | - |

## Common Commands

```bash
# Run tests with verbose output
pytest -v

# Run specific test class
pytest tests/test_ai_models_endpoint.py::TestAIModelsEndpoint

# Run specific test method
pytest tests/test_ai_chat_routing.py::TestAIChatRouting::test_chat_with_openai_model

# Run tests matching pattern
pytest -k "test_chat"

# Stop on first failure
pytest -x

# Show print statements
pytest -s
```

## Documentation

- Full Testing Guide: `../README_TESTING.md`
- Manual QA Checklist: `../../docs/ai/AI_ROUTING_MANUAL_QA.md`
- Test Report: `../../docs/ai/AI_ROUTING_TEST_REPORT.md`

## Test Coverage

The test suite provides comprehensive coverage of:
- ✅ Model listing and filtering
- ✅ Model routing (OpenAI, Gemini, Client nodes, Ollama)
- ✅ Access control and permissions
- ✅ Streaming responses
- ✅ Error handling and fallbacks
- ✅ Backward compatibility

Total: 70+ test cases
