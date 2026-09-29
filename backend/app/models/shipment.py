from datetime import datetime, timezone
from typing import List, Optional
from sqlalchemy import Boolean, DateTime, Float, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.database.base import Base, TimestampMixin
from app.models.user import generate_uuid
from app.core.enums import LoadStatus

class Shipment(Base, TimestampMixin):
    __tablename__ = "shipments"

    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=generate_uuid)
    tracking_code: Mapped[str] = mapped_column(String(64), unique=True, index=True, nullable=False)
    
    # Shipper info
    shipper_id: Mapped[str] = mapped_column(String(64), ForeignKey("users.id"), nullable=False, index=True)
    shipper_name: Mapped[str] = mapped_column(String(255), nullable=False)
    
    # Carrier & Driver assignment
    carrier_id: Mapped[Optional[str]] = mapped_column(String(64), ForeignKey("users.id"), nullable=True, index=True)
    carrier_name: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    driver_id: Mapped[Optional[str]] = mapped_column(String(64), ForeignKey("users.id"), nullable=True, index=True)
    driver_name: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    driver_phone: Mapped[Optional[str]] = mapped_column(String(64), nullable=True)
    vehicle_plate: Mapped[Optional[str]] = mapped_column(String(64), nullable=True)
    
    # Status
    status: Mapped[str] = mapped_column(String(64), default=LoadStatus.CREATED.value, index=True, nullable=False)
    
    # Route: Origin
    origin_city: Mapped[str] = mapped_column(String(128), nullable=False)
    origin_address: Mapped[str] = mapped_column(String(512), nullable=False)
    origin_latitude: Mapped[float] = mapped_column(Float, default=41.2995, nullable=False)
    origin_longitude: Mapped[float] = mapped_column(Float, default=69.2401, nullable=False)
    origin_scheduled_time: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    
    # Route: Destination
    dest_city: Mapped[str] = mapped_column(String(128), nullable=False)
    dest_address: Mapped[str] = mapped_column(String(512), nullable=False)
    dest_latitude: Mapped[float] = mapped_column(Float, default=39.6542, nullable=False)
    dest_longitude: Mapped[float] = mapped_column(Float, default=66.9597, nullable=False)
    dest_scheduled_time: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    
    # Cargo specifications
    cargo_title: Mapped[str] = mapped_column(String(255), nullable=False)
    cargo_type: Mapped[str] = mapped_column(String(128), nullable=False)
    weight_tons: Mapped[float] = mapped_column(Float, nullable=False)
    volume_m3: Mapped[float] = mapped_column(Float, nullable=False)
    price: Mapped[float] = mapped_column(Float, nullable=False) # In UZS or major currency unit
    
    # Escrow & Logistics Progress
    is_escrow_funded: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    distance_km: Mapped[float] = mapped_column(Float, default=300.0, nullable=False)
    eta: Mapped[str] = mapped_column(String(128), default="In Calculation", nullable=False)
    pod_signature_url: Mapped[Optional[str]] = mapped_column(String(512), nullable=True)
    cargo_photos_json: Mapped[Optional[str]] = mapped_column(Text, default="[]", nullable=True) # JSON list of URLs
    
    # POD Receiver Submission Data
    pod_receiver_name: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    pod_receiver_phone: Mapped[Optional[str]] = mapped_column(String(64), nullable=True)
    pod_notes: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    pod_signed_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    pod_signature_strokes: Mapped[Optional[str]] = mapped_column(Text, nullable=True) # JSON points

    # Relationships
    shipper: Mapped["User"] = relationship("User", foreign_keys=[shipper_id])
    bids: Mapped[List["Bid"]] = relationship("Bid", back_populates="shipment", cascade="all, delete-orphan")
    status_history: Mapped[List["ShipmentStatusHistory"]] = relationship("ShipmentStatusHistory", back_populates="shipment", cascade="all, delete-orphan")
    escrow_lock: Mapped[Optional["EscrowLock"]] = relationship("EscrowLock", back_populates="shipment", uselist=False)
    tracking_data: Mapped[Optional["TrackingData"]] = relationship("TrackingData", back_populates="shipment", uselist=False, cascade="all, delete-orphan")

class ShipmentStatusHistory(Base, TimestampMixin):
    __tablename__ = "shipment_status_history"

    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=generate_uuid)
    shipment_id: Mapped[str] = mapped_column(String(64), ForeignKey("shipments.id", ondelete="CASCADE"), nullable=False, index=True)
    from_status: Mapped[Optional[str]] = mapped_column(String(64), nullable=True)
    to_status: Mapped[str] = mapped_column(String(64), nullable=False)
    changed_by_user_id: Mapped[str] = mapped_column(String(64), ForeignKey("users.id"), nullable=False)
    comments: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    shipment: Mapped["Shipment"] = relationship("Shipment", back_populates="status_history")
    changed_by: Mapped["User"] = relationship("User")
