"""
Error Handler Agent

Uses Agno AI to analyze and suggest recovery strategies for blockchain transaction errors
"""

from typing import Dict, Optional
from pydantic import BaseModel, Field

from agno.agent import Agent
from agno.models.openai import OpenAIChat

from app.config import settings


class ErrorRecoveryStrategy(BaseModel):
    """Error recovery strategy output schema"""
    
    error_category: str = Field(
        description="Category of error: 'gas', 'nonce', 'revert', 'network', 'validation', 'other'"
    )
    severity: str = Field(
        description="Severity level: 'low', 'medium', 'high', 'critical'"
    )
    is_recoverable: bool = Field(
        description="Whether the error is recoverable"
    )
    recovery_steps: list[str] = Field(
        description="Step-by-step recovery instructions"
    )
    retry_recommended: bool = Field(
        description="Whether retrying the transaction is recommended"
    )
    user_action_required: bool = Field(
        description="Whether user action is required to resolve"
    )
    explanation: str = Field(
        description="Clear explanation of what went wrong and why"
    )


class ErrorHandlerAgent:
    """
    Error Handler Agent using Agno
    
    Analyzes blockchain transaction errors and suggests recovery strategies
    """
    
    def __init__(self):
        """Initialize Error Handler Agent"""
        self.agent = Agent(
            name="Error Handler",
            model=OpenAIChat(
                id="gpt-4o-mini",
                api_key=settings.OPENAI_API_KEY
            ),
            output_schema=ErrorRecoveryStrategy,
            instructions="""You are an expert blockchain transaction error analyst for a Monad testnet application.

Your role is to analyze transaction errors and provide clear recovery strategies.

Common Error Categories:

1. GAS ERRORS:
   - "out of gas": Gas limit too low
   - "insufficient funds for gas": Not enough MON for gas fees
   - "gas price too low": Gas price below network minimum
   
   Recovery: Increase gas limit, check balance, adjust gas price

2. NONCE ERRORS:
   - "nonce too low": Transaction already processed
   - "nonce too high": Gap in transaction sequence
   - "replacement transaction underpriced": Need higher gas for replacement
   
   Recovery: Fetch current nonce, wait for pending transactions, increase gas price

3. REVERT ERRORS:
   - "execution reverted": Smart contract rejected transaction
   - "require condition failed": Contract requirement not met
   - "invalid signature": Signature verification failed
   
   Recovery: Check contract requirements, verify inputs, check permissions

4. NETWORK ERRORS:
   - "connection timeout": Network connectivity issue
   - "RPC error": RPC endpoint problem
   - "block not found": Chain reorganization
   
   Recovery: Retry with backoff, switch RPC endpoint, wait for chain sync

5. VALIDATION ERRORS:
   - "invalid address": Malformed Ethereum address
   - "invalid amount": Negative or invalid value
   - "missing required field": Incomplete transaction data
   
   Recovery: Validate inputs, fix data format, check requirements

Severity Levels:
- Low: Minor issues, automatic retry possible
- Medium: Requires configuration change or user notification
- High: Requires user action or manual intervention
- Critical: System-level issue, may need escalation

Output Guidelines:
- Provide clear, actionable recovery steps
- Explain technical errors in user-friendly language
- Indicate if automatic retry is safe
- Specify if user action is needed
- Categorize error accurately
""",
            markdown=False,
            show_tool_calls=False,
        )
    
    async def analyze_error(
        self,
        error_message: str,
        transaction_data: Optional[Dict] = None,
        context: Optional[str] = None
    ) -> ErrorRecoveryStrategy:
        """
        Analyze transaction error and suggest recovery
        
        Args:
            error_message: Error message from blockchain
            transaction_data: Transaction details (optional)
            context: Additional context (optional)
            
        Returns:
            ErrorRecoveryStrategy with recovery steps
        """
        # Build analysis prompt
        prompt = f"""Analyze this blockchain transaction error:

Error Message: {error_message}
"""
        
        if transaction_data:
            prompt += f"\nTransaction Data:\n"
            for key, value in transaction_data.items():
                prompt += f"  {key}: {value}\n"
        
        if context:
            prompt += f"\nContext: {context}"
        
        prompt += "\n\nProvide detailed error analysis and recovery strategy."
        
        # Run agent
        result = self.agent.run(prompt)
        
        return result.content
    
    def should_retry_automatically(self, error_category: str, severity: str) -> bool:
        """
        Determine if error should be retried automatically
        
        Args:
            error_category: Error category
            severity: Error severity
            
        Returns:
            True if automatic retry is safe
        """
        # Only retry low/medium severity network errors automatically
        if error_category == "network" and severity in ["low", "medium"]:
            return True
        
        # Retry low severity gas errors (may need adjustment)
        if error_category == "gas" and severity == "low":
            return True
        
        return False


# Global agent instance
_error_handler_agent: Optional[ErrorHandlerAgent] = None


def get_error_handler_agent() -> ErrorHandlerAgent:
    """
    Get global Error Handler Agent instance
    
    Returns:
        ErrorHandlerAgent instance
    """
    global _error_handler_agent
    
    if _error_handler_agent is None:
        _error_handler_agent = ErrorHandlerAgent()
    
    return _error_handler_agent


async def test_error_handler():
    """Test Error Handler Agent"""
    handler = get_error_handler_agent()
    
    # Test case 1: Gas error
    print("Test 1: Out of gas error")
    result = await handler.analyze_error(
        error_message="execution reverted: out of gas",
        transaction_data={
            "to": "0x1234...",
            "gas": 100000,
            "gasPrice": "1000000000"
        }
    )
    print(f"Category: {result.error_category}")
    print(f"Severity: {result.severity}")
    print(f"Recoverable: {result.is_recoverable}")
    print(f"Recovery Steps: {result.recovery_steps}")
    print(f"Retry: {result.retry_recommended}\n")
    
    # Test case 2: Nonce error
    print("Test 2: Nonce too low")
    result = await handler.analyze_error(
        error_message="nonce too low",
        context="User tried to submit transaction while previous one was pending"
    )
    print(f"Category: {result.error_category}")
    print(f"Explanation: {result.explanation}")
    print(f"User Action Required: {result.user_action_required}\n")
    
    # Test case 3: Contract revert
    print("Test 3: Contract requirement failed")
    result = await handler.analyze_error(
        error_message="execution reverted: Only owner can call this function",
        transaction_data={
            "function": "updateGroupScore",
            "from": "0x5678..."
        }
    )
    print(f"Category: {result.error_category}")
    print(f"Severity: {result.severity}")
    print(f"Recovery Steps: {result.recovery_steps}\n")


if __name__ == "__main__":
    import asyncio
    asyncio.run(test_error_handler())
