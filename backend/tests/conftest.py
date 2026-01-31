"""
Pytest configuration and fixtures
"""

import asyncio
from typing import AsyncGenerator, Generator

import pytest
from httpx import AsyncClient, ASGITransport
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker

from app.main import app
from app.config import settings
from app.db.session import get_db
from app.db.base import Base


# Override database URL for testing (use sqlite or a separate test db)
# For simplicity in this environment, we might reuse dev db or mock
# IMPORTANT: In a real CI, use a separate test DB.
TEST_DATABASE_URL = settings.DATABASE_URL.replace("monad_bilitz", "monad_bilitz_test")

# Create async engine for tests
test_engine = create_async_engine(settings.DATABASE_URL, echo=False)
TestingSessionLocal = async_sessionmaker(
    test_engine, class_=AsyncSession, expire_on_commit=False
)


@pytest.fixture(scope="session")
def event_loop() -> Generator:
    """Create an instance of the default event loop for each test case."""
    loop = asyncio.new_event_loop()
    yield loop
    loop.close()


@pytest.fixture(scope="session")
async def setup_db():
    """Setup test database"""
    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield
    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)


@pytest.fixture
async def db_session(setup_db) -> AsyncGenerator[AsyncSession, None]:
    """Get database session"""
    async with TestingSessionLocal() as session:
        yield session


from unittest.mock import MagicMock, AsyncMock, patch

# ... (rest of imports)

@pytest.fixture(autouse=True)
def mock_agents():
    """Mock Agno Agents globally for tests"""
    with patch("app.api.routes.contract_routes.get_smart_router_agent") as mock_router_getter, \
         patch("app.api.routes.contract_routes.get_compliance_agent") as mock_compliance_getter:
        
        # Mock Router Agent
        mock_router = MagicMock()
        mock_router.analyze_and_route = AsyncMock(return_value=MagicMock(
            suggested_authorities=["CEO", "CFO"],
            reasoning="Mocked reasoning",
            priority_level="high"
        ))
        mock_router.calculate_total_score.return_value = 180
        mock_router_getter.return_value = mock_router
        
        # Mock Compliance Agent
        mock_compliance = MagicMock()
        mock_compliance.check_compliance = AsyncMock(return_value=MagicMock(
            is_compliant=True,
            violations=[],
            recommendations=[]
        ))
        mock_compliance_getter.return_value = mock_compliance
        
        yield mock_router, mock_compliance


@pytest.fixture(autouse=True)
def mock_blockchain():
    """Mock Blockchain interaction"""
    with patch("app.api.routes.contract_routes.get_signature_authority") as mock_getter:
        mock_sa = AsyncMock()
        mock_sa.create_contract.return_value = "0xmock_tx_hash"
        mock_sa.add_signature.return_value = "0xmock_sig_hash"
        mock_getter.return_value = mock_sa
        yield mock_sa


@pytest.fixture
async def seed_groups(db_session: AsyncSession):
    """Seed essential groups for tests"""
    from app.models.hierarchy import Group
    
    groups = [
        Group(group_name="CEO", display_name="CEO", level=1, authority_score=100),
        Group(group_name="CFO", display_name="CFO", level=2, authority_score=80),
        Group(group_name="EMPLOYEE", display_name="Employee", level=5, authority_score=10),
    ]
    
    for g in groups:
        db_session.add(g)
    await db_session.commit()
    return groups


@pytest.fixture
async def client(db_session) -> AsyncGenerator[AsyncClient, None]:
    """Get test client"""
    
    # Override get_db dependency
    async def override_get_db():
        yield db_session

    app.dependency_overrides[get_db] = override_get_db
    
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        yield ac
    
    app.dependency_overrides.clear()
