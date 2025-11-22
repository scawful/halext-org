# Testing Guide for Halext Backend

This document provides comprehensive information about testing the Halext backend, particularly the AI routing implementation.

## Table of Contents
1. [Setup](#setup)
2. [Running Tests](#running-tests)
3. [Test Structure](#test-structure)
4. [Test Coverage](#test-coverage)
5. [Writing New Tests](#writing-new-tests)
6. [CI/CD Integration](#cicd-integration)
7. [Troubleshooting](#troubleshooting)

## Setup

### Installing Test Dependencies

```bash
# Install pytest and testing utilities
pip install pytest pytest-asyncio pytest-cov httpx

# Or update requirements.txt and install
pip install -r requirements.txt
```

### Test Database

Tests use an in-memory SQLite database that is created and destroyed for each test function. This ensures test isolation and prevents test data from persisting.

## Running Tests

### Run All Tests

```bash
# From backend directory
pytest

# With verbose output
pytest -v

# With coverage report
pytest --cov=app --cov-report=html
```

### Run Specific Test Files

```bash
# Run only AI models endpoint tests
pytest tests/test_ai_models_endpoint.py

# Run only chat routing tests
pytest tests/test_ai_chat_routing.py

# Run only integration tests
pytest tests/test_ai_routing_integration.py

# Run only regression tests
pytest tests/test_ai_regression.py
```

### Run Specific Test Classes or Methods

```bash
# Run a specific test class
pytest tests/test_ai_models_endpoint.py::TestAIModelsEndpoint

# Run a specific test method
pytest tests/test_ai_models_endpoint.py::TestAIModelsEndpoint::test_list_models_basic

# Run tests matching a pattern
pytest -k "test_chat"
```

### Run Tests by Marker

```bash
# Run only unit tests
pytest -m unit

# Run only integration tests
pytest -m integration

# Run only regression tests
pytest -m regression

# Exclude slow tests
pytest -m "not slow"
```

## Test Structure

### Test Organization

```
backend/
├── tests/
│   ├── __init__.py
│   ├── conftest.py                      # Shared fixtures
│   ├── test_ai_models_endpoint.py       # Unit tests for /ai/models
│   ├── test_ai_chat_routing.py          # Unit tests for chat routing
│   ├── test_ai_routing_integration.py   # Integration tests
│   └── test_ai_regression.py            # Regression tests
├── pytest.ini                           # Pytest configuration
└── README_TESTING.md                    # This file
```

### Test Categories

1. **Unit Tests** (`test_ai_models_endpoint.py`, `test_ai_chat_routing.py`)
   - Test individual endpoints and functions
   - Use mocks to isolate components
   - Fast execution
   - High coverage of edge cases

2. **Integration Tests** (`test_ai_routing_integration.py`)
   - Test multiple components working together
   - End-to-end workflows
   - Test data flow between layers
   - Verify component interactions

3. **Regression Tests** (`test_ai_regression.py`)
   - Ensure backward compatibility
   - Test edge cases and error handling
   - Verify fallback behavior
   - Test with no providers configured

### Fixtures (conftest.py)

Common fixtures available in all tests:

- `db_session`: Fresh test database session
- `client`: FastAPI test client
- `test_user`: Regular test user
- `admin_user`: Admin test user
- `auth_headers`: Authentication headers for test user
- `admin_auth_headers`: Authentication headers for admin user
- `mock_ai_client_node`: Public AI client node
- `private_ai_client_node`: Private AI client node

## Test Coverage

### Current Coverage

The test suite covers the following areas:

#### `/ai/models` Endpoint
- ✅ Authentication requirements
- ✅ Basic model listing
- ✅ Public node visibility
- ✅ Private node access control (own nodes only)
- ✅ Filtering inactive nodes
- ✅ Provider model inclusion
- ✅ Response schema validation
- ✅ Node metadata inclusion
- ✅ Default model ID

#### `/ai/chat` Endpoint
- ✅ Authentication requirements
- ✅ Basic chat requests
- ✅ OpenAI model routing
- ✅ Client node model routing
- ✅ Gemini model routing
- ✅ Local Ollama routing
- ✅ Conversation history handling
- ✅ Model identifier parsing
- ✅ Fallback to mock provider
- ✅ User context passing
- ✅ Request validation
- ✅ Streaming responses
- ✅ Access control for private nodes

#### Integration Scenarios
- ✅ Full workflow (list → select → chat)
- ✅ Model selection persistence
- ✅ Switching between providers
- ✅ Node health affecting availability
- ✅ Concurrent model access
- ✅ Default model routing
- ✅ Metadata consistency

#### Regression & Edge Cases
- ✅ Backward compatibility (no model param)
- ✅ No providers configured (mock fallback)
- ✅ Invalid model identifiers
- ✅ Empty/malformed prompts
- ✅ Special characters in prompts
- ✅ Non-existent node IDs
- ✅ Invalid history format
- ✅ Concurrent requests
- ✅ Nodes with no models

### Coverage Gaps

The following areas may need additional testing:

- **AI Task/Event/Note Features**: Need tests for model parameter passthrough
- **Recipe AI Endpoints**: Integration with model selection
- **WebSocket/SSE**: Real-time streaming behavior
- **Performance**: Load testing with many concurrent requests
- **Database**: Complex queries and filtering
- **Caching**: Model list caching behavior

## Writing New Tests

### Basic Test Template

```python
import pytest
from unittest.mock import patch, AsyncMock

class TestNewFeature:
    """Test suite for new feature"""

    def test_basic_functionality(self, client, auth_headers):
        """Test basic functionality"""
        response = client.post("/api/endpoint", headers=auth_headers, json={
            "param": "value"
        })

        assert response.status_code == 200
        data = response.json()
        assert "expected_field" in data

    @pytest.mark.asyncio
    async def test_async_function(self, db_session):
        """Test async functionality"""
        with patch('module.async_function', new_callable=AsyncMock) as mock:
            mock.return_value = "result"

            result = await some_async_function()

            assert result == "result"
            mock.assert_called_once()
```

### Using Fixtures

```python
def test_with_fixtures(self, client, auth_headers, test_user, mock_ai_client_node):
    """Test using multiple fixtures"""
    # test_user and mock_ai_client_node are already created

    response = client.get("/ai/models", headers=auth_headers)
    # ...assertions
```

### Mocking External Services

```python
from unittest.mock import patch, AsyncMock

def test_with_mocked_service(self, client, auth_headers):
    """Test with mocked external service"""
    with patch('app.ai.AiGateway.generate_reply', new_callable=AsyncMock) as mock:
        mock.return_value = ("Response", MagicMock(identifier="test:model", key="test"))

        response = client.post("/ai/chat", headers=auth_headers, json={
            "prompt": "test"
        })

        assert response.status_code == 200
        mock.assert_called_once()
```

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Backend Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v2

    - name: Set up Python
      uses: actions/setup-python@v2
      with:
        python-version: '3.9'

    - name: Install dependencies
      run: |
        cd backend
        pip install -r requirements.txt
        pip install pytest pytest-asyncio pytest-cov

    - name: Run tests
      run: |
        cd backend
        pytest --cov=app --cov-report=xml

    - name: Upload coverage
      uses: codecov/codecov-action@v2
      with:
        file: ./backend/coverage.xml
```

### Pre-commit Hook

```bash
#!/bin/bash
# .git/hooks/pre-commit

cd backend
pytest
if [ $? -ne 0 ]; then
    echo "Tests failed. Commit aborted."
    exit 1
fi
```

## Troubleshooting

### Common Issues

#### Import Errors

**Problem:** `ModuleNotFoundError: No module named 'app'`

**Solution:**
```bash
# Ensure you're in the backend directory
cd backend

# Run pytest from backend directory
pytest

# Or set PYTHONPATH
export PYTHONPATH="${PYTHONPATH}:$(pwd)"
pytest
```

#### Database Errors

**Problem:** `OperationalError: database is locked`

**Solution:**
- Tests use in-memory SQLite, this shouldn't happen
- Ensure you're using the test fixtures correctly
- Check that `db_session` fixture is being used

#### Async Test Failures

**Problem:** `RuntimeWarning: coroutine was never awaited`

**Solution:**
- Mark async tests with `@pytest.mark.asyncio`
- Install `pytest-asyncio`: `pip install pytest-asyncio`
- Ensure async functions are properly awaited

#### Mock Not Working

**Problem:** Mocks not being called or returning unexpected values

**Solution:**
- Verify the import path in `patch()` is correct
- Use `new_callable=AsyncMock` for async functions
- Check that mock is set up before the code under test runs

### Debugging Tests

```bash
# Run with debugging output
pytest -vv --tb=long

# Stop on first failure
pytest -x

# Run with print statements visible
pytest -s

# Run specific test with debugging
pytest tests/test_file.py::test_name -vv -s
```

### Checking Coverage

```bash
# Generate HTML coverage report
pytest --cov=app --cov-report=html

# Open in browser
open htmlcov/index.html

# Check coverage for specific file
pytest --cov=app.ai --cov-report=term-missing
```

## Best Practices

1. **Test Isolation**: Each test should be independent and not rely on others
2. **Clear Names**: Test names should describe what they test
3. **Arrange-Act-Assert**: Structure tests in three clear phases
4. **Mock External Services**: Don't make real API calls in tests
5. **Test Edge Cases**: Include tests for error conditions and edge cases
6. **Keep Tests Fast**: Use mocks to avoid slow operations
7. **Meaningful Assertions**: Check specific values, not just "success"
8. **Document Complex Tests**: Add docstrings explaining what's being tested

## Additional Resources

- [pytest Documentation](https://docs.pytest.org/)
- [FastAPI Testing](https://fastapi.tiangolo.com/tutorial/testing/)
- [unittest.mock Documentation](https://docs.python.org/3/library/unittest.mock.html)
- [Manual QA Checklist](../docs/ai/AI_ROUTING_MANUAL_QA.md)

## Contact

For questions about testing:
- Check existing tests for examples
- Review this document
- Consult the AI Routing Implementation Plan
- Ask the development team

---

**Last Updated:** 2025-11-19
**Version:** 1.0
