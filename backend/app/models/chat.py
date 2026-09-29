from datetime import datetime, timezone
from typing import List, Optional
from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.database.base import Base, TimestampMixin
from app.models.user import generate_uuid
from app.core.enums import MessageStatus, MessageType, UserRole

class ChatChannel(Base, TimestampMixin):
    __tablename__ = "chat_channels"

    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=generate_uuid)
    shipment_id: Mapped[str] = mapped_column(String(64), ForeignKey("shipments.id"), index=True, nullable=False)
    shipment_title: Mapped[str] = mapped_column(String(255), nullable=False)
    tracking_code: Mapped[str] = mapped_column(String(64), nullable=False)
    last_message: Mapped[str] = mapped_column(String(512), default="Channel created")
    last_message_time: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)
    is_online: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    shipment: Mapped["Shipment"] = relationship("Shipment")
    messages: Mapped[List["ChatMessage"]] = relationship("ChatMessage", back_populates="channel", cascade="all, delete-orphan", order_by="ChatMessage.created_at")

class ChatMessage(Base, TimestampMixin):
    __tablename__ = "chat_messages"

    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=generate_uuid)
    channel_id: Mapped[str] = mapped_column(String(64), ForeignKey("chat_channels.id", ondelete="CASCADE"), nullable=False, index=True)
    sender_id: Mapped[str] = mapped_column(String(64), ForeignKey("users.id"), nullable=False, index=True)
    sender_name: Mapped[str] = mapped_column(String(255), nullable=False)
    sender_role: Mapped[str] = mapped_column(String(32), default=UserRole.SHIPPER.value, nullable=False)
    type: Mapped[str] = mapped_column(String(32), default=MessageType.TEXT.value, nullable=False)
    content: Mapped[str] = mapped_column(Text, nullable=False)
    status: Mapped[str] = mapped_column(String(32), default=MessageStatus.SENT.value, nullable=False)
    
    # Metadata payloads in JSON format
    reply_to_json: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    reactions_json: Mapped[Optional[str]] = mapped_column(Text, default="{}", nullable=True) # e.g. {"👍": 1}
    voice_payload_json: Mapped[Optional[str]] = mapped_column(Text, nullable=True) # {durationSeconds, waveformSamples, ...}
    media_attachment_json: Mapped[Optional[str]] = mapped_column(Text, nullable=True) # {url, fileName, fileSizeBytes, ...}
    location_payload_json: Mapped[Optional[str]] = mapped_column(Text, nullable=True) # {latitude, longitude, title, address}
    is_edited: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    is_deleted: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)

    channel: Mapped["ChatChannel"] = relationship("ChatChannel", back_populates="messages")
    sender: Mapped["User"] = relationship("User")
