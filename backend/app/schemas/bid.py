from datetime import datetime, timezone
from typing import List, Optional
from pydantic import Field
from app.schemas.common import BaseSchema
from app.core.enums import BidNegotiationStatus

class NegotiationStep(BaseSchema):
    id: str
    author_role: str = Field(..., alias="author_role")
    author_name: str = Field(..., alias="author_name")
    proposed_price: float = Field(..., alias="proposed_price")
    comment: Optional[str] = None
    timestamp: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))

class BidModel(BaseSchema):
    id: str
    carrier_id: str = Field(..., alias="carrier_id")
    carrier_name: str = Field(..., alias="carrier_name")
    driver_name: str = Field(..., alias="driver_name")
    vehicle_model: str = Field(..., alias="vehicle_model")
    plate_number: str = Field(..., alias="plate_number")
    bid_amount: float = Field(..., alias="bid_amount")
    counter_price: Optional[float] = Field(None, alias="counter_price")
    negotiation_status: str = Field(BidNegotiationStatus.PENDING.value, alias="negotiation_status")
    negotiation_history: List[NegotiationStep] = Field([], alias="negotiation_history")
    carrier_rating: float = Field(5.0, alias="carrier_rating")
    created_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc), alias="created_at")
    is_accepted: bool = Field(False, alias="is_accepted")

class SubmitBidRequest(BaseSchema):
    driver_name: Optional[str] = Field(None, alias="driverName")
    vehicle_model: Optional[str] = Field(None, alias="vehicleModel")
    plate_number: Optional[str] = Field(None, alias="plateNumber")
    bid_amount: float = Field(..., alias="bidAmount")
    counter_price: Optional[float] = Field(None, alias="counterPrice")
    comment: Optional[str] = None

class CounterBidRequest(BaseSchema):
    counter_price: float = Field(..., alias="counterPrice")
    comment: Optional[str] = None
