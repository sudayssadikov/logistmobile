from datetime import datetime, timezone
from typing import List, Optional
from pydantic import Field
from app.schemas.common import BaseSchema
from app.core.enums import TransactionType

class EscrowTransactionModel(BaseSchema):
    id: str
    type: TransactionType
    title: str
    tracking_code: Optional[str] = Field(None, alias="trackingCode")
    amount: float
    timestamp: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
    is_completed: bool = Field(True, alias="isCompleted")

class WalletModel(BaseSchema):
    available_balance: float = Field(0.0, alias="availableBalance")
    in_escrow_hold_balance: float = Field(0.0, alias="inEscrowHoldBalance")
    pending_payouts: float = Field(0.0, alias="pendingPayouts")
    total_lifetime_earnings: float = Field(0.0, alias="totalLifetimeEarnings")
    transactions: List[EscrowTransactionModel] = []

class DepositRequest(BaseSchema):
    amount: float
    card_number: Optional[str] = Field(None, alias="cardNumber")
    idempotency_key: Optional[str] = Field(None, alias="idempotencyKey")

class WithdrawalRequest(BaseSchema):
    amount: float
    card_number: str = Field(..., alias="cardNumber")
    idempotency_key: Optional[str] = Field(None, alias="idempotencyKey")

class FundEscrowRequest(BaseSchema):
    shipment_id: str = Field(..., alias="shipmentId")
    idempotency_key: Optional[str] = Field(None, alias="idempotencyKey")
