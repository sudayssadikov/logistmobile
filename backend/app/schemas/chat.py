from datetime import datetime, timezone
from typing import Dict, List, Optional
from pydantic import Field
from app.schemas.common import BaseSchema
from app.core.enums import MessageStatus, MessageType, UserRole

class VoiceNotePayload(BaseSchema):
    duration_seconds: int = Field(..., alias="durationSeconds")
    waveform_samples: List[float] = Field([0.2, 0.5, 0.8, 0.4, 0.9, 0.6], alias="waveformSamples")
    is_played: bool = Field(False, alias="isPlayed")
    playback_speed: float = Field(1.0, alias="playbackSpeed")

class MediaAttachment(BaseSchema):
    url: str
    file_name: str = Field(..., alias="fileName")
    file_size_bytes: int = Field(..., alias="fileSizeBytes")
    mime_type: Optional[str] = Field(None, alias="mimeType")
    extension: Optional[str] = None

class LocationPinPayload(BaseSchema):
    latitude: float
    longitude: float
    title: str
    address: str

class ReplySnippet(BaseSchema):
    message_id: str = Field(..., alias="messageId")
    sender_name: str = Field(..., alias="senderName")
    content: str
    type: MessageType

class ChatMessageModel(BaseSchema):
    id: str
    channel_id: str = Field(..., alias="channelId")
    sender_id: str = Field(..., alias="senderId")
    sender_name: str = Field(..., alias="senderName")
    sender_role: str = Field(UserRole.SHIPPER.value, alias="senderRole")
    type: MessageType = MessageType.TEXT
    content: str
    timestamp: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
    is_mine: bool = Field(False, alias="isMine")
    status: MessageStatus = MessageStatus.READ
    reply_to: Optional[ReplySnippet] = Field(None, alias="replyTo")
    reactions: Dict[str, int] = {}
    is_edited: bool = Field(False, alias="isEdited")
    is_deleted: bool = Field(False, alias="isDeleted")
    voice_payload: Optional[VoiceNotePayload] = Field(None, alias="voicePayload")
    media_attachment: Optional[MediaAttachment] = Field(None, alias="mediaAttachment")
    location_payload: Optional[LocationPinPayload] = Field(None, alias="locationPayload")

class ChatChannelModel(BaseSchema):
    id: str
    shipment_id: str = Field(..., alias="shipmentId")
    shipment_title: str = Field(..., alias="shipmentTitle")
    tracking_code: str = Field(..., alias="trackingCode")
    last_message: str = Field(..., alias="lastMessage")
    last_message_time: datetime = Field(default_factory=lambda: datetime.now(timezone.utc), alias="lastMessageTime")
    unread_count: int = Field(0, alias="unreadCount")
    participant_names: List[str] = Field([], alias="participantNames")
    is_online: bool = Field(True, alias="isOnline")
    typing_indicator: Optional[str] = Field(None, alias="typingIndicator")

class SendMessageRequest(BaseSchema):
    type: MessageType = MessageType.TEXT
    content: str
    reply_to: Optional[ReplySnippet] = Field(None, alias="replyTo")
    voice_payload: Optional[VoiceNotePayload] = Field(None, alias="voicePayload")
    media_attachment: Optional[MediaAttachment] = Field(None, alias="mediaAttachment")
    location_payload: Optional[LocationPinPayload] = Field(None, alias="locationPayload")
