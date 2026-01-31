"""
Socket.IO Server

Handles real-time communication with clients
"""

import socketio
from typing import Dict, Set
from jose import jwt, JWTError

from app.config import settings


# Socket.IO server instance (imported from main.py)
sio = socketio.AsyncServer(
    async_mode="asgi",
    cors_allowed_origins=settings.SOCKETIO_CORS_ORIGINS,
    logger=True,
    engineio_logger=True,
)

# Track connected users
connected_users: Dict[str, Set[str]] = {}  # user_id -> set of session_ids


async def authenticate_socket(auth_data: dict) -> str:
    """
    Authenticate Socket.IO connection using JWT token
    
    Args:
        auth_data: Authentication data from client
        
    Returns:
        User ID if authenticated
        
    Raises:
        ValueError if authentication fails
    """
    if not auth_data or 'token' not in auth_data:
        raise ValueError("No token provided")
    
    token = auth_data['token']
    
    try:
        payload = jwt.decode(token, settings.JWT_SECRET_KEY, algorithms=[settings.JWT_ALGORITHM])
        user_id: str = payload.get("sub")
        
        if user_id is None:
            raise ValueError("Invalid token payload")
        
        return user_id
    except JWTError:
        raise ValueError("Invalid token")


@sio.on("connect")
async def handle_connect(sid: str, environ: dict, auth: dict):
    """
    Handle Socket.IO connection
    
    Authenticates user and joins them to their user-specific room
    """
    try:
        # Authenticate user
        user_id = await authenticate_socket(auth)
        
        # Track connection
        if user_id not in connected_users:
            connected_users[user_id] = set()
        connected_users[user_id].add(sid)
        
        # Join user-specific room
        await sio.enter_room(sid, f"user_{user_id}")
        
        print(f"🔗 User {user_id} connected (session: {sid})")
        
        # Send welcome message
        await sio.emit('connected', {
            'message': 'Connected to Signature Move Authority System',
            'user_id': user_id
        }, room=sid)
        
        return True
        
    except ValueError as e:
        print(f"❌ Connection rejected: {e}")
        return False


@sio.on("disconnect")
async def handle_disconnect(sid: str):
    """Handle Socket.IO disconnection"""
    # Find and remove user
    for user_id, sessions in connected_users.items():
        if sid in sessions:
            sessions.remove(sid)
            if not sessions:
                del connected_users[user_id]
            print(f"🔌 User {user_id} disconnected (session: {sid})")
            break


@sio.on("subscribe_contract")
async def handle_subscribe_contract(sid: str, data: dict):
    """
    Subscribe to contract-specific updates
    
    Args:
        sid: Session ID
        data: {'contract_id': 'CONTRACT_XXX'}
    """
    contract_id = data.get('contract_id')
    
    if not contract_id:
        await sio.emit('error', {'message': 'contract_id required'}, room=sid)
        return
    
    await sio.enter_room(sid, f"contract_{contract_id}")
    print(f"📝 Session {sid} subscribed to contract {contract_id}")
    
    await sio.emit('subscribed', {
        'contract_id': contract_id,
        'message': f'Subscribed to contract {contract_id}'
    }, room=sid)


@sio.on("unsubscribe_contract")
async def handle_unsubscribe_contract(sid: str, data: dict):
    """Unsubscribe from contract updates"""
    contract_id = data.get('contract_id')
    
    if not contract_id:
        return
    
    await sio.leave_room(sid, f"contract_{contract_id}")
    print(f"📝 Session {sid} unsubscribed from contract {contract_id}")


# Event broadcasting functions
async def broadcast_contract_created(contract_id: str, contract_data: dict, suggested_authorities: list):
    """
    Broadcast contract created event
    
    Args:
        contract_id: Contract ID
        contract_data: Contract details
        suggested_authorities: List of suggested authority user IDs
    """
    # Notify suggested authorities
    for user_id in suggested_authorities:
        await sio.emit('contract_created', {
            'contract_id': contract_id,
            'title': contract_data.get('title'),
            'type': contract_data.get('contract_type'),
            'amount': contract_data.get('amount'),
            'required_score': contract_data.get('required_score'),
            'urgency': contract_data.get('urgency', 'normal'),
            'timestamp': contract_data.get('created_at')
        }, room=f"user_{user_id}")
    
    print(f"📢 Broadcasted contract_created: {contract_id}")


async def broadcast_signature_added(contract_id: str, signer_username: str, current_score: int, required_score: int):
    """
    Broadcast signature added event
    
    Args:
        contract_id: Contract ID
        signer_username: Username of signer
        current_score: Current total score
        required_score: Required score
    """
    await sio.emit('signature_added', {
        'contract_id': contract_id,
        'signer_username': signer_username,
        'current_score': current_score,
        'required_score': required_score,
        'progress_percentage': int((current_score / required_score) * 100) if required_score > 0 else 0
    }, room=f"contract_{contract_id}")
    
    print(f"📢 Broadcasted signature_added: {contract_id} by {signer_username}")


async def broadcast_contract_finalized(contract_id: str, final_score: int):
    """
    Broadcast contract finalized event
    
    Args:
        contract_id: Contract ID
        final_score: Final total score
    """
    await sio.emit('contract_finalized', {
        'contract_id': contract_id,
        'final_score': final_score,
        'status': 'completed'
    }, room=f"contract_{contract_id}")
    
    print(f"📢 Broadcasted contract_finalized: {contract_id}")


async def notify_user(user_id: str, notification_type: str, data: dict):
    """
    Send notification to a specific user
    
    Args:
        user_id: User ID
        notification_type: Type of notification
        data: Notification data
    """
    await sio.emit('notification', {
        'type': notification_type,
        'data': data
    }, room=f"user_{user_id}")


# Export sio instance and broadcast functions
__all__ = [
    'sio',
    'broadcast_contract_created',
    'broadcast_signature_added',
    'broadcast_contract_finalized',
    'notify_user',
]
