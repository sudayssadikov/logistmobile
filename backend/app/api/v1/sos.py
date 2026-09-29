from typing import List
from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from app.dependencies.auth import get_current_user
from app.dependencies.db import get_db
from app.models.user import User
from app.schemas.common import ApiResponse
from app.schemas.sos import NearbySosProvider, SosRequestResponse, TriggerSosRequest
from app.services.sos_service import SosService

router = APIRouter(prefix="/sos", tags=["SOS Roadside Emergency"])

@router.get("/providers", response_model=ApiResponse[List[NearbySosProvider]])
async def get_nearby_providers(
    lat: float = Query(41.2995, description="Driver latitude"),
    lng: float = Query(69.2401, description="Driver longitude"),
    db: AsyncSession = Depends(get_db),
):
    service = SosService(db)
    results = await service.get_nearby_providers(lat, lng)
    return ApiResponse(data=results)

@router.post("/trigger", response_model=ApiResponse[SosRequestResponse])
async def trigger_sos(
    req: TriggerSosRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    service = SosService(db)
    result = await service.trigger_sos(current_user.id, req)
    return ApiResponse(data=result, message="Emergency assistance signal broadcasted")
