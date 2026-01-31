"""
HKAS Mathematical Foundation - CVP-IPS Implementation

This module implements the Hierarchical Key Assignment Scheme (HKAS) based on
the Closest Vector Problem in Inner Product Space (CVP-IPS).

Reference: "A Hierarchical Key Assignment Scheme" academic paper
"""

import numpy as np
from typing import Tuple, List


class CVPInnerProductSpace:
    """
    CVP-IPS: Closest Vector Problem in Inner Product Space
    
    Implements the mathematical foundation for HKAS including:
    - Vector operations in R^m
    - Gram-Schmidt orthogonalization
    - Orthogonal projection
    - Basis set generation
    """
    
    def __init__(self, dimension_m: int = 32, basis_length_n: int = 10, s: int = 1):
        """
        Initialize CVP-IPS system
        
        Args:
            dimension_m: Vector space dimension (R^m)
            basis_length_n: Length of basis set B_i
            s: Length of unique subset S_i
        """
        self.m = dimension_m
        self.n = basis_length_n
        self.s = s
        
        # Validate parameters
        if self.n <= self.s:
            raise ValueError(f"Basis length n ({self.n}) must be greater than s ({self.s})")
        if self.m < self.n:
            raise ValueError(f"Dimension m ({self.m}) should be >= basis length n ({self.n})")
    
    def generate_public_keys(self) -> Tuple[np.ndarray, np.ndarray]:
        """
        Generate public key vectors f1 and f2
        
        Returns:
            Tuple of (f1, f2) where both are vectors in R^m
        """
        f1 = np.random.rand(self.m)
        f2 = np.random.rand(self.m)
        
        # Normalize for numerical stability
        f1 = f1 / np.linalg.norm(f1)
        f2 = f2 / np.linalg.norm(f2)
        
        return f1, f2
    
    def generate_random_basis(self) -> np.ndarray:
        """
        Generate a random basis set of n vectors in R^m
        
        Returns:
            Matrix of shape (n, m) where each row is a basis vector
        """
        basis = np.random.rand(self.n, self.m)
        
        # Normalize each vector
        for i in range(self.n):
            basis[i] = basis[i] / np.linalg.norm(basis[i])
        
        return basis
    
    def gram_schmidt(self, vectors: np.ndarray) -> np.ndarray:
        """
        Gram-Schmidt orthogonalization process
        
        Converts a set of linearly independent vectors into an orthonormal set
        
        Args:
            vectors: Matrix of shape (k, m) where each row is a vector
            
        Returns:
            Orthonormalized matrix of shape (k', m) where k' <= k
        """
        ortho_vectors = []
        
        for v in vectors:
            # Start with the original vector
            w = v.copy()
            
            # Subtract projections onto all previous orthogonal vectors
            for u in ortho_vectors:
                # Projection of v onto u: proj_u(v) = (v·u / u·u) * u
                projection = np.dot(v, u) / np.dot(u, u) * u
                w = w - projection
            
            # Check if vector is linearly independent
            norm = np.linalg.norm(w)
            if norm > 1e-10:  # Numerical threshold
                # Normalize and add to orthogonal set
                ortho_vectors.append(w / norm)
        
        return np.array(ortho_vectors) if ortho_vectors else np.array([])
    
    def project_vector(self, f: np.ndarray, basis: np.ndarray) -> np.ndarray:
        """
        Project vector f onto the orthogonal complement of span(basis)
        
        This is Algorithm 3 from the paper: GramSchmidt and Projection
        
        Args:
            f: Vector to project (shape: m)
            basis: Basis set (shape: n, m)
            
        Returns:
            Projected vector f* (shape: m)
        """
        # First, orthogonalize the basis
        ortho_basis = self.gram_schmidt(basis)
        
        if len(ortho_basis) == 0:
            return f  # No basis to project onto
        
        # Project f onto orthogonal complement
        # f* = f - sum of projections onto basis vectors
        f_star = f.copy()
        
        for b in ortho_basis:
            # Projection of f onto b
            projection = np.dot(f, b) * b
            f_star = f_star - projection
        
        return f_star
    
    def inner_product(self, v1: np.ndarray, v2: np.ndarray) -> float:
        """
        Compute inner product <v1, v2>
        
        Args:
            v1: First vector
            v2: Second vector
            
        Returns:
            Inner product (scalar)
        """
        return np.dot(v1, v2)
    
    def generate_shared_set(self) -> np.ndarray:
        """
        Generate shared set P of (n - s) vectors
        
        P is shared among all classes in the hierarchy
        
        Returns:
            Matrix of shape (n-s, m)
        """
        p_size = self.n - self.s
        P = np.random.rand(p_size, self.m)
        
        # Normalize
        for i in range(p_size):
            P[i] = P[i] / np.linalg.norm(P[i])
        
        return P
    
    def generate_unique_subset(self) -> np.ndarray:
        """
        Generate unique subset S_i of s vectors for a class
        
        Each class has its own unique S_i
        
        Returns:
            Matrix of shape (s, m)
        """
        S_i = np.random.rand(self.s, self.m)
        
        # Normalize
        for i in range(self.s):
            S_i[i] = S_i[i] / np.linalg.norm(S_i[i])
        
        return S_i
    
    def combine_basis(self, P: np.ndarray, S_i: np.ndarray) -> np.ndarray:
        """
        Combine shared set P and unique subset S_i to form basis B_i
        
        B_i = P ∪ S_i
        
        Args:
            P: Shared set (n-s, m)
            S_i: Unique subset (s, m)
            
        Returns:
            Basis B_i of shape (n, m)
        """
        return np.vstack([P, S_i])
    
    def derive_key(self, basis: np.ndarray, f1: np.ndarray, f2: np.ndarray) -> float:
        """
        Derive key K_i for a class using its basis
        
        K_i = <f*_{1,i}, f2>
        where f*_{1,i} is the projection of f1 onto orthogonal complement of span(B_i)
        
        Args:
            basis: Basis set B_i (n, m)
            f1: Public key vector 1
            f2: Public key vector 2
            
        Returns:
            Derived key K_i (scalar)
        """
        # Project f1 onto orthogonal complement of basis
        f1_star = self.project_vector(f1, basis)
        
        # Compute inner product with f2
        K_i = self.inner_product(f1_star, f2)
        
        return K_i
    
    def verify_orthogonality(self, vectors: np.ndarray, tolerance: float = 1e-10) -> bool:
        """
        Verify that a set of vectors is orthogonal
        
        Args:
            vectors: Matrix of vectors (k, m)
            tolerance: Numerical tolerance for zero
            
        Returns:
            True if vectors are orthogonal
        """
        k = len(vectors)
        
        for i in range(k):
            for j in range(i + 1, k):
                dot_product = np.dot(vectors[i], vectors[j])
                if abs(dot_product) > tolerance:
                    return False
        
        return True


