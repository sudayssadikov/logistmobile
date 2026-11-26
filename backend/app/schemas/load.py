from datetime import datetime, timezone, timedelta
from typing import List, Optional
import math
from pydantic import Field, field_validator, model_validator
from app.schemas.common import BaseSchema
from app.core.enums import CargoType, LoadStatus, TruckType

def haversine_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    R = 6371.0  # Earth radius in kilometers
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = (
        math.sin(dlat / 2.0) ** 2
        + math.cos(math.radians(lat1))
        * math.cos(math.radians(lat2))
        * math.sin(dlon / 2.0) ** 2
    )
    c = 2.0 * math.atan2(math.sqrt(a), math.sqrt(1.0 - a))
    return round(R * c, 2)

class CreateLoadRequest(BaseSchema):
    cargo_name: str = Field(..., min_length=2, max_length=255, alias="cargoName")
    cargo_type: CargoType = Field(CargoType.BOSHQA, alias="cargoType")
    weight_tons: float = Field(..., ge=0.1, le=60.0, alias="weightTons")
    volume_m3: Optional[float] = Field(None, ge=0.1, le=200.0, alias="volumeM3")
    truck_type: TruckType = Field(TruckType.TENT, alias="truckType")

    # Origin
    from_lat: float = Field(..., ge=-90.0, le=90.0, alias="fromLat")
    from_lng: float = Field(..., ge=-180.0, le=180.0, alias="fromLng")
    from_address: str = Field(..., min_length=3, max_length=512, alias="fromAddress")
    from_region: str = Field(..., min_length=2, max_length=128, alias="fromRegion")
    from_city: str = Field(..., min_length=2, max_length=128, alias="fromCity")

    # Destination
    to_lat: float = Field(..., ge=-90.0, le=90.0, alias="toLat")
    to_lng: float = Field(..., ge=-180.0, le=180.0, alias="toLng")
    to_address: str = Field(..., min_length=3, max_length=512, alias="toAddress")
    to_region: str = Field(..., min_length=2, max_length=128, alias="toRegion")
    to_city: str = Field(..., min_length=2, max_length=128, alias="toCity")

    pickup_date: datetime = Field(..., alias="pickupDate")
    price_uzs: Optional[float] = Field(None, ge=0.0, alias="priceUzs")
    price_negotiable: bool = Field(False, alias="priceNegotiable")
    description: Optional[str] = Field(None, max_length=500)
    photos: List[str] = Field(default_factory=list, max_length=5)

    @field_validator("pickup_date")
    @classmethod
    def validate_pickup_date(cls, v: datetime) -> datetime:
        # Convert to UTC or naive comparable
        now = datetime.now(timezone.utc)
        target = v if v.tzinfo else v.replace(tzinfo=timezone.utc)
        # Allow 15 minutes grace period for clock drift
        if target < now - timedelta(minutes=15):
            raise ValueError("Olib ketish sanasi o'tmishda bo'lishi mumkin emas.")
        return v

    @model_validator(mode="after")
    def validate_rules(self) -> "CreateLoadRequest":
        # 1. Distance rule: kamida 1 km farq
        dist = haversine_distance(self.from_lat, self.from_lng, self.to_lat, self.to_lng)
        if dist < 1.0:
            raise ValueError("Yuk ortish va yetkazish joylari orasidagi masofa kamida 1 km bo'lishi kerak.")

        # 2. Pricing rule: narx kiritilgan YOKI "kelishiladi" belgilangan bo'lishi shart
        if not self.price_negotiable and (self.price_uzs is None or self.price_uzs <= 0):
            raise ValueError("Narx kiritilishi yoki 'Narx kelishiladi' belgisi yoqilgan bo'lishi shart.")

        return self

