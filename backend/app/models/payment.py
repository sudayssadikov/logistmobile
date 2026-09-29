from datetime import datetime, timezone
from typing import Optional
from sqlalchemy import Boolean, DateTime, Float, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.database.base import Base, TimestampMixin
from app.models.user import generate_uuid
from app.core.enums import PaymentProvider, PaymentStatus

class PaymentTransaction(Base, TimestampMixin):
    __tablename__ = "payment_transactions"

    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=generate_uuid)
    user_id: Mapped[str] = mapped_column(String(64), ForeignKey("users.id"), nullable=False, index=True)
    provider: Mapped[str] = mapped_column(String(32), default=PaymentProvider.PAYME.value, nullable=False)
    provider_transaction_id: Mapped[Optional[str]] = mapped_column(String(128), unique=True, index=True, nullable=True)
    amount: Mapped[float] = mapped_column(Float, nullable=False)
    currency: Mapped[str] = mapped_column(String(10), default="UZS", nullable=False)
    status: Mapped[str] = mapped_column(String(32), default=PaymentStatus.PENDING.value, index=True, nullable=False)
    idempotency_key: Mapped[Optional[str]] = mapped_column(String(128), unique=True, index=True, nullable=True)
    description: Mapped[str] = mapped_column(String(255), default="Wallet Top-up")
    paid_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    raw_payload: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    user: Mapped["User"] = relationship("User")

class WebhookLog(Base, TimestampMixin):
    __tablename__ = "webhook_logs"

    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=generate_uuid)
    provider: Mapped[str] = mapped_column(String(32), nullable=False)
    event_type: Mapped[str] = mapped_column(String(64), nullable=False)
    signature: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    is_valid_signature: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    payload: Mapped[str] = mapped_column(Text, nullable=False)
    response_body: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    response_code: Mapped[int] = mapped_column(Integer, default=200, nullable=False)
