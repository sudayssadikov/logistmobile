from datetime import datetime, timezone
from typing import List, Optional
from sqlalchemy import Boolean, DateTime, Float, ForeignKey, Integer, Numeric, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.database.base import Base, TimestampMixin
from app.models.user import generate_uuid
from app.core.enums import EscrowStatus, TransactionType

class Wallet(Base, TimestampMixin):
    __tablename__ = "wallets"

    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=generate_uuid)
    user_id: Mapped[str] = mapped_column(String(64), ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False, index=True)
    currency: Mapped[str] = mapped_column(String(10), default="UZS", nullable=False)
    
    # Financial Balances
    available_balance: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)
    in_escrow_hold_balance: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)
    pending_payouts: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)
    total_lifetime_earnings: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)

    user: Mapped["User"] = relationship("User", back_populates="wallet")
    transactions: Mapped[List["LedgerTransaction"]] = relationship("LedgerTransaction", back_populates="wallet", cascade="all, delete-orphan", order_by="desc(LedgerTransaction.created_at)")
    escrow_locks: Mapped[List["EscrowLock"]] = relationship("EscrowLock", back_populates="wallet", cascade="all, delete-orphan")

class EscrowLock(Base, TimestampMixin):
    __tablename__ = "escrow_locks"

    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=generate_uuid)
    wallet_id: Mapped[str] = mapped_column(String(64), ForeignKey("wallets.id", ondelete="CASCADE"), nullable=False, index=True)
    shipment_id: Mapped[str] = mapped_column(String(64), ForeignKey("shipments.id"), unique=True, nullable=False, index=True)
    tracking_code: Mapped[str] = mapped_column(String(64), nullable=False)
    amount: Mapped[float] = mapped_column(Float, nullable=False)
    status: Mapped[str] = mapped_column(String(32), default=EscrowStatus.HELD.value, nullable=False) # held, released, refunded
    held_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)
    released_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    recipient_carrier_id: Mapped[Optional[str]] = mapped_column(String(64), ForeignKey("users.id"), nullable=True)

    wallet: Mapped["Wallet"] = relationship("Wallet", back_populates="escrow_locks")
    shipment: Mapped["Shipment"] = relationship("Shipment", back_populates="escrow_lock")

class LedgerTransaction(Base, TimestampMixin):
    __tablename__ = "ledger_transactions"

    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=generate_uuid)
    wallet_id: Mapped[str] = mapped_column(String(64), ForeignKey("wallets.id", ondelete="CASCADE"), nullable=False, index=True)
    type: Mapped[str] = mapped_column(String(32), nullable=False) # deposit, escrowHold, escrowRelease, payout, commission, refund
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    tracking_code: Mapped[Optional[str]] = mapped_column(String(64), nullable=True)
    amount: Mapped[float] = mapped_column(Float, nullable=False)
    is_completed: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    idempotency_key: Mapped[Optional[str]] = mapped_column(String(128), unique=True, index=True, nullable=True)
    metadata_json: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    wallet: Mapped["Wallet"] = relationship("Wallet", back_populates="transactions")
