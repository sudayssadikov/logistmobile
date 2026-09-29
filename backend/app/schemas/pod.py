from datetime import datetime, timezone
from typing import Any, List, Optional
from pydantic import Field
from app.schemas.common import BaseSchema

class PodSubmissionModel(BaseSchema):
    shipment_id: str = Field(..., alias="shipmentId")
    receiver_name: str = Field(..., alias="receiverName")
    receiver_phone: str = Field(..., alias="receiverPhone")
    notes: str = ""
    signed_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc), alias="signedAt")
    latitude: float
    longitude: float
    cargo_photos: List[str] = Field([], alias="cargoPhotos")
    signature_strokes: List[Any] = Field([], alias="signatureStrokes") # List of stroke coordinate points
    is_approved: bool = Field(True, alias="isApproved")
