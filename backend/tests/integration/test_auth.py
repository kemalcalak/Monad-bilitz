"""
Integration tests for Authentication
"""

import pytest
from httpx import AsyncClient

from app.models.user import User


@pytest.mark.asyncio
async def test_register_user(client: AsyncClient, db_session):
    """Test user registration"""
    response = await client.post(
        "/api/v1/auth/register",
        json={
            "username": "test_auth_user",
            "email": "auth@example.com",
            "password": "strongpassword123",
            "wallet_address": "0x1234567890123456789012345678901234567890"
        }
    )
    
    assert response.status_code == 201
    data = response.json()
    assert data["username"] == "test_auth_user"
    assert "id" in data


@pytest.mark.asyncio
async def test_login_user(client: AsyncClient):
    """Test user login"""
    # Register first
    await client.post(
        "/api/v1/auth/register",
        json={
            "username": "login_user",
            "email": "login@example.com",
            "password": "password123"
        }
    )
    
    # Login
    response = await client.post(
        "/api/v1/auth/login",
        data={
            "username": "login_user",
            "password": "password123"
        }
    )
    
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert data["token_type"] == "bearer"


@pytest.mark.asyncio
async def test_duplicate_user(client: AsyncClient):
    """Test duplicate registration"""
    user_data = {
        "username": "dup_user",
        "email": "dup@example.com",
        "password": "password123"
    }
    
    # First registration
    await client.post("/api/v1/auth/register", json=user_data)
    
    # Second registration
    response = await client.post("/api/v1/auth/register", json=user_data)
    
    assert response.status_code == 400
