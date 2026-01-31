"""
Integration tests for Contracts
"""

import pytest
from httpx import AsyncClient


@pytest.fixture
async def auth_headers(client: AsyncClient):
    """Get auth headers for a test user"""
    # Register
    await client.post(
        "/api/v1/auth/register",
        json={
            "username": "contract_user",
            "email": "contract@example.com",
            "password": "password123"
        }
    )
    
    # Login
    response = await client.post(
        "/api/v1/auth/login",
        data={
            "username": "contract_user",
            "password": "password123"
        }
    )
    
    token = response.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}


@pytest.mark.asyncio
async def test_create_contract(client: AsyncClient, auth_headers):
    """Test contract creation"""
    contract_data = {
        "title": "Test Integration Contract",
        "content": "Content of the test contract",
        "contract_type": "general",
        "amount": 1000,
        "urgency": "normal"
    }
    
    response = await client.post(
        "/api/v1/contracts/",
        json=contract_data,
        headers=auth_headers
    )
    
    assert response.status_code == 201
    data = response.json()
    assert data["title"] == contract_data["title"]
    assert data["status"] == "pending"
    assert data["creator_username"] == "contract_user"


@pytest.mark.asyncio
async def test_list_contracts(client: AsyncClient, auth_headers):
    """Test listing contracts"""
    response = await client.get("/api/v1/contracts/", headers=auth_headers)
    
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    # user just created one in previous test if session persists, 
    # but fixtures strictly isolate or sharing session depends on conftest.
    # With our conftest, we drop_all between sessions/module (check scope).
    # Since we reused client/db per session in conftest fixtures scope="session" with setup_db,
    # tests share data.
    
    # Check if we find the one we likely created
    # Note: test order matters or we should create one here too
    
    # Let's create one just to be sure
    await client.post(
        "/api/v1/contracts/",
        json={
            "title": "Another Contract",
            "content": "Content",
            "contract_type": "general"
        },
        headers=auth_headers
    )
    
    response = await client.get("/api/v1/contracts/", headers=auth_headers)
    assert len(response.json()) >= 1
