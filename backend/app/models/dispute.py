from datetime import datetime, timezone
from typing import List, Optional
from sqlalchemy import Float, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.database.base import Base, TimestampMixin
from app.models.user import generate_uuid
from app.core.enums import DisputeReason, DisputeStatus

class Dispute(Base, TimestampMixin):
    __tablename__ = "disputes"

    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=generate_uuid)
    shipment_id: Mapped[str] = mapped_column(String(64), ForeignKey("shipments.id"), nullable=False, index=True)
    tracking_code: Mapped[str] = mapped_column(String(64), nullable=False)
    claimant_id: Mapped[str] = mapped_column(String(64), ForeignKey("users.id"), nullable=False, index=True)
    claimant_name: Mapped[str] = mapped_column(String(255), nullable=False)
    reason: Mapped[str] = mapped_column(String(64), default=DisputeReason.DAMAGED_CARGO.value, nullable=False)
    description: Mapped[str] = mapped_column(Text, nullable=False)
    claim_amount: Mapped[float] = mapped_column(Float, nullable=False)
    evidence_photos_json: Mapped[str] = mapped_column(Text, default="[]", nullable=False)
    status: Mapped[str] = mapped_column(String(32), default=DisputeStatus.UNDER_REVIEW.value, nullable=False)

    claimant: Mapped["User"] = relationship("User", foreign_keys=[claimant_id])
    shipment: Mapped["Shipment"] = relationship("Shipment")
    timeline: Mapped[List["DisputeTimeline"]] = relationship("DisputeTimeline", back_populates="dispute", cascade="all, delete-orphan", order_by="DisputeTimeline.created_at")

class DisputeTimeline(Base, TimestampMixin):
    __tablename__ = "dispute_timelines"

    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=generate_uuid)
    dispute_id: Mapped[str] = mapped_column(String(64), ForeignKey("disputes.id", ondelete="CASCADE"), nullable=False, index=True)
    status: Mapped[str] = mapped_column(String(32), nullable=False)
    message: Mapped[str] = mapped_column(Text, nullable=False)

    dispute: Mapped["Dispute"] = relationship("Dispute", back_populates="timeline")
