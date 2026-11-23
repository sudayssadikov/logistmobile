from datetime import datetime
from typing import List, Optional
import uuid
import json
from sqlalchemy import Boolean, DateTime, Float, ForeignKey, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.database.base import Base, TimestampMixin
from app.core.enums import TruckType

def generate_uuid() -> str:
    return str(uuid.uuid4())

class DriverVehicle(Base, TimestampMixin):
    __tablename__ = "driver_vehicles"

    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=generate_uuid)
    driver_id: Mapped[str] = mapped_column(String(64), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    truck_type: Mapped[str] = mapped_column(String(64), default=TruckType.TENT.value, nullable=False, index=True)
    capacity_tons: Mapped[float] = mapped_column(Float, nullable=False)
    plate_number: Mapped[Optional[str]] = mapped_column(String(64), nullable=True)
    is_primary: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    driver: Mapped["User"] = relationship("User", foreign_keys=[driver_id])


class DriverPreferences(Base, TimestampMixin):
    __tablename__ = "driver_preferences"

    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=generate_uuid)
    driver_id: Mapped[str] = mapped_column(String(64), ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False, index=True)
    home_region: Mapped[str] = mapped_column(String(128), default="Toshkent shahri", nullable=False)
    preferred_from_regions_json: Mapped[str] = mapped_column(Text, default="[]", nullable=False)
    preferred_to_regions_json: Mapped[str] = mapped_column(Text, default="[]", nullable=False)
    min_price_uzs: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    current_lat: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    current_lng: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    location_updated_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)

    driver: Mapped["User"] = relationship("User", foreign_keys=[driver_id])

    @property
    def preferred_from_regions(self) -> List[str]:
        if not self.preferred_from_regions_json:
            return []
        try:
            return json.loads(self.preferred_from_regions_json)
        except Exception:
            return []

    @preferred_from_regions.setter
    def preferred_from_regions(self, val: List[str]):
        self.preferred_from_regions_json = json.dumps(val or [])

    @property
    def preferred_to_regions(self) -> List[str]:
        if not self.preferred_to_regions_json:
            return []
        try:
            return json.loads(self.preferred_to_regions_json)
        except Exception:
            return []

    @preferred_to_regions.setter
    def preferred_to_regions(self, val: List[str]):
        self.preferred_to_regions_json = json.dumps(val or [])