class LoadResponse(BaseSchema):
    id: str
    shipper_id: str = Field(..., alias="shipperId")
    status: str
    cargo_name: str = Field(..., alias="cargoName")
    cargo_type: str = Field(..., alias="cargoType")
    weight_tons: float = Field(..., alias="weightTons")
    volume_m3: Optional[float] = Field(None, alias="volumeM3")
    truck_type: str = Field(..., alias="truckType")

    from_lat: float = Field(..., alias="fromLat")
    from_lng: float = Field(..., alias="fromLng")
    from_address: str = Field(..., alias="fromAddress")
    from_region: str = Field(..., alias="fromRegion")
    from_city: str = Field(..., alias="fromCity")

    to_lat: float = Field(..., alias="toLat")
    to_lng: float = Field(..., alias="toLng")
    to_address: str = Field(..., alias="toAddress")
    to_region: str = Field(..., alias="toRegion")
    to_city: str = Field(..., alias="toCity")

    distance_km: float = Field(..., alias="distanceKm")
    pickup_date: datetime = Field(..., alias="pickupDate")
    price_uzs: Optional[float] = Field(None, alias="priceUzs")
    price_negotiable: bool = Field(..., alias="priceNegotiable")
    description: Optional[str] = None
    photos: List[str] = []
    created_at: datetime = Field(..., alias="createdAt")
    updated_at: datetime = Field(..., alias="updatedAt")

class UpdateLoadRequest(BaseSchema):
    updated_at: datetime = Field(..., alias="updatedAt", description="Optimistic concurrency check timestamp")
    cargo_name: Optional[str] = Field(None, min_length=2, max_length=255, alias="cargoName")
    cargo_type: Optional[CargoType] = Field(None, alias="cargoType")
    weight_tons: Optional[float] = Field(None, ge=0.1, le=60.0, alias="weightTons")
    volume_m3: Optional[float] = Field(None, ge=0.1, le=200.0, alias="volumeM3")
    truck_type: Optional[TruckType] = Field(None, alias="truckType")

    from_lat: Optional[float] = Field(None, ge=-90.0, le=90.0, alias="fromLat")
    from_lng: Optional[float] = Field(None, ge=-180.0, le=180.0, alias="fromLng")
    from_address: Optional[str] = Field(None, min_length=3, max_length=512, alias="fromAddress")
    from_region: Optional[str] = Field(None, min_length=2, max_length=128, alias="fromRegion")
    from_city: Optional[str] = Field(None, min_length=2, max_length=128, alias="fromCity")

    to_lat: Optional[float] = Field(None, ge=-90.0, le=90.0, alias="toLat")
    to_lng: Optional[float] = Field(None, ge=-180.0, le=180.0, alias="toLng")
    to_address: Optional[str] = Field(None, min_length=3, max_length=512, alias="toAddress")
    to_region: Optional[str] = Field(None, min_length=2, max_length=128, alias="toRegion")
    to_city: Optional[str] = Field(None, min_length=2, max_length=128, alias="toCity")

    pickup_date: Optional[datetime] = Field(None, alias="pickupDate")
    price_uzs: Optional[float] = Field(None, ge=0.0, alias="priceUzs")
    price_negotiable: Optional[bool] = Field(None, alias="priceNegotiable")
    description: Optional[str] = Field(None, max_length=500)
    photos: Optional[List[str]] = Field(None, max_length=5)

class CancelLoadRequest(BaseSchema):
    reason: Optional[str] = Field(None, max_length=500)

class LoadSummaryResponse(BaseSchema):
    id: str
    cargo_name: str = Field(..., alias="cargoName")
    cargo_type: str = Field(..., alias="cargoType")
    weight_tons: float = Field(..., alias="weightTons")
    truck_type: str = Field(..., alias="truckType")
    from_city: str = Field(..., alias="fromCity")
    from_region: str = Field(..., alias="fromRegion")
    to_city: str = Field(..., alias="toCity")
    to_region: str = Field(..., alias="toRegion")
    price_uzs: Optional[float] = Field(None, alias="priceUzs")
    price_negotiable: bool = Field(..., alias="priceNegotiable")
    status: str
    pickup_date: datetime = Field(..., alias="pickupDate")
    created_at: datetime = Field(..., alias="createdAt")
    updated_at: datetime = Field(..., alias="updatedAt")

class PaginatedLoadSummaryResponse(BaseSchema):
    items: List[LoadSummaryResponse]
    total: int
    page: int
    limit: int
    pages: int

class LoadEventResponse(BaseSchema):
    id: str
    load_id: str = Field(..., alias="loadId")
    event_type: str = Field(..., alias="eventType")
    actor_id: Optional[str] = Field(None, alias="actorId")
    payload: dict
    created_at: datetime = Field(..., alias="createdAt")


