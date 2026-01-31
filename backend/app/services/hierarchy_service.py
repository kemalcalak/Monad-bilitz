"""
Hierarchy Service

Manages hierarchical groups, access graph, and authority scores
"""

import uuid
from typing import List, Dict, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from app.models.hierarchy import Group, GroupEdge, OrganizationUnit
from app.models.user import User


class HierarchyService:
    """
    Service for managing hierarchical structure and authority scores
    """
    
    def __init__(self, db: AsyncSession):
        """
        Initialize hierarchy service
        
        Args:
            db: Database session
        """
        self.db = db
        self.graph_cache: Dict[str, List[str]] = {}
    
    async def get_all_groups(self, ou_id: Optional[uuid.UUID] = None) -> List[Group]:
        """
        Get all groups, optionally filtered by organization unit
        
        Args:
            ou_id: Organization unit ID (optional)
            
        Returns:
            List of groups
        """
        query = select(Group)
        
        if ou_id:
            query = query.join(OrganizationUnit).where(OrganizationUnit.id == ou_id)
        
        result = await self.db.execute(query)
        return list(result.scalars().all())
    
    async def get_group_by_name(self, group_name: str) -> Optional[Group]:
        """
        Get group by name
        
        Args:
            group_name: Group name
            
        Returns:
            Group or None
        """
        result = await self.db.execute(
            select(Group).where(Group.group_name == group_name)
        )
        return result.scalar_one_or_none()
    
    async def get_ancestors(self, group_id: uuid.UUID) -> List[Group]:
        """
        Get all ancestor groups (higher authority)
        
        Uses access graph to find all groups that can access this group
        
        Args:
            group_id: Group ID
            
        Returns:
            List of ancestor groups
        """
        # Get edges where this group is the target
        result = await self.db.execute(
            select(GroupEdge)
            .where(GroupEdge.to_group_id == group_id)
            .options(selectinload(GroupEdge.from_group))
        )
        edges = result.scalars().all()
        
        ancestors = []
        for edge in edges:
            if not edge.is_self_loop:
                ancestors.append(edge.from_group)
        
        return ancestors
    
    async def get_descendants(self, group_id: uuid.UUID) -> List[Group]:
        """
        Get all descendant groups (lower authority)
        
        Uses access graph to find all groups this group can access
        
        Args:
            group_id: Group ID
            
        Returns:
            List of descendant groups
        """
        # Get edges where this group is the source
        result = await self.db.execute(
            select(GroupEdge)
            .where(GroupEdge.from_group_id == group_id)
            .options(selectinload(GroupEdge.to_group))
        )
        edges = result.scalars().all()
        
        descendants = []
        for edge in edges:
            if not edge.is_self_loop:
                descendants.append(edge.to_group)
        
        return descendants
    
    async def validate_access(self, from_group_id: uuid.UUID, to_group_id: uuid.UUID) -> bool:
        """
        Check if from_group has access to to_group in hierarchy
        
        from_group >= to_group (from_group has equal or higher authority)
        
        Args:
            from_group_id: Source group ID
            to_group_id: Target group ID
            
        Returns:
            True if access is allowed
        """
        # Same group always has access
        if from_group_id == to_group_id:
            return True
        
        # Check if there's an edge from from_group to to_group
        result = await self.db.execute(
            select(GroupEdge).where(
                GroupEdge.from_group_id == from_group_id,
                GroupEdge.to_group_id == to_group_id
            )
        )
        edge = result.scalar_one_or_none()
        
        return edge is not None
    
    async def get_user_authority_score(self, user_id: uuid.UUID) -> int:
        """
        Get user's authority score based on their group
        
        Args:
            user_id: User ID
            
        Returns:
            Authority score (0 if user has no group)
        """
        result = await self.db.execute(
            select(User)
            .where(User.id == user_id)
            .options(selectinload(User.group))
        )
        user = result.scalar_one_or_none()
        
        if not user or not user.group:
            return 0
        
        # Get authority score from group
        # Note: This requires adding authority_score field to Group model
        return getattr(user.group, 'authority_score', 0)
    
    def calculate_required_score(self, contract_type: str, amount: Optional[float] = None) -> int:
        """
        Calculate required authority score for a contract
        
        Rules:
        - Amount < $10K: score 50
        - Amount $10K-$50K: score 100
        - Amount > $50K: score 150
        - Legal contracts: always 150
        
        Args:
            contract_type: Type of contract
            amount: Contract amount (optional)
            
        Returns:
            Required authority score
        """
        # Special rules for contract types
        if contract_type == "legal":
            return 150
        
        # Amount-based rules
        if amount is None:
            return 50  # Default for contracts without amount
        
        if amount < 10000:
            return 50
        elif amount < 50000:
            return 100
        else:
            return 150
    
    async def get_hierarchy_graph(self, ou_id: Optional[uuid.UUID] = None) -> Dict:
        """
        Get hierarchy graph for visualization
        
        Returns nodes (groups) and edges for frontend visualization
        
        Args:
            ou_id: Organization unit ID (optional)
            
        Returns:
            Dictionary with 'nodes' and 'edges'
        """
        # Get all groups
        groups = await self.get_all_groups(ou_id)
        
        # Get all edges
        query = select(GroupEdge)
        if ou_id:
            query = query.where(GroupEdge.ou_id == ou_id)
        
        result = await self.db.execute(query)
        edges = result.scalars().all()
        
        # Format for frontend
        nodes = [
            {
                'id': str(group.id),
                'group_name': group.group_name,
                'display_name': group.display_name,
                'level': group.level,
                'authority_score': getattr(group, 'authority_score', 0),
                'user_count': group.user_count,
            }
            for group in groups
        ]
        
        edges_data = [
            {
                'from': str(edge.from_group_id),
                'to': str(edge.to_group_id),
                'is_self_loop': edge.is_self_loop,
            }
            for edge in edges
        ]
        
        return {
            'nodes': nodes,
            'edges': edges_data,
        }
    
    async def create_group(
        self,
        group_name: str,
        display_name: str,
        level: int,
        authority_score: int,
        ou_id: uuid.UUID
    ) -> Group:
        """
        Create a new group
        
        Args:
            group_name: Unique group identifier
            display_name: Human-readable name
            level: Hierarchy level
            authority_score: Authority score
            ou_id: Organization unit ID
            
        Returns:
            Created group
        """
        # Check if group already exists
        existing = await self.get_group_by_name(group_name)
        if existing:
            raise ValueError(f"Group {group_name} already exists")
        
        # Create group
        group = Group(
            group_name=group_name,
            display_name=display_name,
            level=level,
            user_count=0,
        )
        
        # Note: authority_score field needs to be added to Group model
        if hasattr(group, 'authority_score'):
            group.authority_score = authority_score
        
        self.db.add(group)
        await self.db.commit()
        await self.db.refresh(group)
        
        return group
    
    async def update_group_score(
        self,
        group_id: uuid.UUID,
        new_score: int
    ) -> Group:
        """
        Update group's authority score
        
        Args:
            group_id: Group ID
            new_score: New authority score
            
        Returns:
            Updated group
        """
        result = await self.db.execute(
            select(Group).where(Group.id == group_id)
        )
        group = result.scalar_one_or_none()
        
        if not group:
            raise ValueError(f"Group {group_id} not found")
        
        # Update score
        if hasattr(group, 'authority_score'):
            group.authority_score = new_score
        
        await self.db.commit()
        await self.db.refresh(group)
        
        return group
