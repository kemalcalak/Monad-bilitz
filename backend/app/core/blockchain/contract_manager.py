"""
Contract Manager for Smart Contract Interactions

Handles interactions with HierarchyManager and SignatureAuthority contracts
"""

import json
from typing import Dict, List, Optional, Any
from pathlib import Path

from web3 import Web3
from web3.contract import Contract

from app.core.blockchain.web3_client import MonadClient, get_monad_client


class ContractManager:
    """
    Manager for smart contract interactions
    
    Handles:
    - Contract deployment
    - Function calls
    - Event filtering
    """
    
    def __init__(
        self,
        contract_address: str,
        abi: List[Dict],
        client: Optional[MonadClient] = None
    ):
        """
        Initialize contract manager
        
        Args:
            contract_address: Deployed contract address
            abi: Contract ABI
            client: MonadClient instance (optional)
        """
        self.client = client or get_monad_client()
        self.contract_address = Web3.to_checksum_address(contract_address)
        self.abi = abi
        
        # Create contract instance
        self.contract: Contract = self.client.w3.eth.contract(
            address=self.contract_address,
            abi=self.abi
        )
    
    async def call_function(
        self,
        function_name: str,
        *args,
        from_address: Optional[str] = None
    ) -> Any:
        """
        Call a contract function (read-only)
        
        Args:
            function_name: Function name
            *args: Function arguments
            from_address: Caller address (optional)
            
        Returns:
            Function result
        """
        function = getattr(self.contract.functions, function_name)
        
        if from_address:
            return function(*args).call({'from': from_address})
        else:
            return function(*args).call()
    
    async def send_transaction(
        self,
        function_name: str,
        *args,
        value: int = 0,
        gas_limit: Optional[int] = None
    ) -> str:
        """
        Send a transaction to a contract function
        
        Args:
            function_name: Function name
            *args: Function arguments
            value: ETH value to send (wei)
            gas_limit: Gas limit (optional)
            
        Returns:
            Transaction hash
        """
        function = getattr(self.contract.functions, function_name)
        
        # Build transaction
        function_call = function(*args)
        
        # Encode function data
        data = function_call._encode_transaction_data()
        
        # Send transaction
        tx_hash = await self.client.send_transaction(
            to=self.contract_address,
            data=data,
            value=value,
            gas_limit=gas_limit
        )
        
        return tx_hash
    
    async def get_events(
        self,
        event_name: str,
        from_block: int = 0,
        to_block: str = 'latest'
    ) -> List[Dict]:
        """
        Get past events from contract
        
        Args:
            event_name: Event name
            from_block: Starting block
            to_block: Ending block
            
        Returns:
            List of events
        """
        event = getattr(self.contract.events, event_name)
        
        events = event.get_logs(
            fromBlock=from_block,
            toBlock=to_block
        )
        
        return [dict(e) for e in events]


class HierarchyManagerContract(ContractManager):
    """
    HierarchyManager contract interface
    """
    
    async def create_group(
        self,
        group_id: str,
        name: str,
        level: int,
        authority_score: int
    ) -> str:
        """
        Create a new group
        
        Args:
            group_id: Unique group identifier
            name: Display name
            level: Hierarchy level
            authority_score: Authority score
            
        Returns:
            Transaction hash
        """
        return await self.send_transaction(
            'createGroup',
            group_id,
            name,
            level,
            authority_score
        )
    
    async def update_group_score(
        self,
        group_id: str,
        new_authority_score: int
    ) -> str:
        """
        Update group authority score
        
        Args:
            group_id: Group identifier
            new_authority_score: New score
            
        Returns:
            Transaction hash
        """
        return await self.send_transaction(
            'updateGroupScore',
            group_id,
            new_authority_score
        )
    
    async def assign_user(
        self,
        user_address: str,
        group_id: str
    ) -> str:
        """
        Assign user to a group
        
        Args:
            user_address: User wallet address
            group_id: Group identifier
            
        Returns:
            Transaction hash
        """
        return await self.send_transaction(
            'assignUser',
            user_address,
            group_id
        )
    
    async def get_group(self, group_id: str) -> Dict:
        """
        Get group information
        
        Args:
            group_id: Group identifier
            
        Returns:
            Group data
        """
        result = await self.call_function('getGroup', group_id)
        
        return {
            'groupId': result[0],
            'name': result[1],
            'level': result[2],
            'authorityScore': result[3],
            'exists': result[4],
            'createdAt': result[5],
        }
    
    async def get_user_group(self, user_address: str) -> str:
        """
        Get user's group ID
        
        Args:
            user_address: User wallet address
            
        Returns:
            Group ID
        """
        return await self.call_function('getUserGroup', user_address)
    
    async def get_user_authority_score(self, user_address: str) -> int:
        """
        Get user's authority score
        
        Args:
            user_address: User wallet address
            
        Returns:
            Authority score
        """
        return await self.call_function('getUserAuthorityScore', user_address)


