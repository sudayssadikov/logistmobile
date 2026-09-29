from typing import Optional
from sqlalchemy import Boolean, Float, ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.database.base import Base, TimestampMixin
from app.models.user import generate_uuid
from app.core.enums import DriverStatus

class DriverProfile(Base, TimestampMixin):
    __tablename__ = "driver_profiles"

    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=generate_uuid)
    user_id: Mapped[str] = mapped_column(String(64), ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False)
    status: Mapped[str] = mapped_column(String(32), default=DriverStatus.IDLE.value, nullable=False)
    assigned_vehicle_plate: Mapped[Optional[str]] = mapped_column(String(64), nullable=True)
    assigned_truck_id: Mapped[Optional[str]] = mapped_column(String(64), ForeignKey("vehicles.id"), nullable=True)
    
    # Preference parameters for AI load matcher
    current_city: Mapped[str] = mapped_column(String(128), default="Tashkent")
    max_radius_km: Mapped[float] = mapped_column(Float, default=50.0)
    truck_type: Mapped[str] = mapped_column(String(64), default="Refrigerated")
    max_weight_tons: Mapped[float] = mapped_column(Float, default=24.0)
    min_rate_per_km: Mapped[float] = mapped_column(Float, default=14000.0)
    has_refrigeration: Mapped[bool] = mapped_column(Boolean, default=True)

    user: Mapped["User"] = relationship("User")
    assigned_truck: Mapped[Optional["Vehicle"]] = relationship("Vehicle")
