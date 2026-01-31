"""
Authentication Routes

Handles user registration, login, and wallet connection
"""

from datetime import datetime, timedelta
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from jose import JWTError, jwt
from passlib.context import CryptContext
from pydantic import BaseModel, EmailStr
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.config import settings
from app.db.session import get_db
from app.models.user import User
from app.models.hierarchy import Group


router = APIRouter(prefix="/auth", tags=["Authentication"])

# Password hashing
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# OAuth2 scheme
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login")


# Schemas
class UserRegister(BaseModel):
    username: str
    email: EmailStr
    password: str
    wallet_address: Optional[str] = None


class UserLogin(BaseModel):
    username: str
    password: str


class WalletConnect(BaseModel):
    wallet_address: str
    signature: str
    message: str


class Token(BaseModel):
    access_token: str
    token_type: str


class UserResponse(BaseModel):
    id: str
    username: str
    email: str
    wallet_address: Optional[str]
    group_name: Optional[str]
    created_at: datetime


# Helper functions
def hash_password(password: str) -> str:
    """Hash a password"""
    return pwd_context.hash(password)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify a password"""
    return pwd_context.verify(plain_password, hashed_password)


def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    """Create JWT access token"""
    to_encode = data.copy()
    
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(days=settings.JWT_EXPIRATION_DAYS)
    
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, settings.JWT_SECRET_KEY, algorithm=settings.JWT_ALGORITHM)
    
    return encoded_jwt


async def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
) -> User:
    """Get current authenticated user"""
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    
    try:
        payload = jwt.decode(token, settings.JWT_SECRET_KEY, algorithms=[settings.JWT_ALGORITHM])
        user_id: str = payload.get("sub")
        if user_id is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception
    
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    
    if user is None:
        raise credentials_exception
    
    return user


# Routes
@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def register(user_data: UserRegister, db: AsyncSession = Depends(get_db)):
    """
    Register a new user
    
    - **username**: Unique username
    - **email**: User email
    - **password**: Password (will be hashed)
    - **wallet_address**: Optional Ethereum wallet address
    """
    # Check if username exists
    result = await db.execute(select(User).where(User.username == user_data.username))
    if result.scalar_one_or_none():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Username already exists"
        )
    
    # Check if email exists
    result = await db.execute(select(User).where(User.email == user_data.email))
    if result.scalar_one_or_none():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already exists"
        )
    
    # Create user
    user = User(
        username=user_data.username,
        email=user_data.email,
        hashed_password=hash_password(user_data.password),
        wallet_address=user_data.wallet_address,
    )
    
    db.add(user)
    await db.commit()
    await db.refresh(user)
    
    return UserResponse(
        id=str(user.id),
        username=user.username,
        email=user.email,
        wallet_address=user.wallet_address,
        group_name=user.group.group_name if user.group else None,
        created_at=user.created_at,
    )


@router.post("/login", response_model=Token)
async def login(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: AsyncSession = Depends(get_db)
):
    """
    Login with username and password
    
    Returns JWT access token
    """
    # Get user
    result = await db.execute(select(User).where(User.username == form_data.username))
    user = result.scalar_one_or_none()
    
    if not user or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Create access token
    access_token = create_access_token(data={"sub": str(user.id)})
    
    return Token(access_token=access_token, token_type="bearer")


@router.post("/wallet-connect", response_model=Token)
async def wallet_connect(
    wallet_data: WalletConnect,
    db: AsyncSession = Depends(get_db)
):
    """
    Connect with Ethereum wallet (MetaMask)
    
    - **wallet_address**: Ethereum address
    - **signature**: Signed message
    - **message**: Original message that was signed
    
    Returns JWT access token
    """
    # TODO: Verify signature using Web3
    # For now, we'll do basic validation
    
    if not wallet_data.wallet_address.startswith("0x"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid wallet address format"
        )
    
    # Find or create user by wallet address
    result = await db.execute(
        select(User).where(User.wallet_address == wallet_data.wallet_address)
    )
    user = result.scalar_one_or_none()
    
    if not user:
        # Create new user with wallet
        user = User(
            username=f"user_{wallet_data.wallet_address[:8]}",
            email=f"{wallet_data.wallet_address[:8]}@wallet.local",
            wallet_address=wallet_data.wallet_address,
            hashed_password=hash_password(wallet_data.wallet_address),  # Dummy password
        )
        db.add(user)
        await db.commit()
        await db.refresh(user)
    
    # Create access token
    access_token = create_access_token(data={"sub": str(user.id)})
    
    return Token(access_token=access_token, token_type="bearer")


@router.get("/me", response_model=UserResponse)
async def get_me(current_user: User = Depends(get_current_user)):
    """
    Get current user information
    """
    return UserResponse(
        id=str(current_user.id),
        username=current_user.username,
        email=current_user.email,
        wallet_address=current_user.wallet_address,
        group_name=current_user.group.group_name if current_user.group else None,
        created_at=current_user.created_at,
    )
