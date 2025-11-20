"""
Pytest configuration and shared fixtures for testing
"""
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.database import Base, get_db
from app.models import User, AIClientNode
from app import crud, schemas, auth
from main import app


# Use in-memory SQLite database for testing
SQLALCHEMY_DATABASE_URL = "sqlite:///:memory:"

engine = create_engine(
    SQLALCHEMY_DATABASE_URL,
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


@pytest.fixture(scope="function")
def db_session():
    """Create a fresh database for each test"""
    Base.metadata.create_all(bind=engine)
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()
        Base.metadata.drop_all(bind=engine)


@pytest.fixture(scope="function")
def client(db_session):
    """Create a test client with the test database"""
    def override_get_db():
        try:
            yield db_session
        finally:
            pass

    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as test_client:
        yield test_client
    app.dependency_overrides.clear()


@pytest.fixture
def test_user(db_session):
    """Create a test user"""
    user_data = schemas.UserCreate(
        username="testuser",
        email="test@example.com",
        password="testpassword",
        full_name="Test User"
    )
    user = crud.create_user(db=db_session, user=user_data)
    return user


@pytest.fixture
def admin_user(db_session):
    """Create an admin user"""
    user_data = schemas.UserCreate(
        username="admin",
        email="admin@example.com",
        password="adminpassword",
        full_name="Admin User",
        is_admin=True
    )
    user = crud.create_user(db=db_session, user=user_data)
    return user


@pytest.fixture
def auth_headers(test_user):
    """Generate authentication headers for test user"""
    from datetime import timedelta
    access_token = auth.create_access_token(
        data={"sub": test_user.username},
        expires_delta=timedelta(minutes=30)
    )
    return {"Authorization": f"Bearer {access_token}"}


@pytest.fixture
def admin_auth_headers(admin_user):
    """Generate authentication headers for admin user"""
    from datetime import timedelta
    access_token = auth.create_access_token(
        data={"sub": admin_user.username},
        expires_delta=timedelta(minutes=30)
    )
    return {"Authorization": f"Bearer {access_token}"}


@pytest.fixture
def mock_ai_client_node(db_session, test_user):
    """Create a mock AI client node for testing"""
    node = AIClientNode(
        name="Test Node",
        node_type="ollama",
        hostname="localhost",
        port=11434,
        is_public=True,
        is_active=True,
        owner_id=test_user.id,
        status="online",
        capabilities={
            "models": ["llama3.1", "mistral"],
            "model_count": 2,
            "last_response_time_ms": 100
        }
    )
    db_session.add(node)
    db_session.commit()
    db_session.refresh(node)
    return node


@pytest.fixture
def private_ai_client_node(db_session, test_user):
    """Create a private AI client node for testing"""
    node = AIClientNode(
        name="Private Node",
        node_type="ollama",
        hostname="192.168.1.100",
        port=11434,
        is_public=False,
        is_active=True,
        owner_id=test_user.id,
        status="online",
        capabilities={
            "models": ["llama3.1-private"],
            "model_count": 1,
            "last_response_time_ms": 150
        }
    )
    db_session.add(node)
    db_session.commit()
    db_session.refresh(node)
    return node
