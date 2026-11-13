from typing import List
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from app.dependencies.auth import get_current_user
from app.dependencies.db import get_db
from app.models.user import User
from app.schemas.common import ApiResponse
from app.schemas.driver import DriverModel, UpdateDriverStatusRequest
from app.schemas.vehicle import CreateTruckRequest, TruckModel
from app.services.fleet_service import FleetService

router = APIRouter(prefix="/fleet", tags=["Fleet & Dispatch Management"])

@router.get("/trucks", response_model=ApiResponse[List[TruckModel]])
async def get_trucks(
    db: AsyncSession = Depends(get_db),
):
    service = FleetService(db)
    result = await service.get_trucks()
    return ApiResponse(data=result)

@router.post("/trucks", response_model=ApiResponse[TruckModel])
async def create_truck(
    req: CreateTruckRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    service = FleetService(db)
    result = await service.create_truck(req)
    return ApiResponse(data=result, message="Truck registered to fleet")

@router.get("/drivers", response_model=ApiResponse[List[DriverModel]])
async def get_drivers(
    db: AsyncSession = Depends(get_db),
):
    service = FleetService(db)
    result = await service.get_drivers()
    return ApiResponse(data=result)

@router.post("/drivers/{driver_id}/status", response_model=ApiResponse[DriverModel])
async def update_driver_status(
    driver_id: str,
    req: UpdateDriverStatusRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    service = FleetService(db)
    result = await service.update_driver_status(driver_id, req)
    return ApiResponse(data=result, message="Driver status updated")

@router.post("/assign", response_model=ApiResponse[TruckModel])
async def assign_driver(
    truck_id: str,
    driver_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    service = FleetService(db)
    result = await service.assign_driver_to_truck(truck_id, driver_id)
    return ApiResponse(data=result, message="Driver assigned to truck")

@router.post("/unassign", response_model=ApiResponse[TruckModel])
async def unassign_driver(
    truck_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    service = FleetService(db)
    result = await service.unassign_driver_from_truck(truck_id)
    return ApiResponse(data=result, message="Driver unassigned from truck")

@router.delete("/trucks/{truck_id}", response_model=ApiResponse[bool])
async def delete_truck(
    truck_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    service = FleetService(db)
    await service.delete_truck(truck_id)
    return ApiResponse(data=True, message="Truck deleted from fleet")

