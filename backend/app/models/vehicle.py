from typing import Optional
from sqlalchemy import Boolean, Float, ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.database.base import Base, TimestampMixin
from app.models.user import generate_uuid
from app.core.enums import TruckBodyType

class Vehicle(Base, TimestampMixin):
    __tablename__ = "vehicles"

    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=generate_uuid)
    plate_number: Mapped[str] = mapped_column(String(64), unique=True, index=True, nullable=False)
    model: Mapped[str] = mapped_column(String(255), nullable=False) # e.g. Volvo FH 500, MAN TGX
    body_type: Mapped[str] = mapped_column(String(64), default=TruckBodyType.TENT.value, nullable=False)
    max_weight_tons: Mapped[float] = mapped_column(Float, default=22.0, nullable=False)
    max_volume_m3: Mapped[float] = mapped_column(Float, default=86.0, nullable=False)
    is_available: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    
    company_id: Mapped[Optional[str]] = mapped_column(String(64), ForeignKey("companies.id"), nullable=True)
    assigned_driver_id: Mapped[Optional[str]] = mapped_column(String(64), ForeignKey("users.id"), nullable=True)
    assigned_driver_name: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)

    company: Mapped[Optional["Company"]] = relationship("Company", back_populates="vehicles")
    assigned_driver: Mapped[Optional["User"]] = relationship("User")
