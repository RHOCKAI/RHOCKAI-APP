"""
Test fixtures — shared across all backend test modules.

Uses an in-memory SQLite database so no real PostgreSQL instance is needed.
"""

import os

os.environ.setdefault("ENVIRONMENT", "test")
os.environ["DATABASE_URL"] = "sqlite:///:memory:"

import pytest
from fastapi.testclient import TestClient

from app.main import app
from app.core.database import Base, SessionLocal, get_db
from app.core.security import create_access_token, get_password_hash
from app.models.user import User, FitnessLevel

# ---------------------------------------------------------------------------
# In-memory SQLite test database
# ---------------------------------------------------------------------------

TEST_DB_ENGINE = SessionLocal.kw["bind"]


@pytest.fixture(scope="function")
def db():
    """Create a fresh DB for each test, then tear it down."""
    Base.metadata.create_all(bind=TEST_DB_ENGINE)
    session = SessionLocal()
    try:
        yield session
    finally:
        session.close()
        Base.metadata.drop_all(bind=TEST_DB_ENGINE)


@pytest.fixture(scope="function")
def client(db):
    """TestClient with the DB dependency overridden to the test DB."""
    def override_get_db():
        try:
            yield db
        finally:
            pass

    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as c:
        yield c
    app.dependency_overrides.clear()


# ---------------------------------------------------------------------------
# Helper fixtures
# ---------------------------------------------------------------------------

@pytest.fixture(scope="function")
def test_user(db):
    """Create and persist a test user, returning the ORM object."""
    user = User(
        email="testuser@example.com",
        hashed_password=get_password_hash("TestPass1234"),
        full_name="Test User",
        fitness_level=FitnessLevel.beginner,
        is_active=True,
        is_verified=True,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


@pytest.fixture(scope="function")
def auth_headers(test_user):
    """Return Authorization headers with a valid JWT for test_user."""
    token = create_access_token(data={"sub": test_user.email})
    return {"Authorization": f"Bearer {token}"}
