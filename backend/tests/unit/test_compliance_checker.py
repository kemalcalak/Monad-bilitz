"""
Unit tests for Compliance Checker Agent
"""

import pytest
from unittest.mock import MagicMock, patch
from app.core.agents.compliance_checker import ComplianceCheckerAgent, ComplianceResult


@pytest.fixture
def compliance_checker():
    with patch('app.core.agents.compliance_checker.settings') as mock_settings:
        mock_settings.OPENAI_API_KEY = "test-key"
        return ComplianceCheckerAgent()


class TestComplianceCheckerAgent:
    """Test group for ComplianceCheckerAgent"""

    def test_validate_basic_requirements(self, compliance_checker):
        """Test non-AI basic validation rules"""
        # Valid case
        res = compliance_checker.validate_basic_requirements("Title", "general", 1000)
        assert all(res.values())
        
        # Missing title
        res = compliance_checker.validate_basic_requirements("", "general", 1000)
        assert res['has_title'] is False
        
        # Missing type
        res = compliance_checker.validate_basic_requirements("Title", "", 1000)
        assert res['has_type'] is False
        
        # Negative amount
        res = compliance_checker.validate_basic_requirements("Title", "general", -10)
        assert res['valid_amount'] is False
        
        # Unreasonable amount
        res = compliance_checker.validate_basic_requirements("Title", "general", 2_000_000)
        assert res['reasonable_amount'] is False

    @pytest.mark.asyncio
    async def test_check_compliance_mock(self, compliance_checker):
        """Test compliance check with mocked LLM response"""
        mock_response = MagicMock()
        mock_response.content = ComplianceResult(
            is_compliant=True,
            violations=[],
            warnings=["Vague description"],
            risk_level="low",
            recommendations="Provide more detail in description"
        )
        
        with patch.object(compliance_checker.agent, 'run', return_value=mock_response) as mock_run:
            result = await compliance_checker.check_compliance(
                contract_title="Office Supplies",
                contract_type="general",
                amount=5000,
                description="Buying pens"
            )
            
            assert result.is_compliant is True
            assert result.risk_level == "low"
            mock_run.assert_called_once()
            
            # Verify prompt contents
            call_args = mock_run.call_args[0][0]
            assert "Office Supplies" in call_args
            assert "$5,000.00" in call_args
