from typing import List, Optional
from fastapi import APIRouter, Depends, Query, status, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from app.config.settings import settings
from app.core.enums import UserRole
from app.dependencies.auth import require_role
from app.dependencies.db import get_db
from app.models.user import User
from app.schemas.common import ApiResponse
from app.schemas.load import (
    CreateLoadRequest,
    UpdateLoadRequest,
    CancelLoadRequest,
    LoadResponse,
    LoadSummaryResponse,
    PaginatedLoadSummaryResponse,
    LoadEventResponse,
)
from app.services.load_service import LoadService

router = APIRouter(prefix="/loads", tags=["Loads (Shipper Loads Management)"])

@router.post("", response_model=ApiResponse[LoadResponse], status_code=status.HTTP_201_CREATED)
@router.post("/", response_model=ApiResponse[LoadResponse], status_code=status.HTTP_201_CREATED)
async def create_load(
    req: CreateLoadRequest,
    current_user: User = Depends(require_role(UserRole.SHIPPER)),
    db: AsyncSession = Depends(get_db),
):
    service = LoadService(db)
    result = await service.create_load(current_user.id, req)
    return ApiResponse(
        data=result,
        message="Yuk muvaffaqiyatli e'lon qilindi",
    )

@router.get("/mine", response_model=ApiResponse[PaginatedLoadSummaryResponse])
async def get_my_loads(
    status_group: str = Query("active", pattern="^(active|in_progress|history)$"),
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    current_user: User = Depends(require_role(UserRole.SHIPPER)),
    db: AsyncSession = Depends(get_db),
):
    service = LoadService(db)
    result = await service.get_my_loads(
        shipper_id=current_user.id,
        status_group=status_group,
        page=page,
        limit=limit,
    )
    return ApiResponse(
        data=result,
        message="Yuklarim ro'yxati yuklandi",
    )

@router.get("/{load_id}", response_model=ApiResponse[LoadResponse])
async def get_load_by_id(
    load_id: str,
    current_user: User = Depends(require_role(UserRole.SHIPPER)),
    db: AsyncSession = Depends(get_db),
):
    service = LoadService(db)
    result = await service.get_load_by_id(load_id, current_user.id)
    return ApiResponse(
        data=result,
        message="Yuk ma'lumotlari yuklandi",
    )

@router.patch("/{load_id}", response_model=ApiResponse[LoadResponse])
async def update_load(
    load_id: str,
    req: UpdateLoadRequest,
    current_user: User = Depends(require_role(UserRole.SHIPPER)),
    db: AsyncSession = Depends(get_db),
):
    service = LoadService(db)
    result = await service.update_load(load_id, current_user.id, req)
    return ApiResponse(
        data=result,
        message="Yuk ma'lumotlari yangilandi",
    )

@router.post("/{load_id}/cancel", response_model=ApiResponse[LoadResponse])
async def cancel_load(
    load_id: str,
    req: Optional[CancelLoadRequest] = None,
    current_user: User = Depends(require_role(UserRole.SHIPPER)),
    db: AsyncSession = Depends(get_db),
):
    service = LoadService(db)
    reason = req.reason if req else None
    result = await service.cancel_load(load_id, current_user.id, reason=reason)
    return ApiResponse(
        data=result,
        message="Yuk bekor qilindi",
    )

@router.post("/{load_id}/duplicate", response_model=ApiResponse[LoadResponse], status_code=status.HTTP_201_CREATED)
async def duplicate_load(
    load_id: str,
    current_user: User = Depends(require_role(UserRole.SHIPPER)),
    db: AsyncSession = Depends(get_db),
):
    service = LoadService(db)
    result = await service.duplicate_load(load_id, current_user.id)
    return ApiResponse(
        data=result,
        message="Yukdan muvaffaqiyatli nusxa ko'chirildi",
    )

@router.get("/{load_id}/events", response_model=ApiResponse[List[LoadEventResponse]])
async def get_load_events(
    load_id: str,
    current_user: User = Depends(require_role(UserRole.SHIPPER)),
    db: AsyncSession = Depends(get_db),
):
    service = LoadService(db)
    events = await service.get_load_events(load_id, current_user.id)
    return ApiResponse(
        data=events,
        message="Yuk hodisalari tarixi yuklandi",
    )

@router.post("/{load_id}/dev-status", response_model=ApiResponse[LoadResponse])
async def dev_set_load_status(
    load_id: str,
    new_status: str = Query(..., pattern="^(ACTIVE|ASSIGNED|IN_TRANSIT|DELIVERED|CANCELLED)$"),
    current_user: User = Depends(require_role(UserRole.SHIPPER)),
    db: AsyncSession = Depends(get_db),
):
    """Dev-only status override endpoint for manual testing (disabled by default, blocked in production)."""
    if getattr(settings, "ENVIRONMENT", "").lower() == "production" or not getattr(settings, "ENABLE_DEV_ENDPOINTS", False):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Dev endpoint o'chirilgan yoki mavjud emas.",
        )
    service = LoadService(db)
    result = await service.dev_set_load_status(load_id, new_status)
    return ApiResponse(data=result, message=f"Dev: status {new_status} ga o'rnatildi")
