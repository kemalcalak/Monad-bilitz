from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """Application settings"""

    # Database
    POSTGRES_USER: str = "monad_user"
    POSTGRES_PASSWORD: str = "monad_password_123"
    POSTGRES_DB: str = "monad_bilitz"
    POSTGRES_HOST: str = "db"
    POSTGRES_PORT: int = 5432

    @property
    def DATABASE_URL(self) -> str:
        """Construct database URL from components"""
        return f"postgresql+asyncpg://{self.POSTGRES_USER}:{self.POSTGRES_PASSWORD}@{self.POSTGRES_HOST}:{self.POSTGRES_PORT}/{self.POSTGRES_DB}"

    # Redis
    REDIS_HOST: str = "redis"
    REDIS_PORT: int = 6379
    REDIS_DB: int = 0

    @property
    def REDIS_URL(self) -> str:
        """Construct Redis URL from components"""
        return f"redis://{self.REDIS_HOST}:{self.REDIS_PORT}/{self.REDIS_DB}"

    # JWT
    JWT_SECRET_KEY: str = "your-super-secret-jwt-key-change-this-in-production"
    JWT_ALGORITHM: str = "HS256"
    JWT_EXPIRATION_DAYS: int = 7

    # Monad Testnet
    MONAD_RPC_URL: str = "https://testnet-rpc.monad.xyz"
    MONAD_WSS_URL: str = "wss://testnet-rpc.monad.xyz"
    MONAD_CHAIN_ID: int = 10143
    ADMIN_WALLET_PRIVATE_KEY: str = ""

    # Smart Contract Addresses
    HIERARCHY_MANAGER_ADDRESS: str = ""
    SIGNATURE_AUTHORITY_ADDRESS: str = ""

    # OpenAI
    OPENAI_API_KEY: str = ""

    # Socket.IO
    SOCKETIO_CORS_ORIGINS: list = ["http://localhost:3000", "http://localhost:8000"]

    # HKAS Cryptography
    HKAS_ENCRYPTION_KEY: str = ""
    PRIME_FIELD_BITS: int = 256
    DEFAULT_SECURITY_LEVEL: int = 128
    DEFAULT_BETA: int = 2

    class Config:
        env_file = ".env"
        case_sensitive = True


settings = Settings()
