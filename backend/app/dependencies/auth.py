from typing import Callable, Optional, Sequence, Union
from fastapi import Depends, Header, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.enums import SystemRole, UserRole
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

def require_role(*allowed_roles: Union[UserRole, SystemRole, str]) -> Callable:
    async def role_checker(
        current_user: User = Depends(get_current_user),
    ) -> User:
        allowed = []
        for r in allowed_roles:
            if hasattr(r, "value"):
                allowed.append(r.value.lower())
            else:
                allowed.append(str(r).lower())

        user_role = (current_user.role or "").lower()
        if user_role not in allowed and not getattr(current_user, "is_superuser", False):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Forbidden: Insufficient role permissions. Allowed: {allowed}, current: {user_role}",
            )
        return current_user
    return role_checker

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
