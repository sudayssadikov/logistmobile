from datetime import datetime
from typing import List, Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.enums import SystemRole, UserRole
from app.dependencies.auth import require_role
from app.dependencies.db import get_db
from app.models.user import User
from app.schemas.common import ApiResponse
from app.schemas.driver_vehicle import (
    DriverVehicleCreate,
    DriverVehicleResponse,
    DriverPreferencesUpdate,
    DriverPreferencesResponse,
    DriverLocationUpdate,
    DriverFeedResponse,
)
from app.services.driver_service import DriverService

router = APIRouter(prefix="/driver", tags=["Driver Portal & Matching"])

@router.put("/location", response_model=ApiResponse[DriverPreferencesResponse])
async def update_driver_location(
    req: DriverLocationUpdate,
    current_user: User = Depends(require_role(UserRole.DRIVER, SystemRole.CARRIER)),
    db: AsyncSession = Depends(get_db),
):
    service = DriverService(db)
    result = await service.update_location(current_user.id, req)
    return ApiResponse(
        data=result,
        message="Haydovchi joylashuvi muvaffaqiyatli yangilandi",
    )

@router.get("/vehicles", response_model=ApiResponse[List[DriverVehicleResponse]])
async def get_driver_vehicles(
    current_user: User = Depends(require_role(UserRole.DRIVER, SystemRole.CARRIER)),
    db: AsyncSession = Depends(get_db),
):
    service = DriverService(db)
    vehicles = await service.get_driver_vehicles(current_user.id)
    return ApiResponse(
        data=vehicles,
        message="Transport vositalari ro'yxati",
    )

@router.post("/vehicles", response_model=ApiResponse[DriverVehicleResponse], status_code=status.HTTP_201_CREATED)
async def add_driver_vehicle(
    req: DriverVehicleCreate,
    current_user: User = Depends(require_role(UserRole.DRIVER, SystemRole.CARRIER)),
    db: AsyncSession = Depends(get_db),
):
    service = DriverService(db)
    vehicle = await service.add_driver_vehicle(current_user.id, req)
    return ApiResponse(
        data=vehicle,
        message="Mashina muvaffaqiyatli qo'shildi",
    )

@router.get("/preferences", response_model=ApiResponse[DriverPreferencesResponse])
async def get_driver_preferences(
    current_user: User = Depends(require_role(UserRole.DRIVER, SystemRole.CARRIER)),
    db: AsyncSession = Depends(get_db),
):
    service = DriverService(db)
    prefs = await service.get_or_create_preferences(current_user.id)
    return ApiResponse(
        data=prefs,
        message="Haydovchi afzalliklari",
    )

@router.put("/preferences", response_model=ApiResponse[DriverPreferencesResponse])
async def update_driver_preferences(
    req: DriverPreferencesUpdate,
    current_user: User = Depends(require_role(UserRole.DRIVER, SystemRole.CARRIER)),
    db: AsyncSession = Depends(get_db),
):
    service = DriverService(db)
    prefs = await service.update_preferences(current_user.id, req)
    return ApiResponse(
        data=prefs,
        message="Haydovchi afzalliklari yangilandi",
    )

@router.get("/feed", response_model=ApiResponse[DriverFeedResponse])
async def get_driver_feed(
    sort: str = Query("newest", pattern="^(match|newest|price|distance)$"),
    min_price: Optional[float] = Query(None, ge=0),
    max_price: Optional[float] = Query(None, ge=0),
    include_negotiable: bool = Query(True),
    max_tons: Optional[float] = Query(None, gt=0),
    truck_types: Optional[List[str]] = Query(None),
    from_region: Optional[str] = Query(None),
    to_region: Optional[str] = Query(None),
    pickup_from: Optional[datetime] = Query(None),
    pickup_to: Optional[datetime] = Query(None),
    limit: int = Query(50, ge=1, le=100),
    offset: int = Query(0, ge=0),
    current_user: User = Depends(require_role(UserRole.DRIVER, SystemRole.CARRIER)),
    db: AsyncSession = Depends(get_db),
):
    service = DriverService(db)
    feed = await service.get_driver_feed(
        driver_id=current_user.id,
        sort=sort,
        min_price=min_price,
        max_price=max_price,
        include_negotiable=include_negotiable,
        max_tons=max_tons,
        truck_types=truck_types,
        from_region=from_region,
        to_region=to_region,
        pickup_from=pickup_from,
        pickup_to=pickup_to,
        limit=limit,
        offset=offset,
    )
    return ApiResponse(
        data=feed,
        message="Yuklar lentasi yuklandi",
    )
