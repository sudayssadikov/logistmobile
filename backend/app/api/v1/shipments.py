from typing import Any, List, Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.enums import LoadStatus, UserRole
from app.dependencies.auth import get_current_user, get_optional_current_user, require_role
from app.dependencies.db import get_db
from app.models.user import User
from app.schemas.bid import CounterBidRequest, SubmitBidRequest
from app.schemas.common import ApiResponse
from app.schemas.driver import DriverPreferences
from app.schemas.shipment import (
    AdvanceStatusRequest,
    CreateShipmentRequest,
    MatchedShipmentResponse,
    ShipmentModel,
)
from app.services.ai_matcher_service import AIMatcherService
from app.services.bid_service import BidService
from app.services.escrow_service import EscrowService
from app.services.shipment_service import ShipmentService

router = APIRouter(tags=["Freight & Shipments"])

# /loads endpoint (matching Flutter ApiEndpoints.loads)
@router.get("/shipments", response_model=ApiResponse[List[ShipmentModel]])
async def list_shipments(
    role: Optional[str] = None,
    q: Optional[str] = Query(None, description="Search query"),
    status: Optional[str] = Query(None, description="Filter status"),
    current_user: Optional[User] = Depends(get_optional_current_user),
    db: AsyncSession = Depends(get_db),
):
    service = ShipmentService(db)
    user_id = current_user.id if current_user else None
    user_role = role or (current_user.role if current_user else None)
    results = await service.get_shipments(role=user_role, user_id=user_id, search_query=q, filter_status=status)
    return ApiResponse(data=results)

@router.get("/shipments/{shipment_id}", response_model=ApiResponse[ShipmentModel])
async def get_shipment_details(
    shipment_id: str,
    db: AsyncSession = Depends(get_db),
):
    service = ShipmentService(db)
    result = await service.get_shipment_by_id(shipment_id)
    return ApiResponse(data=result)

@router.post("/shipments", response_model=ApiResponse[ShipmentModel], status_code=status.HTTP_201_CREATED)
async def create_load(
    req: CreateShipmentRequest,
    current_user: User = Depends(require_role(UserRole.SHIPPER)),
    db: AsyncSession = Depends(get_db),
):
    service = ShipmentService(db)
    result = await service.create_shipment(current_user.id, req)
    return ApiResponse(data=result, message="Freight load posted successfully")

@router.post("/loads/{shipment_id}/status", response_model=ApiResponse[ShipmentModel])
@router.post("/shipments/{shipment_id}/status", response_model=ApiResponse[ShipmentModel])
async def update_load_status(
    shipment_id: str,
    req: AdvanceStatusRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    service = ShipmentService(db)
    result = await service.advance_status(
        shipment_id=shipment_id,
        user_id=current_user.id,
        user_role=current_user.role,
        next_status=req.next_status,
        comments=req.comments,
    )
    return ApiResponse(data=result, message=f"Status advanced to {req.next_status.value}")

# Escrow Lifecycle Endpoints
@router.post("/loads/{shipment_id}/escrow/fund", response_model=ApiResponse[Any])
@router.post("/shipments/{shipment_id}/escrow/fund", response_model=ApiResponse[Any])
async def fund_load_escrow(
    shipment_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    service = EscrowService(db)
    result = await service.fund_escrow(current_user.id, shipment_id)
    return ApiResponse(data=result, message="Funds locked in escrow successfully")

@router.post("/loads/{shipment_id}/escrow/release", response_model=ApiResponse[bool])
@router.post("/shipments/{shipment_id}/escrow/release", response_model=ApiResponse[bool])
async def release_load_escrow(
    shipment_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    service = EscrowService(db)
    result = await service.release_escrow(shipment_id, current_user.id)
    return ApiResponse(data=result, message="Escrow funds released to carrier wallet")

@router.post("/loads/{shipment_id}/escrow/refund", response_model=ApiResponse[bool])
@router.post("/shipments/{shipment_id}/escrow/refund", response_model=ApiResponse[bool])
async def refund_load_escrow(
    shipment_id: str,
    reason: str = "Cancellation refund",
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    service = EscrowService(db)
    result = await service.refund_escrow(shipment_id, current_user.id, reason=reason)
    return ApiResponse(data=result, message="Escrow funds refunded to shipper")

# Bidding Endpoints
@router.post("/loads/{shipment_id}/bids", response_model=ApiResponse[ShipmentModel])
@router.post("/shipments/{shipment_id}/bids", response_model=ApiResponse[ShipmentModel])
async def submit_bid(
    shipment_id: str,
    req: SubmitBidRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    service = BidService(db)
    result = await service.submit_bid(shipment_id, current_user.id, req)
    return ApiResponse(data=result, message="Bid submitted successfully")

@router.post("/loads/{shipment_id}/bids/{bid_id}/accept", response_model=ApiResponse[ShipmentModel])
@router.post("/shipments/{shipment_id}/bids/{bid_id}/accept", response_model=ApiResponse[ShipmentModel])
async def accept_bid(
    shipment_id: str,
    bid_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    service = BidService(db)
    result = await service.accept_bid(shipment_id, bid_id, current_user.id)
    return ApiResponse(data=result, message="Bid accepted and carrier assigned")

@router.post("/loads/{shipment_id}/bids/{bid_id}/counter", response_model=ApiResponse[ShipmentModel])
async def counter_bid(
    shipment_id: str,
    bid_id: str,
    req: CounterBidRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    service = BidService(db)
    result = await service.counter_bid(shipment_id, bid_id, current_user.id, current_user.role, req)
    return ApiResponse(data=result, message="Counter offer sent")

@router.post("/shipments/{shipment_id}/cancel", response_model=ApiResponse[ShipmentModel])
async def cancel_load(
    shipment_id: str,
    reason: str = "User cancellation",
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    service = ShipmentService(db)
    shipment = await service.get_shipment_by_id(shipment_id)
    
    # If escrow is funded, trigger refund without commission
    if shipment.is_escrow_funded:
        escrow_service = EscrowService(db)
        await escrow_service.refund_escrow(shipment_id, current_user.id, reason=reason)
    else:
        await service.advance_status(
            shipment_id=shipment_id,
            user_id=current_user.id,
            user_role=current_user.role,
            next_status=LoadStatus.CANCELLED,
            comments=reason,
        )

    updated = await service.get_shipment_by_id(shipment_id)
    return ApiResponse(data=updated, message="Shipment cancelled and escrow refunded to shipper")

# AI Matcher
@router.post("/shipments/ai-match", response_model=ApiResponse[List[MatchedShipmentResponse]])
async def ai_match_loads(
    prefs: DriverPreferences,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    service = AIMatcherService(db)
    results = await service.get_matched_shipments_for_driver(current_user.id, prefs)
    return ApiResponse(data=results, message="Matched freight loads calculated")
