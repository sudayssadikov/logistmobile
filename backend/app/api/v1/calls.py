from typing import Any, Dict, List
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from app.config.settings import settings
from app.dependencies.auth import get_current_user
from app.dependencies.db import get_db
from app.models.user import User
from app.schemas.call import (
    CallLogModel,
    CallSessionModel,
    InitiateCallRequest,
    UpdateCallStatusRequest,
)
from app.schemas.common import ApiResponse
from app.services.call_service import CallService

router = APIRouter(prefix="/calls", tags=["VoIP Calling & WebRTC"])

@router.get("/ice-servers", response_model=ApiResponse[Dict[str, Any]])
async def get_ice_servers(current_user: User = Depends(get_current_user)):
    """Returns WebRTC STUN and TURN server credentials for NAT traversal."""
    servers = [
        {"urls": [settings.STUN_SERVER_URL, "stun:stun1.l.google.com:19302"]},
        {
            "urls": [f"turn:{settings.COTURN_HOST}:{settings.COTURN_PORT}?transport=udp", f"turn:{settings.COTURN_HOST}:{settings.COTURN_PORT}?transport=tcp"],
            "username": f"user_{current_user.id}",
            "credential": settings.COTURN_SECRET,
        },
    ]
    return ApiResponse(data={"iceServers": servers})

@router.post("/initiate", response_model=ApiResponse[CallSessionModel])
async def initiate_call(
    req: InitiateCallRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    service = CallService(db)
    result = await service.initiate_call(current_user.id, req)
    return ApiResponse(data=result, message="Call session created")

@router.post("/{call_id}/status", response_model=ApiResponse[CallSessionModel])
async def update_call_status(
    call_id: str,
    req: UpdateCallStatusRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    service = CallService(db)
    result = await service.update_call_status(call_id, req)
    return ApiResponse(data=result, message="Call status updated")

@router.get("/history", response_model=ApiResponse[List[CallLogModel]])
async def get_call_history(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    service = CallService(db)
    result = await service.get_call_history(current_user.id)
    return ApiResponse(data=result)
