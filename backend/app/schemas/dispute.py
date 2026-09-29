from datetime import datetime, timezone
from typing import List, Optional
from pydantic import Field
from app.schemas.common import BaseSchema
from app.core.enums import DisputeReason, DisputeStatus

class DisputeTimelineItem(BaseSchema):
    status: str
    message: str
    timestamp: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))

class DisputeModel(BaseSchema):
    id: str
    shipment_id: str = Field(..., alias="shipmentId")
    tracking_code: str = Field(..., alias="trackingCode")
    claimant_name: str = Field(..., alias="claimantName")
    reason: str
    description: str
    claim_amount: float = Field(..., alias="claimAmount")
    evidence_photos: List[str] = Field([], alias="evidencePhotos")
    status: str = Field(DisputeStatus.UNDER_REVIEW.value, alias="status")
    timeline: List[DisputeTimelineItem] = []
    created_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc), alias="createdAt")

class CreateDisputeRequest(BaseSchema):
    shipment_id: str = Field(..., alias="shipmentId")
    tracking_code: Optional[str] = Field(None, alias="trackingCode")
    reason: DisputeReason
    description: str
    claim_amount: float = Field(..., alias="claimAmount")
    evidence_photos: List[str] = Field([], alias="evidencePhotos")

class ResolveDisputeRequest(BaseSchema):
    status: DisputeStatus
    resolution_message: str = Field(..., alias="resolutionMessage")
    refund_amount: Optional[float] = Field(None, alias="refundAmount")
