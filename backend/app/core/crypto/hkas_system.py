"""
HKAS System Management

Implements high-level HKAS operations:
- System initialization (Algorithm 1)
- Key generation and distribution
- Dynamic updates (Algorithm 4)
"""

import json
import uuid
from typing import Dict, List, Optional
from datetime import datetime

import numpy as np
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.core.crypto.hkas_math import CVPInnerProductSpace
from app.core.crypto.encryption import encrypt_data, decrypt_data
from app.models.hierarchy import Group, OrganizationUnit
from app.models.user import User


class HKASSystem:
    """
    HKAS System Manager
    
    Implements Algorithm 1: System Preparation and Distribution
    """
    
    def __init__(self, dimension_m: int = 32, basis_length_n: int = 10, s: int = 1):
        """
        Initialize HKAS system
        
        Args:
            dimension_m: Vector space dimension
            basis_length_n: Basis set length
            s: Unique subset length
        """
        self.cvp = CVPInnerProductSpace(dimension_m, basis_length_n, s)
        self.dimension_m = dimension_m
        self.basis_length_n = basis_length_n
        self.s = s
    
    async def initialize_system(self, db: AsyncSession, ou_id: uuid.UUID) -> Dict:
        """
        Initialize HKAS for an organization unit (Algorithm 1)
        
        Steps:
        1. Generate public keys f1, f2
        2. Generate shared set P
        3. For each group, generate unique subset S_i
        4. Combine to form basis B_i for each group
        5. Store encrypted data in database
        
        Args:
            db: Database session
            ou_id: Organization unit ID
            
        Returns:
            Dictionary with system initialization data
        """
        # Step 1: Generate public keys
        f1, f2 = self.cvp.generate_public_keys()
        
        # Step 2: Generate shared set P
        P = self.cvp.generate_shared_set()
        
        # Step 3: Get all groups in this organization unit
        result = await db.execute(
            select(Group).join(OrganizationUnit).where(OrganizationUnit.id == ou_id)
        )
        groups = result.scalars().all()
        
        if not groups:
            raise ValueError(f"No groups found for organization unit {ou_id}")
        
        # Step 4: Generate basis for each group
        group_data = {}
        
        for group in groups:
            # Generate unique subset S_i for this group
            S_i = self.cvp.generate_unique_subset()
            
            # Combine P and S_i to form B_i
            B_i = self.cvp.combine_basis(P, S_i)
            
            # Derive key for this group
            K_i = self.cvp.derive_key(B_i, f1, f2)
            
            group_data[group.group_name] = {
                'B_i': B_i.tolist(),  # Convert to list for JSON serialization
                'S_i': S_i.tolist(),
                'K_i': float(K_i),
                'group_id': str(group.id),
            }
        
        # Step 5: Store system data
        system_data = {
            'f1': f1.tolist(),
            'f2': f2.tolist(),
            'P': P.tolist(),
            'groups': group_data,
            'initialized_at': datetime.utcnow().isoformat(),
            'dimension_m': self.dimension_m,
            'basis_length_n': self.basis_length_n,
            's': self.s,
        }
        
        return system_data
    
    async def generate_user_shares(
        self,
        user_id: uuid.UUID,
        group_id: uuid.UUID,
        system_data: Dict,
        db: AsyncSession
    ) -> Dict:
        """
        Generate and encrypt shares for a user (Algorithm 1 - Distribution)
        
        Args:
            user_id: User ID
            group_id: Group ID
            system_data: System initialization data
            db: Database session
            
        Returns:
            Encrypted user shares
        """
        # Get group information
        result = await db.execute(select(Group).where(Group.id == group_id))
        group = result.scalar_one_or_none()
        
        if not group:
            raise ValueError(f"Group {group_id} not found")
        
        # Get group's basis data
        group_name = group.group_name
        if group_name not in system_data['groups']:
            raise ValueError(f"Group {group_name} not in system data")
        
        group_data = system_data['groups'][group_name]
        
        # User shares include:
        # - B_i (basis set)
        # - K_i (derived key)
        # - Access to ancestor S_j sets (for key derivation)
        user_shares = {
            'user_id': str(user_id),
            'group_id': str(group_id),
            'group_name': group_name,
            'B_i': group_data['B_i'],
            'K_i': group_data['K_i'],
            'assigned_at': datetime.utcnow().isoformat(),
        }
        
        return user_shares
    
    def derive_descendant_key(
        self,
        user_basis: np.ndarray,
        descendant_unique_subset: np.ndarray,
        f1: np.ndarray,
        f2: np.ndarray
    ) -> float:
        """
        Derive key for a descendant class (Algorithm 2)
        
        A user in class C_i can derive the key for descendant class C_j
        if they have access to S_j (unique subset of C_j)
        
        Args:
            user_basis: User's basis B_i
            descendant_unique_subset: Descendant's unique subset S_j
            f1: Public key 1
            f2: Public key 2
            
        Returns:
            Derived key K_j for descendant class
        """
        # Combine user's basis with descendant's unique subset
        # B_j = B_i ∪ S_j (but B_i already contains P, so we just add S_j)
        B_j = np.vstack([user_basis, descendant_unique_subset])
        
        # Derive key for descendant
        K_j = self.cvp.derive_key(B_j, f1, f2)
        
        return K_j


