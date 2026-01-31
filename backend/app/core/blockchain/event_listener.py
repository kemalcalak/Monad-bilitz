"""
Blockchain Event Listener

Listens to blockchain events in real-time using WebSocket connection
"""

import asyncio
import json
from typing import Dict, Callable, Optional, List
from web3 import Web3
from web3.contract import Contract

from app.config import settings
from app.core.blockchain.contract_manager import load_contract_abi


class BlockchainEventListener:
    """
    Real-time blockchain event listener using WebSocket
    
    Listens to:
    - ContractCreated
    - SignatureAdded
    - ContractFinalized
    - GroupCreated
    - UserAssigned
    """
    
    def __init__(
        self,
        wss_url: Optional[str] = None,
        hierarchy_manager_address: Optional[str] = None,
        signature_authority_address: Optional[str] = None
    ):
        """
        Initialize event listener
        
        Args:
            wss_url: WebSocket URL (defaults to settings)
            hierarchy_manager_address: HierarchyManager contract address
            signature_authority_address: SignatureAuthority contract address
        """
        self.wss_url = wss_url or settings.MONAD_WSS_URL
        self.hierarchy_manager_address = hierarchy_manager_address
        self.signature_authority_address = signature_authority_address
        
        # Event handlers
        self.event_handlers: Dict[str, List[Callable]] = {}
        
        # WebSocket connection
        self.w3: Optional[Web3] = None
        self.hierarchy_contract: Optional[Contract] = None
        self.signature_contract: Optional[Contract] = None
        
        # Running flag
        self.is_running = False
    
    def connect(self):
        """Connect to WebSocket"""
        try:
            self.w3 = Web3(Web3.WebsocketProvider(self.wss_url))
            
            if not self.w3.is_connected():
                raise ConnectionError(f"Failed to connect to WebSocket: {self.wss_url}")
            
            # Load contracts
            if self.hierarchy_manager_address:
                abi = load_contract_abi('HierarchyManager')
                self.hierarchy_contract = self.w3.eth.contract(
                    address=Web3.to_checksum_address(self.hierarchy_manager_address),
                    abi=abi
                )
            
            if self.signature_authority_address:
                abi = load_contract_abi('SignatureAuthority')
                self.signature_contract = self.w3.eth.contract(
                    address=Web3.to_checksum_address(self.signature_authority_address),
                    abi=abi
                )
            
            print(f"✅ Connected to Monad WebSocket: {self.wss_url}")
            
        except Exception as e:
            print(f"❌ Failed to connect to WebSocket: {e}")
            raise
    
    def register_handler(self, event_name: str, handler: Callable):
        """
        Register an event handler
        
        Args:
            event_name: Event name (e.g., 'ContractCreated')
            handler: Async function to handle event
        """
        if event_name not in self.event_handlers:
            self.event_handlers[event_name] = []
        
        self.event_handlers[event_name].append(handler)
        print(f"📝 Registered handler for event: {event_name}")
    
    async def handle_event(self, event_name: str, event_data: Dict):
        """
        Handle an event by calling all registered handlers
        
        Args:
            event_name: Event name
            event_data: Event data
        """
        if event_name in self.event_handlers:
            for handler in self.event_handlers[event_name]:
                try:
                    await handler(event_data)
                except Exception as e:
                    print(f"❌ Error in event handler for {event_name}: {e}")
    
    async def listen_to_signature_authority_events(self):
        """Listen to SignatureAuthority contract events"""
        if not self.signature_contract:
            return
        
        print("👂 Listening to SignatureAuthority events...")
        
        # Create event filters
        contract_created_filter = self.signature_contract.events.ContractCreated.create_filter(
            fromBlock='latest'
        )
        signature_added_filter = self.signature_contract.events.SignatureAdded.create_filter(
            fromBlock='latest'
        )
        contract_finalized_filter = self.signature_contract.events.ContractFinalized.create_filter(
            fromBlock='latest'
        )
        
        while self.is_running:
            try:
                # Check ContractCreated events
                for event in contract_created_filter.get_new_entries():
                    event_data = {
                        'event': 'ContractCreated',
                        'contractId': event['args']['contractId'],
                        'creator': event['args']['creator'],
                        'requiredScore': event['args']['requiredScore'],
                        'timestamp': event['args']['timestamp'],
                        'blockNumber': event['blockNumber'],
                        'transactionHash': event['transactionHash'].hex(),
                    }
                    print(f"📄 ContractCreated: {event_data['contractId']}")
                    await self.handle_event('ContractCreated', event_data)
                
                # Check SignatureAdded events
                for event in signature_added_filter.get_new_entries():
                    event_data = {
                        'event': 'SignatureAdded',
                        'contractId': event['args']['contractId'],
                        'signer': event['args']['signer'],
                        'score': event['args']['score'],
                        'currentScore': event['args']['currentScore'],
                        'timestamp': event['args']['timestamp'],
                        'blockNumber': event['blockNumber'],
                        'transactionHash': event['transactionHash'].hex(),
                    }
                    print(f"✍️  SignatureAdded: {event_data['contractId']} by {event_data['signer']}")
                    await self.handle_event('SignatureAdded', event_data)
                
                # Check ContractFinalized events
                for event in contract_finalized_filter.get_new_entries():
                    event_data = {
                        'event': 'ContractFinalized',
                        'contractId': event['args']['contractId'],
                        'finalScore': event['args']['finalScore'],
                        'timestamp': event['args']['timestamp'],
                        'blockNumber': event['blockNumber'],
                        'transactionHash': event['transactionHash'].hex(),
                    }
                    print(f"✅ ContractFinalized: {event_data['contractId']}")
                    await self.handle_event('ContractFinalized', event_data)
                
            except Exception as e:
                print(f"❌ Error listening to events: {e}")
            
            # Wait before next poll
            await asyncio.sleep(2)
    
    async def listen_to_hierarchy_manager_events(self):
        """Listen to HierarchyManager contract events"""
        if not self.hierarchy_contract:
            return
        
        print("👂 Listening to HierarchyManager events...")
        
        # Create event filters
        group_created_filter = self.hierarchy_contract.events.GroupCreated.create_filter(
            fromBlock='latest'
        )
        user_assigned_filter = self.hierarchy_contract.events.UserAssigned.create_filter(
            fromBlock='latest'
        )
        
        while self.is_running:
            try:
                # Check GroupCreated events
                for event in group_created_filter.get_new_entries():
                    event_data = {
                        'event': 'GroupCreated',
                        'groupId': event['args']['groupId'],
                        'name': event['args']['name'],
                        'level': event['args']['level'],
                        'authorityScore': event['args']['authorityScore'],
                        'timestamp': event['args']['timestamp'],
                        'blockNumber': event['blockNumber'],
                        'transactionHash': event['transactionHash'].hex(),
                    }
                    print(f"🏢 GroupCreated: {event_data['groupId']}")
                    await self.handle_event('GroupCreated', event_data)
                
                # Check UserAssigned events
                for event in user_assigned_filter.get_new_entries():
                    event_data = {
                        'event': 'UserAssigned',
                        'user': event['args']['user'],
                        'groupId': event['args']['groupId'],
                        'timestamp': event['args']['timestamp'],
                        'blockNumber': event['blockNumber'],
                        'transactionHash': event['transactionHash'].hex(),
                    }
                    print(f"👤 UserAssigned: {event_data['user']} to {event_data['groupId']}")
                    await self.handle_event('UserAssigned', event_data)
                
            except Exception as e:
                print(f"❌ Error listening to events: {e}")
            
            # Wait before next poll
            await asyncio.sleep(2)
    
    async def start(self):
        """Start listening to events"""
        if self.is_running:
            print("⚠️  Event listener is already running")
            return
        
        # Connect to WebSocket
        self.connect()
        
        self.is_running = True
        print("🚀 Event listener started")
        
        # Start listening tasks
        tasks = []
        
        if self.signature_contract:
            tasks.append(asyncio.create_task(self.listen_to_signature_authority_events()))
        
        if self.hierarchy_contract:
            tasks.append(asyncio.create_task(self.listen_to_hierarchy_manager_events()))
        
        if not tasks:
            print("⚠️  No contracts configured. Event listener has nothing to listen to.")
            return
        
        # Wait for all tasks
        await asyncio.gather(*tasks)
    
    async def stop(self):
        """Stop listening to events"""
        self.is_running = False
        print("🛑 Event listener stopped")


