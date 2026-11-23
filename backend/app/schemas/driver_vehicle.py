from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, ConfigDict, Field, field_validator
from app.core.enums import TruckType

class DriverVehicleCreate(BaseModel):
    truck_type: TruckType
    capacity_tons: float = Field(..., gt=0.0, le=100.0)
    plate_number: Optional[str] = Field(None, max_length=64)
    is_primary: bool = True

class DriverVehicleResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    driver_id: str
    truck_type: str
    capacity_tons: float
    plate_number: Optional[str] = None
    is_primary: bool
    created_at: datetime
    updated_at: datetime

class DriverPreferencesUpdate(BaseModel):
    home_region: Optional[str] = None
    preferred_from_regions: Optional[List[str]] = None
    preferred_to_regions: Optional[List[str]] = None
    min_price_uzs: Optional[float] = Field(None, ge=0)

class DriverPreferencesResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    driver_id: str
    home_region: str
    preferred_from_regions: List[str]
    preferred_to_regions: List[str]
    min_price_uzs: Optional[float] = None
    current_lat: Optional[float] = None
    current_lng: Optional[float] = None
    location_updated_at: Optional[datetime] = None

class DriverLocationUpdate(BaseModel):
    lat: float = Field(..., ge=-90.0, le=90.0)
    lng: float = Field(..., ge=-180.0, le=180.0)
    updated_at: Optional[datetime] = None

class DriverFeedItem(BaseModel):
    id: str
    cargo_name: str
    cargo_type: str
    weight_tons: float
    volume_m3: Optional[float] = None
    truck_type: str
    from_address: str
    from_region: str
    from_city: str
    from_lat: float
    from_lng: float
    to_address: str
    to_region: str
    to_city: str
    to_lat: float
    to_lng: float
    distance_km: float
    pickup_date: datetime
    price_uzs: Optional[float] = None
    price_negotiable: bool
    description: Optional[str] = None
    photos: List[str] = []
    
    # Matching metadata
    match_percent: int
    match_reasons: List[str] = []
    pickup_distance_km: Optional[float] = None
    already_offered: bool = False
    created_at: datetime

class DriverFeedResponse(BaseModel):
    items: List[DriverFeedItem]
    has_vehicle: bool
    total: int
