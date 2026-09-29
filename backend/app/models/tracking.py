from datetime import datetime, timezone
from typing import List, Optional
from sqlalchemy import DateTime, Float, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.database.base import Base, TimestampMixin
from app.models.user import generate_uuid

class TrackingData(Base, TimestampMixin):
    __tablename__ = "tracking_data"

    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=generate_uuid)
    shipment_id: Mapped[str] = mapped_column(String(64), ForeignKey("shipments.id", ondelete="CASCADE"), unique=True, nullable=False, index=True)
    tracking_code: Mapped[str] = mapped_column(String(64), index=True, nullable=False)
    vehicle_plate: Mapped[str] = mapped_column(String(64), nullable=False)
    driver_name: Mapped[str] = mapped_column(String(255), nullable=False)
    driver_phone: Mapped[str] = mapped_column(String(64), nullable=False)
    
    # Route Polyline serialized as JSON array of points
    route_polyline_json: Mapped[str] = mapped_column(Text, default="[]", nullable=False)
    
    # Latest telemetry
    current_latitude: Mapped[float] = mapped_column(Float, default=41.2995, nullable=False)
    current_longitude: Mapped[float] = mapped_column(Float, default=69.2401, nullable=False)
    current_speed_kmh: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)
    current_heading_degrees: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)
    current_altitude_meters: Mapped[float] = mapped_column(Float, default=450.0, nullable=False)
    current_battery_percent: Mapped[int] = mapped_column(Integer, default=95, nullable=False)
    distance_remaining_km: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)
    eta: Mapped[str] = mapped_column(String(128), default="On Schedule", nullable=False)
    next_waypoint_name: Mapped[str] = mapped_column(String(255), default="Tashkent Checkpoint", nullable=False)
    telemetry_timestamp: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)

    shipment: Mapped["Shipment"] = relationship("Shipment", back_populates="tracking_data")
    telemetry_history: Mapped[List["TelemetryLog"]] = relationship("TelemetryLog", back_populates="tracking", cascade="all, delete-orphan")

class TelemetryLog(Base, TimestampMixin):
    __tablename__ = "telemetry_logs"

    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=generate_uuid)
    tracking_id: Mapped[str] = mapped_column(String(64), ForeignKey("tracking_data.id", ondelete="CASCADE"), nullable=False, index=True)
    driver_id: Mapped[str] = mapped_column(String(64), ForeignKey("users.id"), nullable=False)
    latitude: Mapped[float] = mapped_column(Float, nullable=False)
    longitude: Mapped[float] = mapped_column(Float, nullable=False)
    speed_kmh: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)
    heading_degrees: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)
    altitude_meters: Mapped[float] = mapped_column(Float, default=450.0, nullable=False)
    battery_percent: Mapped[int] = mapped_column(Integer, default=100, nullable=False)
    accuracy_meters: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    timestamp: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)

    tracking: Mapped["TrackingData"] = relationship("TrackingData", back_populates="telemetry_history")
    driver: Mapped["User"] = relationship("User")
