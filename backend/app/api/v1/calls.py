from typing import List
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from app.dependencies.auth import get_current_user
from app.dependencies.db import get_db
from app.models.user import User
from app.schemas.call import CallLogModel, CallSessionModel, InitiateCallRequest
from app.schemas.common import ApiResponse
from app.services.call_service import CallService

router = APIRouter(prefix="/calls", tags=["VoIP Calling & WebRTC"])

@router.post("/initiate", response_model=ApiResponse[CallSessionModel])
async def initiate_call(
    req: InitiateCallRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    service = CallService(db)
    result = await service.initiate_call(current_user.id, req)
    return ApiResponse(data=result, message="Call session created")

@router.get("/history", response_model=ApiResponse[List[CallLogModel]])
async def get_call_history(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    service = CallService(db)
    result = await service.get_call_history(current_user.id)
    return ApiResponse(data=result)
