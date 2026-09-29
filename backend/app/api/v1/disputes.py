from typing import List
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from app.dependencies.auth import get_current_user
from app.dependencies.db import get_db
from app.models.user import User
from app.schemas.common import ApiResponse
from app.schemas.dispute import CreateDisputeRequest, DisputeModel, ResolveDisputeRequest
from app.services.dispute_service import DisputeService

router = APIRouter(prefix="/disputes", tags=["Disputes & Arbitration"])

@router.get("", response_model=ApiResponse[List[DisputeModel]])
async def list_disputes(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    service = DisputeService(db)
    claimant_id = current_user.id if current_user.role != "admin" else None
    results = await service.get_disputes(claimant_id)
    return ApiResponse(data=results)

@router.get("/{dispute_id}", response_model=ApiResponse[DisputeModel])
async def get_dispute(
    dispute_id: str,
    db: AsyncSession = Depends(get_db),
):
    service = DisputeService(db)
    result = await service.get_dispute_by_id(dispute_id)
    return ApiResponse(data=result)

@router.post("", response_model=ApiResponse[DisputeModel])
async def create_dispute(
    req: CreateDisputeRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    service = DisputeService(db)
    result = await service.create_dispute(current_user.id, req)
    return ApiResponse(data=result, message="Dispute opened and submitted for arbitration")

@router.post("/{dispute_id}/resolve", response_model=ApiResponse[DisputeModel])
async def resolve_dispute(
    dispute_id: str,
    req: ResolveDisputeRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    service = DisputeService(db)
    result = await service.resolve_dispute(dispute_id, current_user.id, req)
    return ApiResponse(data=result, message="Dispute resolved")