class SignatureAuthorityContract(ContractManager):
    """
    SignatureAuthority contract interface
    """
    
    async def create_contract(
        self,
        contract_id: str,
        required_score: int
    ) -> str:
        """
        Create a new contract
        
        Args:
            contract_id: Unique contract identifier
            required_score: Required authority score
            
        Returns:
            Transaction hash
        """
        return await self.send_transaction(
            'createContract',
            contract_id,
            required_score
        )
    
    async def add_signature(
        self,
        contract_id: str,
        signer_score: int
    ) -> str:
        """
        Add signature to a contract
        
        Args:
            contract_id: Contract identifier
            signer_score: Signer's authority score
            
        Returns:
            Transaction hash
        """
        return await self.send_transaction(
            'addSignature',
            contract_id,
            signer_score
        )
    
    async def get_contract(self, contract_id: str) -> Dict:
        """
        Get contract information
        
        Args:
            contract_id: Contract identifier
            
        Returns:
            Contract data
        """
        result = await self.call_function('getContract', contract_id)
        
        return {
            'contractId': result[0],
            'creator': result[1],
            'requiredScore': result[2],
            'currentScore': result[3],
            'finalized': result[4],
            'createdAt': result[5],
            'finalizedAt': result[6],
        }
    
    async def get_contract_status(self, contract_id: str) -> Dict:
        """
        Get contract status
        
        Args:
            contract_id: Contract identifier
            
        Returns:
            Status dict
        """
        result = await self.call_function('getContractStatus', contract_id)
        
        return {
            'currentScore': result[0],
            'requiredScore': result[1],
            'finalized': result[2],
            'signatureCount': result[3],
        }
    
    async def has_user_signed(self, contract_id: str, signer_address: str) -> bool:
        """
        Check if user has signed a contract
        
        Args:
            contract_id: Contract identifier
            signer_address: Signer wallet address
            
        Returns:
            True if signed
        """
        return await self.call_function('hasUserSigned', contract_id, signer_address)


def load_contract_abi(contract_name: str) -> List[Dict]:
    """
    Load contract ABI from artifacts
    
    Args:
        contract_name: Contract name (e.g., 'HierarchyManager')
        
    Returns:
        Contract ABI
    """
    # Path to Hardhat artifacts
    artifacts_path = Path(__file__).parent.parent.parent.parent.parent / 'contracts' / 'artifacts' / 'contracts'
    abi_file = artifacts_path / f'{contract_name}.sol' / f'{contract_name}.json'
    
    if not abi_file.exists():
        raise FileNotFoundError(f"ABI file not found: {abi_file}")
    
    with open(abi_file, 'r') as f:
        artifact = json.load(f)
    
    return artifact['abi']


def get_hierarchy_manager(contract_address: str) -> HierarchyManagerContract:
    """
    Get HierarchyManager contract instance
    
    Args:
        contract_address: Deployed contract address
        
    Returns:
        HierarchyManagerContract instance
    """
    abi = load_contract_abi('HierarchyManager')
    return HierarchyManagerContract(contract_address, abi)


def get_signature_authority(contract_address: str) -> SignatureAuthorityContract:
    """
    Get SignatureAuthority contract instance
    
    Args:
        contract_address: Deployed contract address
        
    Returns:
        SignatureAuthorityContract instance
    """
    abi = load_contract_abi('SignatureAuthority')
    return SignatureAuthorityContract(contract_address, abi)
