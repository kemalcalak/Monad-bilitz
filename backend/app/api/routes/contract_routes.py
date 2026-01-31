"""
Contract Management Routes

Handles contract creation, listing, signing, and status tracking
"""

import uuid
from datetime import datetime
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_
from sqlalchemy.orm import selectinload

from app.api.routes.auth_routes import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.models.contract import Contract
from app.models.signature import Signature
from app.services.hierarchy_service import HierarchyService
from app.core.agents import get_smart_router_agent, get_compliance_agent
from app.core.blockchain import get_signature_authority


router = APIRouter(prefix="/contracts", tags=["Contracts"])


# Schemas
class ContractCreate(BaseModel):
    title: str
    content: str
    contract_type: str
    amount: Optional[float] = None
    urgency: str = "normal"


class ContractResponse(BaseModel):
    id: str
    contract_id: str
    title: str
    content: str
    contract_type: str
    amount: Optional[float]
    required_score: int
    current_score: int
    status: str
    creator_id: str
    creator_username: str
    blockchain_tx_hash: Optional[str]
    created_at: datetime
    signatures: List[dict]


class SignatureCreate(BaseModel):
    contract_id: str


class SignatureResponse(BaseModel):
    id: str
    contract_id: str
    signer_id: str
    signer_username: str
    authority_score: int
    blockchain_tx_hash: Optional[str]
    signed_at: datetime


