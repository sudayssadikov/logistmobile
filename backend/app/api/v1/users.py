from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from app.dependencies.auth import get_current_user
from app.dependencies.db import get_db
from app.models.user import User
from app.schemas.common import ApiResponse
from app.schemas.user import UserModel, UserUpdate
from app.services.user_service import UserService

router = APIRouter(prefix="/users", tags=["Users & Profile"])

@router.get("/{user_id}", response_model=ApiResponse[UserModel])
async def get_user_profile(
    user_id: str,
    db: AsyncSession = Depends(get_db),
):
    service = UserService(db)
    result = await service.get_user_by_id(user_id)
    return ApiResponse(data=result)

@router.put("/profile", response_model=ApiResponse[UserModel])
async def update_profile(
    req: UserUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    service = UserService(db)
    result = await service.update_profile(current_user.id, req)
    return ApiResponse(data=result, message="Profile updated successfully")
