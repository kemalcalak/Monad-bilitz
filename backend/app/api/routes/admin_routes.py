"""
Admin Routes

Admin-only endpoints for system management
"""

from typing import List, Optional
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.api.routes.auth_routes import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.models.contract import Contract


router = APIRouter(prefix="/admin", tags=["Admin"])


# Schemas
class SystemStats(BaseModel):
    total_users: int
    total_contracts: int
    pending_contracts: int
    completed_contracts: int
    total_signatures: int


class BlockchainEvent(BaseModel):
    event_type: str
    contract_id: Optional[str]
    timestamp: datetime
    block_number: int
    transaction_hash: str
    data: dict


# Helper function
async def verify_admin(current_user: User = Depends(get_current_user)):
    """Verify user is admin"""
    # TODO: Implement proper admin check
    # For now, check if user has CEO group
    if not current_user.group or current_user.group.group_name != "CEO":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin access required"
        )
    return current_user


# Routes
@router.get("/stats", response_model=SystemStats)
async def get_system_stats(
    admin_user: User = Depends(verify_admin),
    db: AsyncSession = Depends(get_db)
):
    """
    Get system statistics (admin only)
    """
    # Count users
    result = await db.execute(select(User))
    total_users = len(result.scalars().all())
    
    # Count contracts
    result = await db.execute(select(Contract))
    contracts = result.scalars().all()
    total_contracts = len(contracts)
    
    pending_contracts = len([c for c in contracts if c.status == "pending"])
    completed_contracts = len([c for c in contracts if c.status == "completed"])
    
    # Count signatures
    total_signatures = sum(len(c.signatures) for c in contracts)
    
    return SystemStats(
        total_users=total_users,
        total_contracts=total_contracts,
        pending_contracts=pending_contracts,
        completed_contracts=completed_contracts,
        total_signatures=total_signatures
    )


@router.get("/contracts", response_model=List[dict])
async def get_all_contracts(
    status_filter: Optional[str] = None,
    admin_user: User = Depends(verify_admin),
    db: AsyncSession = Depends(get_db)
):
    """
    Get all contracts (admin only)
    
    - **status_filter**: Filter by status
    """
    query = select(Contract)
    
    if status_filter:
        query = query.where(Contract.status == status_filter)
    
    result = await db.execute(query.order_by(Contract.created_at.desc()))
    contracts = result.scalars().all()
    
    return [
        {
            "id": str(c.id),
            "contract_id": c.contract_id,
            "title": c.title,
            "contract_type": c.contract_type,
            "amount": c.amount,
            "required_score": c.required_score,
            "current_score": c.current_score,
            "status": c.status,
            "creator_id": str(c.creator_id),
            "created_at": c.created_at.isoformat(),
            "signature_count": len(c.signatures)
        }
        for c in contracts
    ]


@router.get("/blockchain/events", response_model=List[BlockchainEvent])
async def get_blockchain_events(
    limit: int = 50,
    admin_user: User = Depends(verify_admin),
    db: AsyncSession = Depends(get_db)
):
    """
    Get recent blockchain events (admin only)
    
    - **limit**: Maximum number of events to return
    
    TODO: Implement actual blockchain event fetching
    """
    # This would fetch events from the blockchain event listener
    # For now, return empty list
    return []


@router.get("/users", response_model=List[dict])
async def get_all_users(
    admin_user: User = Depends(verify_admin),
    db: AsyncSession = Depends(get_db)
):
    """
    Get all users (admin only)
    """
    result = await db.execute(select(User))
    users = result.scalars().all()
    
    return [
        {
            "id": str(u.id),
            "username": u.username,
            "email": u.email,
            "wallet_address": u.wallet_address,
            "group_name": u.group.group_name if u.group else None,
            "created_at": u.created_at.isoformat()
        }
        for u in users
    ]


@router.post("/contracts/{contract_id}/force-complete")
async def force_complete_contract(
    contract_id: str,
    admin_user: User = Depends(verify_admin),
    db: AsyncSession = Depends(get_db)
):
    """
    Force complete a contract (admin emergency action)
    """
    result = await db.execute(
        select(Contract).where(Contract.contract_id == contract_id)
    )
    contract = result.scalar_one_or_none()
    
    if not contract:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Contract not found"
        )
    
    contract.status = "completed"
    await db.commit()
    
    return {
        "message": "Contract force-completed",
        "contract_id": contract_id
    }