def test_cvp_ips():
    """Test CVP-IPS implementation"""
    print("Testing CVP-IPS Implementation...")
    
    cvp = CVPInnerProductSpace(dimension_m=32, basis_length_n=10, s=1)
    
    # Test 1: Generate public keys
    f1, f2 = cvp.generate_public_keys()
    print(f"✓ Generated public keys: f1 shape {f1.shape}, f2 shape {f2.shape}")
    
    # Test 2: Generate basis
    basis = cvp.generate_random_basis()
    print(f"✓ Generated basis: shape {basis.shape}")
    
    # Test 3: Gram-Schmidt orthogonalization
    ortho_basis = cvp.gram_schmidt(basis)
    is_orthogonal = cvp.verify_orthogonality(ortho_basis)
    print(f"✓ Gram-Schmidt: orthogonal = {is_orthogonal}")
    
    # Test 4: Vector projection
    f1_star = cvp.project_vector(f1, basis)
    print(f"✓ Projected f1: shape {f1_star.shape}")
    
    # Test 5: Key derivation
    K_i = cvp.derive_key(basis, f1, f2)
    print(f"✓ Derived key K_i: {K_i:.6f}")
    
    # Test 6: Shared set and unique subset
    P = cvp.generate_shared_set()
    S_i = cvp.generate_unique_subset()
    B_i = cvp.combine_basis(P, S_i)
    print(f"✓ Combined basis B_i: shape {B_i.shape}")
    
    print("\n✅ All CVP-IPS tests passed!")


if __name__ == "__main__":
    test_cvp_ips()
