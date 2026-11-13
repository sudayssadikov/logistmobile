from typing import Callable, Sequence, Union
from fastapi import Depends, HTTPException, status
from app.core.enums import SystemRole, UserRole
from app.dependencies.auth import get_current_user
from app.models.user import User

class RoleChecker:
    def __init__(self, allowed_roles: Sequence[Union[UserRole, SystemRole, str]]):
        self.allowed_roles = [
            r.value.lower() if hasattr(r, "value") else str(r).lower()
            for r in allowed_roles
        ]

    def __call__(self, current_user: User = Depends(get_current_user)) -> User:
        if getattr(current_user, "is_superuser", False):
            return current_user

        user_role = (current_user.role or "").lower()
        if user_role not in self.allowed_roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Role '{user_role}' is not authorized. Allowed roles: {self.allowed_roles}",
            )
        return current_user

def require_role(*roles: Union[UserRole, SystemRole, str]):
    return RoleChecker(list(roles))