# Routes
@router.post("/", response_model=ContractResponse, status_code=status.HTTP_201_CREATED)
async def create_contract(
    contract_data: ContractCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Create a new contract
    
    Steps:
    1. Analyze contract with Smart Router Agent
    2. Validate with Compliance Agent
    3. Calculate required score
    4. Create contract in database
    5. Submit to blockchain
    6. Notify suggested authorities via Socket.IO
    """
    # Step 1: Analyze with Contract Team (Agentic Workflow)
    from app.core.agents.contract_team import get_contract_team
    
    team = get_contract_team()
    analysis = await team.analyze_contract(
        title=contract_data.title,
        content=contract_data.content,
        contract_type=contract_data.contract_type,
        amount=contract_data.amount,
        urgency=contract_data.urgency
    )
    
    # Check compliance based on team verdict
    if analysis.final_verdict == "REJECTED" or not analysis.is_compliant:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={
                "message": "Contract rejected by AI Compliance Team",
                "risk_assessment": analysis.risk_assessment,
                "summary": analysis.summary
            }
        )
        
    suggested_authorities = analysis.suggested_route
    
    # Step 3: Calculate required score
    hierarchy_service = HierarchyService(db)
    required_score = hierarchy_service.calculate_required_score(
        contract_data.contract_type,
        contract_data.amount
    )
    
    # Step 4: Create contract in database
    contract_id = f"CONTRACT_{uuid.uuid4().hex[:8].upper()}"
    
    contract = Contract(
        contract_id=contract_id,
        title=contract_data.title,
        content=contract_data.content,
        contract_type=contract_data.contract_type,
        amount=contract_data.amount,
        required_score=required_score,
        current_score=0,
        status="pending",
        creator_id=current_user.id,
    )
    
    db.add(contract)
    await db.commit()
    await db.refresh(contract)
    
    # Step 5: Submit to blockchain
    try:
        # Get contract manager (you'll need to set contract address in env)
        # signature_authority = get_signature_authority(settings.SIGNATURE_AUTHORITY_ADDRESS)
        # tx_hash = await signature_authority.create_contract(contract_id, required_score)
        # contract.blockchain_tx_hash = tx_hash
        # await db.commit()
        pass  # TODO: Add contract address to settings
    except Exception as e:
        print(f"Blockchain submission failed: {e}")
        # Continue even if blockchain fails (can retry later)
    
    # Step 6: TODO: Notify via Socket.IO
    # await sio.emit('contract_created', {
    #     'contract_id': contract_id,
    #     'suggested_authorities': routing.suggested_authorities
    # })
    
    return ContractResponse(
        id=str(contract.id),
        contract_id=contract.contract_id,
        title=contract.title,
        content=contract.content,
        contract_type=contract.contract_type,
        amount=contract.amount,
        required_score=contract.required_score,
        current_score=contract.current_score,
        status=contract.status,
        creator_id=str(contract.creator_id),
        creator_username=current_user.username,
        blockchain_tx_hash=contract.blockchain_tx_hash,
        created_at=contract.created_at,
        signatures=[]
    )


@router.get("/", response_model=List[ContractResponse])
async def list_contracts(
    status_filter: Optional[str] = None,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    List contracts
    
    - **status_filter**: Filter by status (pending, signed, completed, rejected)
    """
    query = select(Contract).options(
        selectinload(Contract.creator),
        selectinload(Contract.signatures)
    )
    
    if status_filter:
        query = query.where(Contract.status == status_filter)
    
    # TODO: Filter by user's authority (only show contracts they can sign)
    
    result = await db.execute(query.order_by(Contract.created_at.desc()))
    contracts = result.scalars().all()
    
    return [
        ContractResponse(
            id=str(c.id),
            contract_id=c.contract_id,
            title=c.title,
            content=c.content,
            contract_type=c.contract_type,
            amount=c.amount,
            required_score=c.required_score,
            current_score=c.current_score,
            status=c.status,
            creator_id=str(c.creator_id),
            creator_username=c.creator.username,
            blockchain_tx_hash=c.blockchain_tx_hash,
            created_at=c.created_at,
            signatures=[
                {
                    'signer_username': sig.signer.username,
                    'authority_score': sig.authority_score,
                    'signed_at': sig.signed_at.isoformat()
                }
                for sig in c.signatures
            ]
        )
        for c in contracts
    ]


@router.get("/{contract_id}", response_model=ContractResponse)
async def get_contract(
    contract_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get contract details"""
    result = await db.execute(
        select(Contract)
        .where(Contract.contract_id == contract_id)
        .options(
            selectinload(Contract.creator),
            selectinload(Contract.signatures).selectinload(Signature.signer)
        )
    )
    contract = result.scalar_one_or_none()
    
    if not contract:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Contract not found"
        )
    
    return ContractResponse(
        id=str(contract.id),
        contract_id=contract.contract_id,
        title=contract.title,
        content=contract.content,
        contract_type=contract.contract_type,
        amount=contract.amount,
        required_score=contract.required_score,
        current_score=contract.current_score,
        status=contract.status,
        creator_id=str(contract.creator_id),
        creator_username=contract.creator.username,
        blockchain_tx_hash=contract.blockchain_tx_hash,
        created_at=contract.created_at,
        signatures=[
            {
                'signer_username': sig.signer.username,
                'authority_score': sig.authority_score,
                'signed_at': sig.signed_at.isoformat()
            }
            for sig in contract.signatures
        ]
    )


@router.post("/{contract_id}/sign", response_model=SignatureResponse)
async def sign_contract(
    contract_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Sign a contract
    
    Steps:
    1. Verify user has authority
    2. Check if already signed
    3. Get user's authority score
    4. Create signature in database
    5. Submit to blockchain
    6. Update contract score
    7. Check if contract is complete
    """
    # Get contract
    result = await db.execute(
        select(Contract).where(Contract.contract_id == contract_id)
    )
    contract = result.scalar_one_or_none()
    
    if not contract:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Contract not found"
        )
    
    if contract.status != "pending":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Contract is {contract.status}, cannot sign"
        )
    
    # Check if already signed
    result = await db.execute(
        select(Signature).where(
            and_(
                Signature.contract_id == contract.id,
                Signature.signer_id == current_user.id
            )
        )
    )
    if result.scalar_one_or_none():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="You have already signed this contract"
        )
    
    # Get user's authority score
    hierarchy_service = HierarchyService(db)
    authority_score = await hierarchy_service.get_user_authority_score(current_user.id)
    
    if authority_score == 0:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You do not have authority to sign contracts"
        )
    
    # Generate signature hash (simulating cryptographic signature)
    import hashlib
    sig_data = f"{contract.contract_id}:{current_user.id}:{datetime.utcnow().isoformat()}"
    signature_hash = hashlib.sha256(sig_data.encode()).hexdigest()
    
    # Create signature
    signature = Signature(
        contract_id=contract.id,
        signer_id=current_user.id,
        authority_score=authority_score,
        signature_hash=f"0x{signature_hash}", # Ethereum style prefix
        signed_at=datetime.utcnow()
    )
    
    db.add(signature)
    
    # Update contract score
    contract.current_score += authority_score
    
    # Check if complete
    if contract.current_score >= contract.required_score:
        contract.status = "completed"
    
    await db.commit()
    await db.refresh(signature)
    
    # TODO: Submit to blockchain
    # TODO: Emit Socket.IO event
    
    return SignatureResponse(
        id=str(signature.id),
        contract_id=contract_id,
        signer_id=str(current_user.id),
        signer_username=current_user.username,
        authority_score=authority_score,
        blockchain_tx_hash=signature.blockchain_tx_hash,
        signed_at=signature.signed_at
    )
