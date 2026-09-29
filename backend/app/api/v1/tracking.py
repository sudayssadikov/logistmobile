from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from app.dependencies.auth import get_current_user
from app.dependencies.db import get_db
from app.models.user import User
from app.schemas.common import ApiResponse
from app.schemas.pod import PodSubmissionModel
from app.schemas.tracking import SendLocationRequest, TrackingDataModel
from app.services.tracking_service import TrackingService

router = APIRouter(tags=["Tracking & POD"])

@router.get("/tracking/{shipment_id}", response_model=ApiResponse[TrackingDataModel])
async def get_shipment_tracking(
    shipment_id: str,
    db: AsyncSession = Depends(get_db),
):
    service = TrackingService(db)
    result = await service.get_tracking_by_shipment_id(shipment_id)
    return ApiResponse(data=result)

@router.post("/tracking/{shipment_id}/location", response_model=ApiResponse[TrackingDataModel])
async def send_location(
    shipment_id: str,
    req: SendLocationRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    service = TrackingService(db)
    result = await service.update_location(shipment_id, current_user.id, req)
    return ApiResponse(data=result, message="Location updated successfully")

@router.post("/shipments/{shipment_id}/pod", response_model=ApiResponse[bool])
@router.post("/loads/{shipment_id}/pod", response_model=ApiResponse[bool])
async def submit_pod(
    shipment_id: str,
    req: PodSubmissionModel,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    service = TrackingService(db)
    result = await service.submit_pod(shipment_id, current_user.id, req)
    return ApiResponse(data=result, message="Proof of Delivery submitted successfully")
