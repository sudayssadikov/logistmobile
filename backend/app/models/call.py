from datetime import datetime, timezone
from typing import Optional
from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.database.base import Base, TimestampMixin
from app.models.user import generate_uuid
from app.core.enums import CallDirection, CallStatus, CallType, UserRole

class CallSession(Base, TimestampMixin):
    __tablename__ = "call_sessions"

    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=generate_uuid)
    shipment_id: Mapped[Optional[str]] = mapped_column(String(64), ForeignKey("shipments.id"), nullable=True)
    caller_id: Mapped[str] = mapped_column(String(64), ForeignKey("users.id"), nullable=False, index=True)
    caller_name: Mapped[str] = mapped_column(String(255), nullable=False)
    caller_role: Mapped[str] = mapped_column(String(32), default=UserRole.SHIPPER.value, nullable=False)
    caller_avatar: Mapped[Optional[str]] = mapped_column(String(512), nullable=True)
    
    receiver_id: Mapped[str] = mapped_column(String(64), ForeignKey("users.id"), nullable=False, index=True)
    receiver_name: Mapped[str] = mapped_column(String(255), nullable=False)
    receiver_role: Mapped[str] = mapped_column(String(32), default=UserRole.DRIVER.value, nullable=False)
    receiver_avatar: Mapped[Optional[str]] = mapped_column(String(512), nullable=True)
    
    type: Mapped[str] = mapped_column(String(32), default=CallType.AUDIO.value, nullable=False)
    status: Mapped[str] = mapped_column(String(32), default=CallStatus.IDLE.value, nullable=False)
    direction: Mapped[str] = mapped_column(String(32), default=CallDirection.OUTGOING.value, nullable=False)
    
    started_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)
    connected_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    ended_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    duration_seconds: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    
    caller: Mapped["User"] = relationship("User", foreign_keys=[caller_id])
    receiver: Mapped["User"] = relationship("User", foreign_keys=[receiver_id])

class CallLog(Base, TimestampMixin):
    __tablename__ = "call_logs"

    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=generate_uuid)
    user_id: Mapped[str] = mapped_column(String(64), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    participant_name: Mapped[str] = mapped_column(String(255), nullable=False)
    participant_role: Mapped[str] = mapped_column(String(32), default=UserRole.DRIVER.value, nullable=False)
    participant_phone: Mapped[Optional[str]] = mapped_column(String(64), nullable=True)
    type: Mapped[str] = mapped_column(String(32), default=CallType.AUDIO.value, nullable=False)
    direction: Mapped[str] = mapped_column(String(32), default=CallDirection.INCOMING.value, nullable=False)
    outcome: Mapped[str] = mapped_column(String(32), default=CallStatus.ACTIVE.value, nullable=False)
    duration_seconds: Mapped[int] = mapped_column(Integer, default=0, nullable=False)

    user: Mapped["User"] = relationship("User")
