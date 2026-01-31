"""
Compliance Checker Agent

Uses Agno AI to validate contracts against compliance rules
"""

from typing import Dict, List, Optional
from pydantic import BaseModel, Field

from agno.agent import Agent
from agno.models.openai import OpenAIChat

from app.config import settings


class ComplianceResult(BaseModel):
    """Compliance check result output schema"""
    
    is_compliant: bool = Field(
        description="Whether the contract is compliant with all rules"
    )
    violations: List[str] = Field(
        description="List of compliance violations (empty if compliant)"
    )
    warnings: List[str] = Field(
        description="List of warnings or recommendations"
    )
    risk_level: str = Field(
        description="Risk level: 'low', 'medium', or 'high'"
    )
    recommendations: str = Field(
        description="Recommendations to make the contract compliant"
    )


class ComplianceCheckerAgent:
    """
    Compliance Checker Agent using Agno
    
    Validates contracts against:
    - Financial limits
    - Required approvals
    - Legal requirements
    - Company policies
    """
    
    def __init__(self):
        """Initialize Compliance Checker Agent"""
        self.agent = Agent(
            name="Compliance Checker",
            model=OpenAIChat(
                id="gpt-4o-mini",
                api_key=settings.OPENAI_API_KEY
            ),
            output_schema=ComplianceResult,
            instructions="""You are a compliance validation assistant for a hierarchical signature authorization system.

Your role is to validate contracts against company policies and compliance rules.

Compliance Rules:

1. Financial Limits:
   - Contracts > $100K require CEO approval (score >= 100)
   - Contracts > $50K require at least 2 signatures from C-level (CFO/CTO/CEO)
   - Contracts < $10K can be approved by Department Head

2. Contract Types:
   - Legal contracts MUST have CEO approval
   - HR contracts for executives MUST have CEO approval
   - Technical contracts > $25K MUST have CTO review
   - Financial contracts > $20K MUST have CFO review

3. Required Signatures:
   - Minimum 1 signature for contracts < $10K
   - Minimum 2 signatures for contracts $10K-$50K
   - Minimum 2 C-level signatures for contracts > $50K

4. Prohibited Actions:
   - Contracts with missing title or description
   - Contracts with negative amounts
   - Contracts with unrealistic amounts (> $1M without special approval)
   - Contracts without specified type

5. Warnings:
   - Contracts with vague descriptions
   - Contracts with unusually high amounts for their type
   - Contracts with very short approval deadlines

Risk Levels:
- Low: Standard contracts within normal parameters
- Medium: Contracts requiring extra attention or documentation
- High: Contracts with potential compliance issues or high financial impact

Output format:
- is_compliant: true/false
- violations: List of specific rule violations
- warnings: List of concerns or recommendations
- risk_level: low/medium/high
- recommendations: How to fix violations
""",
            markdown=False,
        )
    
    async def check_compliance(
        self,
        contract_title: str,
        contract_type: str,
        amount: Optional[float] = None,
        description: Optional[str] = None,
        required_score: int = 50,
        suggested_authorities: Optional[List[str]] = None
    ) -> ComplianceResult:
        """
        Check contract compliance
        
        Args:
            contract_title: Contract title
            contract_type: Contract type
            amount: Contract amount (optional)
            description: Contract description (optional)
            required_score: Required authority score
            suggested_authorities: Suggested authority groups (optional)
            
        Returns:
            ComplianceResult with validation details
        """
        # Build compliance check prompt
        prompt = f"""Check compliance for this contract:

Title: {contract_title}
Type: {contract_type}
Amount: ${amount:,.2f} USD" if amount else "Not specified"
Description: {description or "Not provided"}
Required Score: {required_score}
"""
        
        if suggested_authorities:
            prompt += f"\nSuggested Authorities: {', '.join(suggested_authorities)}"
        
        prompt += "\n\nValidate against all compliance rules and provide detailed analysis."
        
        # Run agent
        result = self.agent.run(prompt)
        
        return result.content
    
    def validate_basic_requirements(
        self,
        contract_title: str,
        contract_type: str,
        amount: Optional[float]
    ) -> Dict[str, bool]:
        """
        Perform basic validation checks (non-AI)
        
        Args:
            contract_title: Contract title
            contract_type: Contract type
            amount: Contract amount
            
        Returns:
            Dictionary of validation results
        """
        validations = {
            'has_title': bool(contract_title and contract_title.strip()),
            'has_type': bool(contract_type and contract_type.strip()),
            'valid_amount': amount is None or amount >= 0,
            'reasonable_amount': amount is None or amount <= 1_000_000,
        }
        
        return validations


# Global agent instance
_compliance_agent: Optional[ComplianceCheckerAgent] = None


def get_compliance_agent() -> ComplianceCheckerAgent:
    """
    Get global Compliance Checker Agent instance
    
    Returns:
        ComplianceCheckerAgent instance
    """
    global _compliance_agent
    
    if _compliance_agent is None:
        _compliance_agent = ComplianceCheckerAgent()
    
    return _compliance_agent


async def test_compliance_checker():
    """Test Compliance Checker Agent"""
    checker = get_compliance_agent()
    
    # Test case 1: Compliant contract
    print("Test 1: Standard compliant contract")
    result = await checker.check_compliance(
        contract_title="Office Supplies Purchase",
        contract_type="general",
        amount=5000,
        description="Purchase of office supplies for Q1 2024",
        required_score=50,
        suggested_authorities=["DEPT_HEAD"]
    )
    print(f"Compliant: {result.is_compliant}")
    print(f"Violations: {result.violations}")
    print(f"Risk: {result.risk_level}\n")
    
    # Test case 2: High-value contract
    print("Test 2: High-value contract requiring CEO")
    result = await checker.check_compliance(
        contract_title="Enterprise Software License",
        contract_type="financial",
        amount=150000,
        description="Annual license for enterprise software",
        required_score=100,
        suggested_authorities=["CEO", "CFO"]
    )
    print(f"Compliant: {result.is_compliant}")
    print(f"Violations: {result.violations}")
    print(f"Warnings: {result.warnings}")
    print(f"Risk: {result.risk_level}\n")
    
    # Test case 3: Non-compliant contract
    print("Test 3: Legal contract without CEO")
    result = await checker.check_compliance(
        contract_title="Partnership Agreement",
        contract_type="legal",
        amount=30000,
        description="Legal partnership agreement",
        required_score=50,
        suggested_authorities=["DEPT_HEAD"]
    )
    print(f"Compliant: {result.is_compliant}")
    print(f"Violations: {result.violations}")
    print(f"Recommendations: {result.recommendations}\n")


if __name__ == "__main__":
    import asyncio
    asyncio.run(test_compliance_checker())
