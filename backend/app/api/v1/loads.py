from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.enums import UserRole
from app.dependencies.auth import require_role
from app.dependencies.db import get_db
from app.models.user import User
from app.schemas.common import ApiResponse
from app.schemas.load import CreateLoadRequest, LoadResponse
from app.services.load_service import LoadService

router = APIRouter(prefix="/loads", tags=["Loads (Shipper Create Load)"])

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

