from datetime import datetime, timezone
from typing import Optional
from pydantic import Field
from app.schemas.common import BaseSchema
from app.core.enums import CallDirection, CallStatus, CallType, UserRole

class CallSessionModel(BaseSchema):
    id: str
    shipment_id: Optional[str] = Field(None, alias="shipmentId")
    caller_id: str = Field(..., alias="callerId")
    caller_name: str = Field(..., alias="callerName")
    caller_role: str = Field(UserRole.SHIPPER.value, alias="callerRole")
    caller_avatar: Optional[str] = Field(None, alias="callerAvatar")
    receiver_id: str = Field(..., alias="receiverId")
    receiver_name: str = Field(..., alias="receiverName")
    receiver_role: str = Field(UserRole.DRIVER.value, alias="receiverRole")
    receiver_avatar: Optional[str] = Field(None, alias="receiverAvatar")
    type: CallType = CallType.AUDIO
    status: CallStatus = CallStatus.IDLE
    direction: CallDirection = CallDirection.OUTGOING
    started_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc), alias="startedAt")
    connected_at: Optional[datetime] = Field(None, alias="connectedAt")
    ended_at: Optional[datetime] = Field(None, alias="endedAt")
    duration_seconds: int = Field(0, alias="durationSeconds")
    is_mic_muted: bool = Field(False, alias="isMicMuted")
    is_speaker_on: bool = Field(False, alias="isSpeakerOn")
    is_video_enabled: bool = Field(True, alias="isVideoEnabled")
    is_front_camera: bool = Field(True, alias="isFrontCamera")
    network_quality: str = Field("HD Excellent", alias="networkQuality")
    codec: str = "Opus 48kHz (End-to-End Encrypted)"

class CallLogModel(BaseSchema):
    id: str
    participant_name: str = Field(..., alias="participantName")
    participant_role: str = Field(UserRole.DRIVER.value, alias="participantRole")
    participant_phone: Optional[str] = Field(None, alias="participantPhone")
    type: CallType = CallType.AUDIO
    direction: CallDirection = CallDirection.INCOMING
    outcome: CallStatus = CallStatus.ACTIVE
    duration_seconds: int = Field(0, alias="durationSeconds")
    timestamp: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))

class InitiateCallRequest(BaseSchema):
    receiver_id: str = Field(..., alias="receiverId")
    shipment_id: Optional[str] = Field(None, alias="shipmentId")
    type: CallType = CallType.AUDIO

class UpdateCallStatusRequest(BaseSchema):
    status: CallStatus
    duration_seconds: Optional[int] = Field(None, alias="durationSeconds")
