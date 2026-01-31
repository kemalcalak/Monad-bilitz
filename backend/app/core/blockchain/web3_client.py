"""
Web3 Client for Monad Testnet

Handles blockchain connection, transaction signing, and submission
"""

import asyncio
from typing import Optional, Dict, Any
from web3 import Web3
from web3.middleware import ExtraDataToPOAMiddleware
from eth_account import Account
from eth_account.signers.local import LocalAccount

from app.config import settings


class MonadClient:
    """
    Web3 client for Monad testnet
    
    Handles:
    - Connection to Monad RPC
    - Transaction signing and submission
    - Gas estimation
    - Nonce management
    """
    
    def __init__(
        self,
        rpc_url: Optional[str] = None,
        private_key: Optional[str] = None
    ):
        """
        Initialize Monad client
        
        Args:
            rpc_url: Monad RPC URL (defaults to settings)
            private_key: Admin wallet private key (defaults to settings)
        """
        self.rpc_url = rpc_url or settings.MONAD_RPC_URL
        self.private_key = private_key or settings.ADMIN_WALLET_PRIVATE_KEY
        
        # Initialize Web3
        self.w3 = Web3(Web3.HTTPProvider(self.rpc_url))
        
        # Add PoA middleware (Monad uses PoS but this helps with compatibility)
        self.w3.middleware_onion.inject(ExtraDataToPOAMiddleware, layer=0)
        
        # Initialize account if private key provided
        self.account: Optional[LocalAccount] = None
        if self.private_key:
            self.account = Account.from_key(self.private_key)
        
        # Verify connection
        if not self.w3.is_connected():
            raise ConnectionError(f"Failed to connect to Monad RPC: {self.rpc_url}")
    
    def is_connected(self) -> bool:
        """Check if connected to blockchain"""
        return self.w3.is_connected()
    
    async def get_balance(self, address: str) -> int:
        """
        Get balance of an address in wei
        
        Args:
            address: Ethereum address
            
        Returns:
            Balance in wei
        """
        return self.w3.eth.get_balance(address)
    
    async def get_balance_eth(self, address: str) -> float:
        """
        Get balance of an address in ETH (MON)
        
        Args:
            address: Ethereum address
            
        Returns:
            Balance in ETH
        """
        balance_wei = await self.get_balance(address)
        return self.w3.from_wei(balance_wei, 'ether')
    
    async def get_nonce(self, address: Optional[str] = None) -> int:
        """
        Get transaction nonce for an address
        
        Args:
            address: Address (defaults to account address)
            
        Returns:
            Nonce
        """
        addr = address or (self.account.address if self.account else None)
        if not addr:
            raise ValueError("No address provided and no account set")
        
        return self.w3.eth.get_transaction_count(addr)
    
    async def estimate_gas(self, transaction: Dict[str, Any]) -> int:
        """
        Estimate gas for a transaction
        
        Args:
            transaction: Transaction dict
            
        Returns:
            Estimated gas
        """
        try:
            return self.w3.eth.estimate_gas(transaction)
        except Exception as e:
            # If estimation fails, return a safe default
            print(f"Gas estimation failed: {e}. Using default.")
            return 200000
    
    async def get_gas_price(self) -> int:
        """
        Get current gas price
        
        Returns:
            Gas price in wei
        """
        return self.w3.eth.gas_price
    
    async def send_transaction(
        self,
        to: str,
        data: str = "0x",
        value: int = 0,
        gas_limit: Optional[int] = None,
        gas_price: Optional[int] = None
    ) -> str:
        """
        Send a transaction to the blockchain
        
        Args:
            to: Recipient address
            data: Transaction data (hex string)
            value: Value to send in wei
            gas_limit: Gas limit (auto-estimated if not provided)
            gas_price: Gas price (auto-fetched if not provided)
            
        Returns:
            Transaction hash (hex string)
        """
        if not self.account:
            raise ValueError("No account set. Provide private key in constructor.")
        
        # Get nonce
        nonce = await self.get_nonce()
        
        # Build transaction
        transaction = {
            'from': self.account.address,
            'to': to,
            'value': value,
            'data': data,
            'nonce': nonce,
            'chainId': settings.MONAD_CHAIN_ID,
        }
        
        # Estimate gas if not provided
        if gas_limit is None:
            gas_limit = await self.estimate_gas(transaction)
        transaction['gas'] = gas_limit
        
        # Get gas price if not provided
        if gas_price is None:
            gas_price = await self.get_gas_price()
        transaction['gasPrice'] = gas_price
        
        # Sign transaction
        signed_tx = self.w3.eth.account.sign_transaction(
            transaction,
            self.account.key
        )
        
        # Send transaction
        tx_hash = self.w3.eth.send_raw_transaction(signed_tx.rawTransaction)
        
        return tx_hash.hex()
    
    async def wait_for_transaction_receipt(
        self,
        tx_hash: str,
        timeout: int = 120,
        poll_interval: float = 1.0
    ) -> Dict[str, Any]:
        """
        Wait for transaction to be mined
        
        Args:
            tx_hash: Transaction hash
            timeout: Timeout in seconds
            poll_interval: Polling interval in seconds
            
        Returns:
            Transaction receipt
        """
        start_time = asyncio.get_event_loop().time()
        
        while True:
            try:
                receipt = self.w3.eth.get_transaction_receipt(tx_hash)
                if receipt is not None:
                    return dict(receipt)
            except Exception:
                pass
            
            # Check timeout
            if asyncio.get_event_loop().time() - start_time > timeout:
                raise TimeoutError(f"Transaction {tx_hash} not mined after {timeout}s")
            
            # Wait before next poll
            await asyncio.sleep(poll_interval)
    
    async def call_contract_function(
        self,
        contract_address: str,
        function_data: str,
        from_address: Optional[str] = None
    ) -> Any:
        """
        Call a contract function (read-only, no transaction)
        
        Args:
            contract_address: Contract address
            function_data: Encoded function data
            from_address: Caller address (optional)
            
        Returns:
            Function result
        """
        call_params = {
            'to': contract_address,
            'data': function_data,
        }
        
        if from_address:
            call_params['from'] = from_address
        
        return self.w3.eth.call(call_params)
    
    def get_block_number(self) -> int:
        """Get current block number"""
        return self.w3.eth.block_number
    
    async def get_transaction(self, tx_hash: str) -> Dict[str, Any]:
        """
        Get transaction details
        
        Args:
            tx_hash: Transaction hash
            
        Returns:
            Transaction dict
        """
        tx = self.w3.eth.get_transaction(tx_hash)
        return dict(tx) if tx else {}


# Global client instance
_monad_client: Optional[MonadClient] = None


def get_monad_client() -> MonadClient:
    """
    Get global Monad client instance
    
    Returns:
        MonadClient instance
    """
    global _monad_client
    
    if _monad_client is None:
        _monad_client = MonadClient()
    
    return _monad_client


async def test_connection():
    """Test Monad connection"""
    client = get_monad_client()
    
    print(f"🔗 Connected to Monad: {client.is_connected()}")
    print(f"📊 Chain ID: {settings.MONAD_CHAIN_ID}")
    print(f"🔢 Block number: {client.get_block_number()}")
    
    if client.account:
        print(f"👤 Account: {client.account.address}")
        balance = await client.get_balance_eth(client.account.address)
        print(f"💰 Balance: {balance:.4f} MON")


if __name__ == "__main__":
    asyncio.run(test_connection())
