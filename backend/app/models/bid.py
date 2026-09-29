from typing import List, Optional
from sqlalchemy import Boolean, Float, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.database.base import Base, TimestampMixin
from app.models.user import generate_uuid
from app.core.enums import BidNegotiationStatus

class Bid(Base, TimestampMixin):
    __tablename__ = "bids"

    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=generate_uuid)
    shipment_id: Mapped[str] = mapped_column(String(64), ForeignKey("shipments.id", ondelete="CASCADE"), nullable=False, index=True)
    carrier_id: Mapped[str] = mapped_column(String(64), ForeignKey("users.id"), nullable=False, index=True)
    carrier_name: Mapped[str] = mapped_column(String(255), nullable=False)
    driver_name: Mapped[str] = mapped_column(String(255), nullable=False)
    vehicle_model: Mapped[str] = mapped_column(String(255), nullable=False)
    plate_number: Mapped[str] = mapped_column(String(64), nullable=False)
    bid_amount: Mapped[float] = mapped_column(Float, nullable=False)
    counter_price: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    negotiation_status: Mapped[str] = mapped_column(String(32), default=BidNegotiationStatus.PENDING.value, nullable=False)
    carrier_rating: Mapped[float] = mapped_column(Float, default=5.0, nullable=False)
    is_accepted: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)

    shipment: Mapped["Shipment"] = relationship("Shipment", back_populates="bids")
    carrier: Mapped["User"] = relationship("User")
    negotiation_steps: Mapped[List["NegotiationStep"]] = relationship("NegotiationStep", back_populates="bid", cascade="all, delete-orphan")

class NegotiationStep(Base, TimestampMixin):
    __tablename__ = "negotiation_steps"

    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=generate_uuid)
    bid_id: Mapped[str] = mapped_column(String(64), ForeignKey("bids.id", ondelete="CASCADE"), nullable=False, index=True)
    author_role: Mapped[str] = mapped_column(String(32), nullable=False) # shipper or carrier
    author_name: Mapped[str] = mapped_column(String(255), nullable=False)
    proposed_price: Mapped[float] = mapped_column(Float, nullable=False)
    comment: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    bid: Mapped["Bid"] = relationship("Bid", back_populates="negotiation_steps")
