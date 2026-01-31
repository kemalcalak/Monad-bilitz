"""
Smart Router Agent

Uses Agno AI to analyze contracts and suggest optimal routing to authorities
"""

from typing import Dict, List, Optional
from pydantic import BaseModel, Field

from agno.agent import Agent
from agno.models.openai import OpenAIChat

from app.config import settings


class RoutingSuggestion(BaseModel):
    """Routing suggestion output schema"""
    
    suggested_authorities: List[str] = Field(
        description="List of suggested authority group IDs (e.g., ['CEO', 'CFO'])"
    )
    reasoning: str = Field(
        description="Explanation of why these authorities were suggested"
    )
    priority_level: str = Field(
        description="Priority level: 'high', 'medium', or 'low'"
    )
    estimated_approval_time: str = Field(
        description="Estimated time to get approval (e.g., '1-2 days')"
    )


class SmartRouterAgent:
    """
    Smart Router Agent using Agno
    
    Analyzes contract details and suggests optimal routing to authorities
    based on:
    - Contract type
    - Amount
    - Urgency
    - Historical patterns
    """
    
    def __init__(self):
        """Initialize Smart Router Agent"""
        self.agent = Agent(
            name="Smart Router",
            model=OpenAIChat(
                id="gpt-4o-mini",
                api_key=settings.OPENAI_API_KEY
            ),
            output_schema=RoutingSuggestion,
            instructions="""You are an intelligent contract routing assistant for a hierarchical signature authorization system.

Your role is to analyze contract details and suggest the optimal authorities to route the contract to for approval.

Authority Groups and Scores:
- CEO (Chief Executive Officer): Score 100
- CFO (Chief Financial Officer): Score 80
- CTO (Chief Technology Officer): Score 80
- DEPT_HEAD (Department Head): Score 50
- MANAGER (Manager): Score 30
- EMPLOYEE (Employee): Score 10

Routing Rules:
1. Financial contracts:
   - Amount < $10K: DEPT_HEAD or MANAGER (total score >= 50)
   - Amount $10K-$50K: CFO or CEO (total score >= 100)
   - Amount > $50K: CEO + CFO or CEO + CTO (total score >= 150)

2. Technical contracts:
   - Low complexity: CTO or DEPT_HEAD (score >= 50)
   - High complexity: CTO + CEO (score >= 180)

3. Legal contracts:
   - Always require CEO + CFO (score >= 180)

4. HR contracts:
   - Standard: DEPT_HEAD (score >= 50)
   - Executive level: CEO (score >= 100)

5. General contracts:
   - Use amount-based rules if amount is specified
   - Otherwise, route to DEPT_HEAD (score >= 50)

Consider:
- Minimize number of signers while meeting score requirement
- Prioritize higher authorities for urgent or high-value contracts
- Suggest backup authorities if primary ones are unavailable

Output format:
- suggested_authorities: List of group IDs
- reasoning: Clear explanation
- priority_level: high/medium/low
- estimated_approval_time: Realistic estimate
""",
            markdown=False,
        )
    
    async def analyze_and_route(
        self,
        contract_title: str,
        contract_type: str,
        amount: Optional[float] = None,
        urgency: str = "normal",
        description: Optional[str] = None
    ) -> RoutingSuggestion:
        """
        Analyze contract and suggest routing
        
        Args:
            contract_title: Contract title
            contract_type: Type (financial, technical, legal, hr, general)
            amount: Contract amount in USD (optional)
            urgency: Urgency level (low, normal, high)
            description: Additional description (optional)
            
        Returns:
            RoutingSuggestion with suggested authorities
        """
        # Build analysis prompt
        prompt = f"""Analyze this contract and suggest optimal routing:

Title: {contract_title}
Type: {contract_type}
Amount: ${amount:,.2f} USD" if amount else "Not specified"
Urgency: {urgency}
"""
        
        if description:
            prompt += f"\nDescription: {description}"
        
        prompt += "\n\nProvide routing suggestion with reasoning."
        
        # Run agent
        result = self.agent.run(prompt)
        
        return result.content
    
    def calculate_total_score(self, authority_groups: List[str]) -> int:
        """
        Calculate total authority score for a list of groups
        
        Args:
            authority_groups: List of group IDs
            
        Returns:
            Total score
        """
        score_map = {
            'CEO': 100,
            'CFO': 80,
            'CTO': 80,
            'DEPT_HEAD': 50,
            'MANAGER': 30,
            'EMPLOYEE': 10,
        }
        
        return sum(score_map.get(group, 0) for group in authority_groups)


# Global agent instance (reuse for performance)
_smart_router_agent: Optional[SmartRouterAgent] = None


def get_smart_router_agent() -> SmartRouterAgent:
    """
    Get global Smart Router Agent instance
    
    Returns:
        SmartRouterAgent instance
    """
    global _smart_router_agent
    
    if _smart_router_agent is None:
        _smart_router_agent = SmartRouterAgent()
    
    return _smart_router_agent


async def test_smart_router():
    """Test Smart Router Agent"""
    router = get_smart_router_agent()
    
    # Test case 1: High-value financial contract
    print("Test 1: High-value financial contract")
    result = await router.analyze_and_route(
        contract_title="Annual Budget Approval 2024",
        contract_type="financial",
        amount=75000,
        urgency="high"
    )
    print(f"Suggested: {result.suggested_authorities}")
    print(f"Reasoning: {result.reasoning}")
    print(f"Priority: {result.priority_level}")
    print(f"Total Score: {router.calculate_total_score(result.suggested_authorities)}\n")
    
    # Test case 2: Technical contract
    print("Test 2: Technical contract")
    result = await router.analyze_and_route(
        contract_title="Cloud Infrastructure Migration",
        contract_type="technical",
        urgency="normal",
        description="Migrate to AWS with high complexity"
    )
    print(f"Suggested: {result.suggested_authorities}")
    print(f"Reasoning: {result.reasoning}\n")


if __name__ == "__main__":
    import asyncio
    asyncio.run(test_smart_router())
