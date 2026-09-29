from typing import List, Optional
from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from app.dependencies.auth import get_current_user
from app.dependencies.db import get_db
from app.models.user import User
from app.schemas.common import ApiResponse
from app.schemas.notification import DeviceTokenRegister, NotificationModel
from app.services.notification_service import NotificationService

router = APIRouter(prefix="/notifications", tags=["Notifications"])

@router.get("", response_model=ApiResponse[List[NotificationModel]])
async def get_notifications(
    category: Optional[str] = Query(None, description="Category filter (shipments, payments, alerts, all)"),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    service = NotificationService(db)
    results = await service.get_user_notifications(current_user.id, category)
    return ApiResponse(data=results)

@router.post("/read-all", response_model=ApiResponse[bool])
async def mark_all_as_read(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    service = NotificationService(db)
    await service.mark_all_as_read(current_user.id)
    return ApiResponse(data=True, message="All notifications marked as read")

@router.post("/device-token", response_model=ApiResponse[bool])
async def register_device_token(
    req: DeviceTokenRegister,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    service = NotificationService(db)
    await service.register_device_token(current_user.id, req)
    return ApiResponse(data=True, message="Device token registered")
