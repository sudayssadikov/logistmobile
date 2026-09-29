from typing import List
from fastapi import Depends
from app.core.enums import UserRole
from app.core.exceptions import PermissionDeniedError
from app.dependencies.auth import get_current_user
from app.models.user import User

class RoleChecker:
    def __init__(self, allowed_roles: List[UserRole]):
        self.allowed_roles = [r.value for r in allowed_roles]

    def __call__(self, current_user: User = Depends(get_current_user)) -> User:
        if current_user.is_superuser:
            return current_user

        if current_user.role not in self.allowed_roles:
            raise PermissionDeniedError(
                f"Role '{current_user.role}' is not authorized. Allowed roles: {self.allowed_roles}"
            )
        return current_user

def require_role(*roles: UserRole):
    return RoleChecker(list(roles))