# Global event listener instance
_event_listener: Optional[BlockchainEventListener] = None


def get_event_listener(
    hierarchy_manager_address: Optional[str] = None,
    signature_authority_address: Optional[str] = None
) -> BlockchainEventListener:
    """
    Get global event listener instance
    
    Args:
        hierarchy_manager_address: HierarchyManager contract address
        signature_authority_address: SignatureAuthority contract address
        
    Returns:
        BlockchainEventListener instance
    """
    global _event_listener
    
    if _event_listener is None:
        _event_listener = BlockchainEventListener(
            hierarchy_manager_address=hierarchy_manager_address,
            signature_authority_address=signature_authority_address
        )
    
    return _event_listener


async def example_event_handlers():
    """Example event handlers"""
    
    async def on_contract_created(event_data: Dict):
        """Handle ContractCreated event"""
        print(f"🔔 New contract created: {event_data['contractId']}")
        # TODO: Update database, send notifications via Socket.IO
    
    async def on_signature_added(event_data: Dict):
        """Handle SignatureAdded event"""
        print(f"🔔 Signature added to {event_data['contractId']}")
        # TODO: Update database, notify users
    
    async def on_contract_finalized(event_data: Dict):
        """Handle ContractFinalized event"""
        print(f"🔔 Contract finalized: {event_data['contractId']}")
        # TODO: Update database, send completion notifications
    
    # Register handlers
    listener = get_event_listener()
    listener.register_handler('ContractCreated', on_contract_created)
    listener.register_handler('SignatureAdded', on_signature_added)
    listener.register_handler('ContractFinalized', on_contract_finalized)


if __name__ == "__main__":
    # Test event listener
    async def main():
        listener = get_event_listener(
            signature_authority_address="0x...",  # Replace with actual address
        )
        
        await example_event_handlers()
        await listener.start()
    
    asyncio.run(main())
