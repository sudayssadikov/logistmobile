from datetime import datetime
from typing import Optional
from pydantic import Field
from app.schemas.common import BaseSchema
from app.core.enums import SosServiceType

class NearbySosProvider(BaseSchema):
    id: str
    name: str
    type: SosServiceType
    phone: str
    distance_km: float = Field(..., alias="distanceKm")
    rating: float = 4.9
    address: str
    is_24_7: bool = Field(True, alias="is24_7")
    estimated_arrival_minutes: str = Field(..., alias="estimatedArrivalMinutes")

class TriggerSosRequest(BaseSchema):
    service_type: SosServiceType = Field(..., alias="serviceType")
    latitude: float
    longitude: float
    description: Optional[str] = None
    shipment_id: Optional[str] = Field(None, alias="shipmentId")

class SosRequestResponse(BaseSchema):
    id: str
    driver_id: str
    service_type: str
    latitude: float
    longitude: float
    description: Optional[str] = None
    is_resolved: bool
    created_at: datetime
