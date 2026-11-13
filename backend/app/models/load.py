from datetime import datetime
from typing import List, Optional
import uuid
import json
from sqlalchemy import Boolean, DateTime, Float, ForeignKey, Integer, String, Text, Index
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.database.base import Base, TimestampMixin
from app.core.enums import CargoType, LoadStatus, TruckType

def generate_uuid() -> str:
    return str(uuid.uuid4())

class Load(Base, TimestampMixin):
    __tablename__ = "loads"

    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=generate_uuid)
    shipper_id: Mapped[str] = mapped_column(String(64), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    status: Mapped[str] = mapped_column(String(32), default=LoadStatus.ACTIVE.value, nullable=False, index=True)
    
    cargo_name: Mapped[str] = mapped_column(String(255), nullable=False)
    cargo_type: Mapped[str] = mapped_column(String(64), default=CargoType.BOSHQA.value, nullable=False)
    weight_tons: Mapped[float] = mapped_column(Float, nullable=False)
    volume_m3: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    truck_type: Mapped[str] = mapped_column(String(64), default=TruckType.TENT.value, nullable=False, index=True)
    
    # Origin location
    from_lat: Mapped[float] = mapped_column(Float, nullable=False)
    from_lng: Mapped[float] = mapped_column(Float, nullable=False)
    from_address: Mapped[str] = mapped_column(String(512), nullable=False)
    from_region: Mapped[str] = mapped_column(String(128), nullable=False, index=True)
    from_city: Mapped[str] = mapped_column(String(128), nullable=False)
    
    # Destination location
    to_lat: Mapped[float] = mapped_column(Float, nullable=False)
    to_lng: Mapped[float] = mapped_column(Float, nullable=False)
    to_address: Mapped[str] = mapped_column(String(512), nullable=False)
    to_region: Mapped[str] = mapped_column(String(128), nullable=False, index=True)
    to_city: Mapped[str] = mapped_column(String(128), nullable=False)
    
    distance_km: Mapped[float] = mapped_column(Float, nullable=False)
    pickup_date: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, index=True)
    
    # Pricing
    price_uzs: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    price_negotiable: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    
    # Additional
    description: Mapped[Optional[str]] = mapped_column(String(500), nullable=True)
    photos_json: Mapped[Optional[str]] = mapped_column(Text, nullable=True, default="[]")

    # Relationship
    shipper: Mapped["User"] = relationship("User", foreign_keys=[shipper_id])

    @property
    def photos(self) -> List[str]:
        if not self.photos_json:
            return []
        try:
            return json.loads(self.photos_json)
        except Exception:
            return []

    @photos.setter
    def photos(self, val: List[str]):
        self.photos_json = json.dumps(val or [])

