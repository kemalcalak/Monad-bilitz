"""
Unit tests for Hierarchy Service
"""

import pytest
import uuid
from unittest.mock import AsyncMock, MagicMock
from app.services.hierarchy_service import HierarchyService
from app.models.hierarchy import Group


@pytest.fixture
def mock_db():
    return AsyncMock()


@pytest.fixture
def hierarchy_service(mock_db):
    return HierarchyService(mock_db)


class TestHierarchyService:
    """Test group for HierarchyService"""

    def test_calculate_required_score(self, hierarchy_service):
        """Test calculation of required scores based on rules"""
        # Legal contracts always 150
        assert hierarchy_service.calculate_required_score("legal") == 150
        assert hierarchy_service.calculate_required_score("legal", 500) == 150
        
        # Amount based rules
        assert hierarchy_service.calculate_required_score("general", 5000) == 50
        assert hierarchy_service.calculate_required_score("general", 9999) == 50
        assert hierarchy_service.calculate_required_score("general", 10000) == 100
        assert hierarchy_service.calculate_required_score("general", 49999) == 100
        assert hierarchy_service.calculate_required_score("general", 50000) == 150
        assert hierarchy_service.calculate_required_score("general", 1000000) == 150
        
        # Default
        assert hierarchy_service.calculate_required_score("general") == 50

    @pytest.mark.asyncio
    async def test_get_group_by_name(self, hierarchy_service, mock_db):
        """Test getting a group by name"""
        mock_group = Group(id=uuid.uuid4(), group_name="CEO", display_name="Chief Executive Officer")
        
        # Mocking SQLAlchemy result
        mock_result = MagicMock()
        mock_result.scalar_one_or_none.return_value = mock_group
        mock_db.execute.return_value = mock_result
        
        group = await hierarchy_service.get_group_by_name("CEO")
        
        assert group is not None
        assert group.group_name == "CEO"
        mock_db.execute.assert_called_once()

    @pytest.mark.asyncio
    async def test_validate_access_same_group(self, hierarchy_service):
        """Access within same group should always be True"""
        group_id = uuid.uuid4()
        result = await hierarchy_service.validate_access(group_id, group_id)
        assert result is True

    @pytest.mark.asyncio
    async def test_create_group_duplicate_error(self, hierarchy_service, mock_db):
        """Creating an existing group should raise ValueError"""
        mock_group = Group(group_name="CEO")
        
        # Mocking that group already exists
        mock_result = MagicMock()
        mock_result.scalar_one_or_none.return_value = mock_group
        mock_db.execute.return_value = mock_result
        
        with pytest.raises(ValueError, match="Group CEO already exists"):
            await hierarchy_service.create_group(
                group_name="CEO",
                display_name="CEO",
                level=1,
                authority_score=100,
                ou_id=uuid.uuid4()
            )
