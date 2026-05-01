"""
Authentication endpoint tests.
Uses conftest.py fixtures for an isolated in-memory DB.
"""

import pytest


class TestRegisterUser:
    def test_register_new_user(self, client):
        response = client.post("/api/v1/auth/register", json={
            "email": "newuser@example.com",
            "password": "SecurePass1234",
            "full_name": "New User",
        })
        # Register returns 200 with UserResponse
        assert response.status_code == 200
        data = response.json()
        assert data["email"] == "newuser@example.com"
        assert "id" in data
        assert "hashed_password" not in data  # password must never be returned

    def test_register_duplicate_email_returns_400(self, client):
        payload = {
            "email": "duplicate@example.com",
            "password": "SecurePass1234",
            "full_name": "First User",
        }
        client.post("/api/v1/auth/register", json=payload)
        # Second registration with the same email
        response = client.post("/api/v1/auth/register", json=payload)
        assert response.status_code == 400
        assert "already registered" in response.json()["detail"].lower()

    def test_register_invalid_email_returns_422(self, client):
        response = client.post("/api/v1/auth/register", json={
            "email": "not-an-email",
            "password": "SecurePass1234",
        })
        assert response.status_code == 422


class TestLogin:
    def test_login_valid_credentials(self, client, test_user):
        response = client.post("/api/v1/auth/login", json={
            "email": test_user.email,
            "password": "TestPass1234",
        })
        assert response.status_code == 200
        data = response.json()
        assert "access_token" in data
        assert data["token_type"] == "bearer"

    def test_login_wrong_password_returns_401(self, client, test_user):
        response = client.post("/api/v1/auth/login", json={
            "email": test_user.email,
            "password": "WrongPassword!",
        })
        assert response.status_code == 401

    def test_login_unknown_email_returns_401(self, client):
        response = client.post("/api/v1/auth/login", json={
            "email": "nobody@example.com",
            "password": "SomePass1234",
        })
        assert response.status_code == 401


class TestGetCurrentUser:
    def test_me_returns_authenticated_user(self, client, test_user, auth_headers):
        response = client.get("/api/v1/auth/me", headers=auth_headers)
        assert response.status_code == 200
        data = response.json()
        assert data["email"] == test_user.email
        assert data["id"] == test_user.id

    def test_me_without_token_returns_401(self, client):
        response = client.get("/api/v1/auth/me")
        assert response.status_code == 401

    def test_me_with_invalid_token_returns_401(self, client):
        response = client.get(
            "/api/v1/auth/me",
            headers={"Authorization": "Bearer totally.invalid.token"},
        )
        assert response.status_code == 401