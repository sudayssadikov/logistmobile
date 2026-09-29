from datetime import datetime, timezone
from typing import List, Optional
from pydantic import Field
from app.schemas.common import BaseSchema
from app.schemas.bid import BidModel
from app.core.enums import LoadStatus

class LocationPoint(BaseSchema):
    city: str = "Tashkent"
    address: str = "Chilanzar logistics center"
    latitude: float = 41.2995
    longitude: float = 69.2401
    scheduled_time: datetime = Field(default_factory=lambda: datetime.now(timezone.utc), alias="scheduled_time")

class ShipmentModel(BaseSchema):
    id: str
    tracking_code: str = Field(..., alias="tracking_code")
    shipper_id: str = Field(..., alias="shipper_id")
    shipper_name: str = Field(..., alias="shipper_name")
    carrier_id: Optional[str] = Field(None, alias="carrier_id")
    carrier_name: Optional[str] = Field(None, alias="carrier_name")
    driver_name: Optional[str] = Field(None, alias="driver_name")
    driver_phone: Optional[str] = Field(None, alias="driver_phone")
    vehicle_plate: Optional[str] = Field(None, alias="vehicle_plate")
    status: str = Field(LoadStatus.CREATED.value, alias="status")
    origin: LocationPoint
    destination: LocationPoint
    cargo_title: str = Field(..., alias="cargo_title")
    cargo_type: str = Field(..., alias="cargo_type")
    weight_tons: float = Field(..., alias="weight_tons")
    volume_m3: float = Field(..., alias="volume_m3")
    price: float
    is_escrow_funded: bool = Field(False, alias="is_escrow_funded")
    distance_km: float = Field(300.0, alias="distance_km")
    eta: str = "In Transit"
    bids: List[BidModel] = []
    pod_signature_url: Optional[str] = Field(None, alias="pod_signature_url")
    cargo_photos: List[str] = Field([], alias="cargo_photos")
    created_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc), alias="created_at")

class CreateShipmentRequest(BaseSchema):
    origin: LocationPoint
    destination: LocationPoint
    cargo_title: str = Field(..., alias="cargoTitle")
    cargo_type: str = Field(..., alias="cargoType")
    weight_tons: float = Field(..., alias="weightTons")
    volume_m3: float = Field(..., alias="volumeM3")
    price: float
    distance_km: Optional[float] = Field(300.0, alias="distanceKm")
    eta: Optional[str] = "4h 30m"
    cargo_photos: List[str] = Field([], alias="cargoPhotos")

class AdvanceStatusRequest(BaseSchema):
    next_status: LoadStatus = Field(..., alias="nextStatus")
    comments: Optional[str] = None

class MatchedShipmentResponse(BaseSchema):
    shipment: ShipmentModel
    match_percentage: int = Field(..., alias="matchPercentage")
    distance_from_driver_km: float = Field(..., alias="distanceFromDriverKm")
    ai_reason: str = Field(..., alias="aiReason")
    is_return_trip: bool = Field(False, alias="isReturnTrip")
