from datetime import datetime
from typing import Any, Dict, Optional
from pydantic import Field
from app.schemas.common import BaseSchema
from app.core.enums import PaymentProvider, PaymentStatus

class PaymentCreateRequest(BaseSchema):
    amount: float
    provider: PaymentProvider = PaymentProvider.DIRECT_CARD
    description: Optional[str] = "LogiFlow Balance Deposit"
    return_url: Optional[str] = None
    idempotency_key: Optional[str] = Field(None, alias="idempotencyKey")

class PaymentResponse(BaseSchema):
    id: str
    user_id: str
    provider: str
    amount: float
    currency: str
    status: str
    payment_url: Optional[str] = None
    created_at: datetime
    paid_at: Optional[datetime] = None

class PaymeWebhookRequest(BaseSchema):
    method: str
    params: Dict[str, Any]
    id: Optional[int] = None

class ClickWebhookRequest(BaseSchema):
    click_trans_id: int
    service_id: int
    click_paydoc_id: int
    merchant_trans_id: str
    amount: float
    action: int
    error: int
    error_note: str
    sign_time: str
    sign_string: str
