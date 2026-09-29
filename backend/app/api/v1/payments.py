from typing import Any, Dict, Optional
from fastapi import APIRouter, Depends, Header
from sqlalchemy.ext.asyncio import AsyncSession
from app.dependencies.auth import get_current_user
from app.dependencies.db import get_db
from app.models.user import User
from app.schemas.common import ApiResponse
from app.schemas.payment import ClickWebhookRequest, PaymentCreateRequest, PaymentResponse, PaymeWebhookRequest
from app.services.payment_service import PaymentService

router = APIRouter(prefix="/payments", tags=["Payment Gateways"])

@router.post("/intent", response_model=ApiResponse[PaymentResponse])
async def create_payment_intent(
    req: PaymentCreateRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    service = PaymentService(db)
    result = await service.create_payment_intent(current_user.id, req)
    return ApiResponse(data=result)

@router.post("/webhooks/payme")
async def payme_webhook(
    req: PaymeWebhookRequest,
    authorization: Optional[str] = Header(None),
    db: AsyncSession = Depends(get_db),
) -> Dict[str, Any]:
    service = PaymentService(db)
    return await service.handle_payme_webhook(req, signature=authorization)

@router.post("/webhooks/click")
async def click_webhook(
    req: ClickWebhookRequest,
    db: AsyncSession = Depends(get_db),
) -> Dict[str, Any]:
    service = PaymentService(db)
    return await service.handle_click_webhook(req)
