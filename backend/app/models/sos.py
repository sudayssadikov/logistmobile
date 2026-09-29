from datetime import datetime, timezone
from typing import Optional
from sqlalchemy import Boolean, DateTime, Float, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.database.base import Base, TimestampMixin
from app.models.user import generate_uuid
from app.core.enums import SosServiceType

class SosProvider(Base, TimestampMixin):
    __tablename__ = "sos_providers"

    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=generate_uuid)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    type: Mapped[str] = mapped_column(String(64), default=SosServiceType.HEAVY_TOW_TRUCK.value, nullable=False)
    phone: Mapped[str] = mapped_column(String(64), nullable=False)
    rating: Mapped[float] = mapped_column(Float, default=4.9, nullable=False)
    address: Mapped[str] = mapped_column(String(512), nullable=False)
    latitude: Mapped[float] = mapped_column(Float, nullable=False)
    longitude: Mapped[float] = mapped_column(Float, nullable=False)
    is_24_7: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

class SosRequest(Base, TimestampMixin):
    __tablename__ = "sos_requests"

    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=generate_uuid)
    driver_id: Mapped[str] = mapped_column(String(64), ForeignKey("users.id"), nullable=False, index=True)
    shipment_id: Mapped[Optional[str]] = mapped_column(String(64), ForeignKey("shipments.id"), nullable=True)
    service_type: Mapped[str] = mapped_column(String(64), default=SosServiceType.HEAVY_TOW_TRUCK.value, nullable=False)
    latitude: Mapped[float] = mapped_column(Float, nullable=False)
    longitude: Mapped[float] = mapped_column(Float, nullable=False)
    description: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    is_resolved: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)

    driver: Mapped["User"] = relationship("User")
