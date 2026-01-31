"""
Hierarchy Routes

Handles hierarchy visualization and admin operations
"""

import uuid
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.routes.auth_routes import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.services.hierarchy_service import HierarchyService


router = APIRouter(prefix="/hierarchy", tags=["Hierarchy"])


# Schemas
class GroupResponse(BaseModel):
    id: str
    group_name: str
    display_name: str
    level: int
    authority_score: int
    user_count: int


class HierarchyGraphResponse(BaseModel):
    nodes: List[dict]
    edges: List[dict]


class GroupCreate(BaseModel):
    group_name: str
    display_name: str
    level: int
    authority_score: int


class GroupUpdate(BaseModel):
    authority_score: int


# Routes
@router.get("/graph", response_model=HierarchyGraphResponse)
async def get_hierarchy_graph(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Get hierarchy graph for visualization
    
    Returns nodes (groups) and edges for frontend visualization
    """
    hierarchy_service = HierarchyService(db)
    graph_data = await hierarchy_service.get_hierarchy_graph()
    
    return HierarchyGraphResponse(
        nodes=graph_data['nodes'],
        edges=graph_data['edges']
    )


@router.get("/groups", response_model=List[GroupResponse])
async def list_groups(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """List all groups"""
    hierarchy_service = HierarchyService(db)
    groups = await hierarchy_service.get_all_groups()
    
    return [
        GroupResponse(
            id=str(group.id),
            group_name=group.group_name,
            display_name=group.display_name,
            level=group.level,
            authority_score=getattr(group, 'authority_score', 0),
            user_count=group.user_count
        )
        for group in groups
    ]


@router.get("/groups/{group_name}", response_model=GroupResponse)
async def get_group(
    group_name: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get group details"""
    hierarchy_service = HierarchyService(db)
    group = await hierarchy_service.get_group_by_name(group_name)
    
    if not group:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Group not found"
        )
    
    return GroupResponse(
        id=str(group.id),
        group_name=group.group_name,
        display_name=group.display_name,
        level=group.level,
        authority_score=getattr(group, 'authority_score', 0),
        user_count=group.user_count
    )


@router.post("/groups", response_model=GroupResponse, status_code=status.HTTP_201_CREATED)
async def create_group(
    group_data: GroupCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Create a new group (admin only)
    
    TODO: Add admin permission check
    """
    hierarchy_service = HierarchyService(db)
    
    # TODO: Check if user is admin
    
    # For now, we need an organization unit ID
    # This should come from the user's context
    # Using a placeholder for demo
    ou_id = uuid.uuid4()  # TODO: Get from user's organization
    
    try:
        group = await hierarchy_service.create_group(
            group_name=group_data.group_name,
            display_name=group_data.display_name,
            level=group_data.level,
            authority_score=group_data.authority_score,
            ou_id=ou_id
        )
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    
    return GroupResponse(
        id=str(group.id),
        group_name=group.group_name,
        display_name=group.display_name,
        level=group.level,
        authority_score=getattr(group, 'authority_score', 0),
        user_count=group.user_count
    )


@router.patch("/groups/{group_id}/score", response_model=GroupResponse)
async def update_group_score(
    group_id: str,
    update_data: GroupUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Update group authority score (admin only)
    
    TODO: Add admin permission check
    """
    hierarchy_service = HierarchyService(db)
    
    # TODO: Check if user is admin
    
    try:
        group = await hierarchy_service.update_group_score(
            group_id=uuid.UUID(group_id),
            new_score=update_data.authority_score
        )
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
    
    return GroupResponse(
        id=str(group.id),
        group_name=group.group_name,
        display_name=group.display_name,
        level=group.level,
        authority_score=getattr(group, 'authority_score', 0),
        user_count=group.user_count
    )


@router.get("/my-authority-score")
async def get_my_authority_score(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get current user's authority score"""
    hierarchy_service = HierarchyService(db)
    score = await hierarchy_service.get_user_authority_score(current_user.id)
    
    return {
        "user_id": str(current_user.id),
        "username": current_user.username,
        "authority_score": score,
        "group_name": current_user.group.group_name if current_user.group else None
    }
