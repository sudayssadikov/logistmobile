from typing import Optional
from fastapi import Depends, Header
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.exceptions import AuthenticationError
from app.core.security import decode_token
from app.dependencies.db import get_db
from app.models.user import User
from app.repositories.user_repo import UserRepository

security = HTTPBearer(auto_error=False)

async def get_current_user(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(security),
    db: AsyncSession = Depends(get_db),
) -> User:
    if not credentials or not credentials.credentials:
        raise AuthenticationError("Not authenticated. Bearer token missing.")

    token = credentials.credentials
    payload = decode_token(token)
    user_id: Optional[str] = payload.get("sub")
    if not user_id:
        raise AuthenticationError("Invalid token subject.")

    user_repo = UserRepository(db)
    user = await user_repo.get_by_id(user_id)
    if not user or not user.is_active:
        raise AuthenticationError("User not found or account disabled.")

    return user

async def get_optional_current_user(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(security),
    db: AsyncSession = Depends(get_db),
) -> Optional[User]:
    if not credentials or not credentials.credentials:
        return None
    try:
        token = credentials.credentials
        payload = decode_token(token)
        user_id: Optional[str] = payload.get("sub")
        if not user_id:
            return None
        user_repo = UserRepository(db)
        return await user_repo.get_by_id(user_id)
    except Exception:
        return None
