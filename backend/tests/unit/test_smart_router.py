"""
Unit tests for Smart Router Agent
"""

import pytest
from unittest.mock import MagicMock, patch
from app.core.agents.smart_router import SmartRouterAgent, RoutingSuggestion


@pytest.fixture
def smart_router():
    # Use a mock for settings or ensure OPENAI_API_KEY doesn't fail init
    with patch('app.core.agents.smart_router.settings') as mock_settings:
        mock_settings.OPENAI_API_KEY = "test-key"
        return SmartRouterAgent()


class TestSmartRouterAgent:
    """Test group for SmartRouterAgent"""

    def test_calculate_total_score(self, smart_router):
        """Test score summation of authority groups"""
        # Single groups
        assert smart_router.calculate_total_score(['CEO']) == 100
        assert smart_router.calculate_total_score(['CFO']) == 80
        assert smart_router.calculate_total_score(['EMPLOYEE']) == 10
        
        # Combinations
        assert smart_router.calculate_total_score(['CEO', 'CFO']) == 180
        assert smart_router.calculate_total_score(['CTO', 'DEPT_HEAD', 'MANAGER']) == 160
        
        # Unknown group
        assert smart_router.calculate_total_score(['UNKNOWN']) == 0
        assert smart_router.calculate_total_score(['CEO', 'UNKNOWN']) == 100

    @pytest.mark.asyncio
    async def test_analyze_and_route_mock(self, smart_router):
        """Test agent routing with mocked LLM response"""
        # Mocking the internal agent.run method
        mock_response = MagicMock()
        mock_response.content = RoutingSuggestion(
            suggested_authorities=['CEO', 'CFO'],
            reasoning="High value financial contract requires executive approval",
            priority_level="high",
            estimated_approval_time="1-2 days"
        )
        
        # Correctly patching the run method of the Agno Agent instance
        with patch.object(smart_router.agent, 'run', return_value=mock_response) as mock_run:
            result = await smart_router.analyze_and_route(
                contract_title="Big Purchase",
                contract_type="financial",
                amount=100000,
                urgency="high"
            )
            
            assert result.suggested_authorities == ['CEO', 'CFO']
            assert result.priority_level == "high"
            mock_run.assert_called_once()
            
            # Check if prompt contains key info
            call_args = mock_run.call_args[0][0]
            assert "Big Purchase" in call_args
            assert "financial" in call_args
            assert "$100,000.00" in call_args
