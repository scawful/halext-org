"""
Encryption utilities for storing API keys securely
Uses Fernet symmetric encryption
"""
import os
import base64
from cryptography.fernet import Fernet
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2


def get_encryption_key() -> bytes:
    """
    Get or generate the encryption key for API keys
    In production, this should be stored in a secure key management service
    """
    key_env = os.getenv("API_KEY_ENCRYPTION_KEY")

    if key_env:
        # Use existing key from environment
        return base64.urlsafe_b64decode(key_env)

    # Generate a new key (for development only)
    # In production, you should set API_KEY_ENCRYPTION_KEY environment variable
    password = os.getenv("SECRET_KEY", "change-this-in-production").encode()
    salt = b"halext-org-api-key-salt"  # In production, use a random salt stored separately

    kdf = PBKDF2(
        algorithm=hashes.SHA256(),
        length=32,
        salt=salt,
        iterations=100000,
    )

    return base64.urlsafe_b64encode(kdf.derive(password))


def encrypt_api_key(api_key: str) -> str:
    """Encrypt an API key for storage"""
    encryption_key = get_encryption_key()
    f = Fernet(encryption_key)
    encrypted = f.encrypt(api_key.encode())
    return encrypted.decode()


def decrypt_api_key(encrypted_key: str) -> str:
    """Decrypt a stored API key"""
    encryption_key = get_encryption_key()
    f = Fernet(encryption_key)
    decrypted = f.decrypt(encrypted_key.encode())
    return decrypted.decode()


def mask_api_key(api_key: str, show_chars: int = 4) -> str:
    """
    Mask an API key for display
    Shows only the last few characters
    """
    if len(api_key) <= show_chars:
        return "*" * len(api_key)

    return "*" * (len(api_key) - show_chars) + api_key[-show_chars:]
