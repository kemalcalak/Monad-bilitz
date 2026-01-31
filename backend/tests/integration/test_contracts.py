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
@pytest.mark.asyncio
async def test_sign_contract_flow(client: AsyncClient, db_session, seed_groups):
    """Test full signature flow with authority score accumulation"""
    
    # 1. Register two users in different groups
    # CEO User
    await client.post("/api/v1/auth/register", json={
        "username": "ceo_user", "email": "ceo@test.com", "password": "password123"
    })
    # Manually assign to CEO group (since auto-assignment might be complex in mock)
    # Get user and group from DB
    from app.models.user import User
    from app.models.hierarchy import Group
    import sqlalchemy as sa
    
    res = await db_session.execute(sa.select(User).where(User.username == "ceo_user"))
    ceo_user = res.scalar_one()
    res = await db_session.execute(sa.select(Group).where(Group.group_name == "CEO"))
    ceo_group = res.scalar_one()
    ceo_user.group_id = ceo_group.id
    await db_session.commit()

    # CFO User
    await client.post("/api/v1/auth/register", json={
        "username": "cfo_user", "email": "cfo@test.com", "password": "password123"
    })
    res = await db_session.execute(sa.select(User).where(User.username == "cfo_user"))
    cfo_user = res.scalar_one()
    res = await db_session.execute(sa.select(Group).where(Group.group_name == "CFO"))
    cfo_group = res.scalar_one()
    cfo_user.group_id = cfo_group.id
    await db_session.commit()

    # 2. Login as CEO to create contract
    resp = await client.post("/api/v1/auth/login", data={"username": "ceo_user", "password": "password123"})
    ceo_token = resp.json()["access_token"]
    ceo_headers = {"Authorization": f"Bearer {ceo_token}"}

    # Create contract (needs 150 score maybe)
    contract_data = {
        "title": "Board Resolution",
        "content": "Secret content",
        "contract_type": "legal", # Needs 150 score usually
        "amount": 0
    }
    resp = await client.post("/api/v1/contracts/", json=contract_data, headers=ceo_headers)
    contract_id = resp.json()["contract_id"]
    
    # Check initial status
    assert resp.json()["status"] == "pending"
    assert resp.json()["current_score"] == 0

    # 3. Sign as CEO (adds 100)
    resp = await client.post(f"/api/v1/contracts/{contract_id}/sign", headers=ceo_headers)
    assert resp.status_code == 200
    assert resp.json()["authority_score"] == 100

    # Verify partially signed status
    resp = await client.get(f"/api/v1/contracts/{contract_id}", headers=ceo_headers)
    assert resp.json()["current_score"] == 100
    assert resp.json()["status"] == "pending"

    # 4. Login as CFO to sign (adds 80)
    resp = await client.post("/api/v1/auth/login", data={"username": "cfo_user", "password": "password123"})
    cfo_token = resp.json()["access_token"]
    cfo_headers = {"Authorization": f"Bearer {cfo_token}"}

    resp = await client.post(f"/api/v1/contracts/{contract_id}/sign", headers=cfo_headers)
    assert resp.status_code == 200
    assert resp.json()["authority_score"] == 80

    # 5. Verify completed status (100 + 80 = 180 >= 150)
    resp = await client.get(f"/api/v1/contracts/{contract_id}", headers=ceo_headers)
    assert resp.json()["current_score"] == 180
    assert resp.json()["status"] == "completed"
