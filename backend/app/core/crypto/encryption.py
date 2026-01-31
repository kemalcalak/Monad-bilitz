"""
Encryption utilities for HKAS

Provides Fernet-based encryption for storing user shares and sensitive data
"""

import json
from typing import Dict, Any

from cryptography.fernet import Fernet


def generate_encryption_key() -> bytes:
    """
    Generate a new Fernet encryption key
    
    Returns:
        Encryption key (bytes)
    """
    return Fernet.generate_key()


def encrypt_data(data: Dict[str, Any], key: bytes) -> str:
    """
    Encrypt data using Fernet symmetric encryption
    
    Args:
        data: Dictionary to encrypt
        key: Encryption key
        
    Returns:
        Encrypted data as base64 string
    """
    f = Fernet(key)
    
    # Convert dict to JSON string
    json_str = json.dumps(data, default=str)
    
    # Encrypt
    encrypted = f.encrypt(json_str.encode())
    
    return encrypted.decode()


def decrypt_data(encrypted_str: str, key: bytes) -> Dict[str, Any]:
    """
    Decrypt data using Fernet symmetric encryption
    
    Args:
        encrypted_str: Encrypted data (base64 string)
        key: Encryption key
        
    Returns:
        Decrypted dictionary
    """
    f = Fernet(key)
    
    # Decrypt
    decrypted = f.decrypt(encrypted_str.encode())
    
    # Parse JSON
    data = json.loads(decrypted.decode())
    
    return data


def get_encryption_key_from_env() -> bytes:
    """
    Get encryption key from environment variable
    
    Returns:
        Encryption key
    """
    from app.config import settings
    
    if not settings.HKAS_ENCRYPTION_KEY:
        raise ValueError("HKAS_ENCRYPTION_KEY not set in environment")
    
    return settings.HKAS_ENCRYPTION_KEY.encode()


# Numpy array JSON encoder
class NumpyEncoder(json.JSONEncoder):
    """Custom JSON encoder for numpy arrays"""
    
    def default(self, obj):
        import numpy as np
        
        if isinstance(obj, np.ndarray):
            return obj.tolist()
        if isinstance(obj, np.integer):
            return int(obj)
        if isinstance(obj, np.floating):
            return float(obj)
        
        return super().default(obj)
