"""
Contract Management Team

A team of agents that collaborate to analyze and validate contracts.
Uses Agno (Phidata) Team architecture.
"""

from typing import Optional, List
from pydantic import BaseModel, Field
from agno.agent import Agent
from agno.models.openai import OpenAIChat
# from agno.team import Team # Not: Agno sürümüne göre Team import'u değişebilir, Agent listesi ile simüle edebiliriz. 
# Agno v1.0 yapısında Team genellikle birden fazla Agent'ı yöneten bir üst yapı veya birbirini bilen Agent'lardır.

from app.config import settings
from app.core.agents.smart_router import get_smart_router_agent
from app.core.agents.compliance_checker import get_compliance_agent


class AnalysisResult(BaseModel):
    """Combined analysis result from the team"""
    summary: str = Field(description="Executive summary of the contract analysis")
    final_verdict: str = Field(description="'APPROVED' or 'REJECTED'")
    suggested_route: List[str] = Field(description="Final list of approvers")
    risk_assessment: str = Field(description="Combined risk assessment")
    is_compliant: bool = Field(description="Is the contract fully compliant")


class ContractTeam:
    """
    Orchestrates collaboration between SmartRouter and Compliance agents.
    """
    
    def __init__(self):
        # Get existing specialists
        self.router = get_smart_router_agent().agent
        self.compliance = get_compliance_agent().agent
        
        # Create the Team Leader
        # Since 'team' param is not directly supported in this version of Agent,
        # we will use the agents manually in the execute flow or use delegation tools if we were using function calling.
        # For simplicity and robustness, we will effectively orchestrate them in Python code (Manager Pattern),
        # as this gives us more control over the specific workflow (Router -> Compliance -> Verdict).
        
        self.team_leader = Agent(
            name="Contract Manager",
            model=OpenAIChat(id="gpt-4o", api_key=settings.OPENAI_API_KEY),
            output_schema=AnalysisResult,
            markdown=False,
            instructions="""You are the Contract Manager. 
            You will receive inputs from a 'Smart Router' and a 'Compliance Checker'.
            Your job is to synthesize their findings into a final decision.
            """
        )

    async def analyze_contract(
        self,
        title: str,
        content: str,
        contract_type: str,
        amount: float,
        urgency: str
    ) -> AnalysisResult:
        """
        Run the full team analysis workflow (Manual Orchestration)
        """
        # 1. Ask Smart Router
        router_prompt = f"""Analyze routing for:
        Title: {title}
        Type: {contract_type}
        Amount: ${amount}
        Urgency: {urgency}
        """
        routing_result = self.router.run(router_prompt).content
        
        # 2. Ask Compliance Checker (giving it the router's suggestion)
        compliance_prompt = f"""Check compliance for:
        Title: {title}
        Type: {contract_type}
        Amount: ${amount}
        Content: {content[:500]}
        
        Suggested Routing: {routing_result.suggested_authorities}
        """
        compliance_result = self.compliance.run(compliance_prompt).content
        
        # 3. Manager synthesizes the final result
        leader_prompt = f"""
        Synthesize a final verdict based on these reports:
        
        [Smart Router Report]
        Suggested Authorities: {routing_result.suggested_authorities}
        Reasoning: {routing_result.reasoning}
        
        [Compliance Report]
        Is Compliant: {compliance_result.is_compliant}
        Violations: {compliance_result.violations}
        Risk Level: {compliance_result.risk_level}
        
        Task:
        - If not compliant, REJECT.
        - If compliant, APPROVE.
        - Create a risk assessment summary.
        """
        
        response = self.team_leader.run(leader_prompt)
        return response.content

# Global instance
_contract_team: Optional[ContractTeam] = None

def get_contract_team() -> ContractTeam:
    global _contract_team
    if _contract_team is None:
        _contract_team = ContractTeam()
    return _contract_team