class HKASDynamicUpdates:
    """
    HKAS Dynamic Updates (Algorithm 4)
    
    Handles:
    - Key rollover
    - Class insertion/deletion
    - User insertion/deletion
    """
    
    def __init__(self, hkas_system: HKASSystem):
        """
        Initialize dynamic updates manager
        
        Args:
            hkas_system: HKAS system instance
        """
        self.hkas = hkas_system
        self.cvp = hkas_system.cvp
    
    async def key_rollover(
        self,
        group_id: uuid.UUID,
        system_data: Dict,
        db: AsyncSession
    ) -> Dict:
        """
        Perform key rollover for a group (Algorithm 4 - KeyRollover)
        
        Generate new S_i for the group and update all affected keys
        
        Args:
            group_id: Group to rollover
            system_data: Current system data
            db: Database session
            
        Returns:
            Updated system data
        """
        # Get group
        result = await db.execute(select(Group).where(Group.id == group_id))
        group = result.scalar_one_or_none()
        
        if not group:
            raise ValueError(f"Group {group_id} not found")
        
        group_name = group.group_name
        
        # Generate new unique subset S_i
        new_S_i = self.cvp.generate_unique_subset()
        
        # Reconstruct basis with new S_i
        P = np.array(system_data['P'])
        new_B_i = self.cvp.combine_basis(P, new_S_i)
        
        # Derive new key
        f1 = np.array(system_data['f1'])
        f2 = np.array(system_data['f2'])
        new_K_i = self.cvp.derive_key(new_B_i, f1, f2)
        
        # Update system data
        system_data['groups'][group_name]['S_i'] = new_S_i.tolist()
        system_data['groups'][group_name]['B_i'] = new_B_i.tolist()
        system_data['groups'][group_name]['K_i'] = float(new_K_i)
        system_data['groups'][group_name]['last_rollover'] = datetime.utcnow().isoformat()
        
        return system_data
    
    async def insert_class(
        self,
        new_group: Group,
        system_data: Dict,
        db: AsyncSession
    ) -> Dict:
        """
        Insert a new class into the hierarchy (Algorithm 4 - ClassInsertion)
        
        Args:
            new_group: New group to insert
            system_data: Current system data
            db: Database session
            
        Returns:
            Updated system data
        """
        # Generate unique subset for new class
        S_new = self.cvp.generate_unique_subset()
        
        # Combine with shared set P
        P = np.array(system_data['P'])
        B_new = self.cvp.combine_basis(P, S_new)
        
        # Derive key
        f1 = np.array(system_data['f1'])
        f2 = np.array(system_data['f2'])
        K_new = self.cvp.derive_key(B_new, f1, f2)
        
        # Add to system data
        system_data['groups'][new_group.group_name] = {
            'B_i': B_new.tolist(),
            'S_i': S_new.tolist(),
            'K_i': float(K_new),
            'group_id': str(new_group.id),
            'created_at': datetime.utcnow().isoformat(),
        }
        
        return system_data
    
    async def delete_class(
        self,
        group_name: str,
        system_data: Dict,
        db: AsyncSession
    ) -> Dict:
        """
        Delete a class from the hierarchy (Algorithm 4 - ClassDeletion)
        
        Args:
            group_name: Group name to delete
            system_data: Current system data
            db: Database session
            
        Returns:
            Updated system data
        """
        if group_name not in system_data['groups']:
            raise ValueError(f"Group {group_name} not found in system data")
        
        # Remove group data
        del system_data['groups'][group_name]
        system_data['last_class_deletion'] = datetime.utcnow().isoformat()
        
        return system_data
    
    async def insert_user(
        self,
        user_id: uuid.UUID,
        group_id: uuid.UUID,
        system_data: Dict,
        encryption_key: bytes,
        db: AsyncSession
    ) -> str:
        """
        Insert a user into a class (Algorithm 4 - UserInsertion)
        
        Args:
            user_id: User ID
            group_id: Group ID
            system_data: System data
            encryption_key: Encryption key for storing shares
            db: Database session
            
        Returns:
            Encrypted user shares (as string)
        """
        # Generate user shares
        user_shares = await self.hkas.generate_user_shares(
            user_id, group_id, system_data, db
        )
        
        # Encrypt shares
        encrypted_shares = encrypt_data(user_shares, encryption_key)
        
        # Update user in database
        result = await db.execute(select(User).where(User.id == user_id))
        user = result.scalar_one_or_none()
        
        if user:
            user.encrypted_shares = encrypted_shares
            await db.commit()
        
        return encrypted_shares
    
    async def delete_user(
        self,
        user_id: uuid.UUID,
        db: AsyncSession
    ) -> None:
        """
        Delete a user from the system (Algorithm 4 - UserDeletion)
        
        Args:
            user_id: User ID
            db: Database session
        """
        # Clear user's encrypted shares
        result = await db.execute(select(User).where(User.id == user_id))
        user = result.scalar_one_or_none()
        
        if user:
            user.encrypted_shares = None
            await db.commit()
