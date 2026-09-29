from datetime import datetime, timezone
import json
from typing import List, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.enums import MessageStatus, MessageType, UserRole
from app.core.exceptions import NotFoundError
from app.models.chat import ChatChannel, ChatMessage
from app.repositories.chat_repo import ChatMessageRepository, ChatRepository
from app.repositories.user_repo import UserRepository
from app.schemas.chat import (
    ChatChannelModel,
    ChatMessageModel,
    LocationPinPayload,
    MediaAttachment,
    ReplySnippet,
    SendMessageRequest,
    VoiceNotePayload,
)

class ChatService:
    def __init__(self, session: AsyncSession):
        self.session = session
        self.chat_repo = ChatRepository(session)
        self.message_repo = ChatMessageRepository(session)
        self.user_repo = UserRepository(session)

    def _to_message_model(self, m: ChatMessage, current_user_id: Optional[str] = None) -> ChatMessageModel:
        voice: Optional[VoiceNotePayload] = None
        if m.voice_payload_json:
            try:
                voice = VoiceNotePayload(**json.loads(m.voice_payload_json))
            except Exception:
                pass

        media: Optional[MediaAttachment] = None
        if m.media_attachment_json:
            try:
                media = MediaAttachment(**json.loads(m.media_attachment_json))
            except Exception:
                pass

        location: Optional[LocationPinPayload] = None
        if m.location_payload_json:
            try:
                location = LocationPinPayload(**json.loads(m.location_payload_json))
            except Exception:
                pass

        reply: Optional[ReplySnippet] = None
        if m.reply_to_json:
            try:
                reply = ReplySnippet(**json.loads(m.reply_to_json))
            except Exception:
                pass

        reactions = {}
        if m.reactions_json:
            try:
                reactions = json.loads(m.reactions_json)
            except Exception:
                reactions = {}

        return ChatMessageModel(
            id=m.id,
            channelId=m.channel_id,
            senderId=m.sender_id,
            senderName=m.sender_name,
            senderRole=UserRole(m.sender_role),
            type=MessageType(m.type),
            content=m.content,
            timestamp=m.created_at,
            isMine=(m.sender_id == current_user_id) if current_user_id else False,
            status=MessageStatus(m.status),
            replyTo=reply,
            reactions=reactions,
            isEdited=m.is_edited,
            isDeleted=m.is_deleted,
            voicePayload=voice,
            mediaAttachment=media,
            locationPayload=location,
        )

    async def get_channels(self, user_id: str) -> List[ChatChannelModel]:
        channels = await self.chat_repo.get_channels_for_user(user_id)
        results: List[ChatChannelModel] = []
        for c in channels:
            results.append(
                ChatChannelModel(
                    id=c.id,
                    shipmentId=c.shipment_id,
                    shipmentTitle=c.shipment_title,
                    trackingCode=c.tracking_code,
                    lastMessage=c.last_message,
                    lastMessageTime=c.last_message_time,
                    unreadCount=0,
                    participantNames=["Shipper", "Driver"],
                    isOnline=c.is_online,
                )
            )
        return results

    async def get_messages(self, channel_id: str, current_user_id: str) -> List[ChatMessageModel]:
        messages = await self.message_repo.get_messages_for_channel(channel_id)
        return [self._to_message_model(m, current_user_id) for m in messages]

    async def send_message(self, channel_id: str, sender_id: str, req: SendMessageRequest) -> ChatMessageModel:
        channel = await self.chat_repo.get_by_id(channel_id)
        if not channel:
            # Check if channel_id is a shipment_id
            channel = await self.chat_repo.get_by_shipment_id(channel_id)
            if not channel:
                raise NotFoundError("Chat channel not found.")

        sender = await self.user_repo.get_by_id(sender_id)
        if not sender:
            raise NotFoundError("User not found.")

        voice_json = json.dumps(req.voice_payload.model_dump(by_alias=True)) if req.voice_payload else None
        media_json = json.dumps(req.media_attachment.model_dump(by_alias=True)) if req.media_attachment else None
        location_json = json.dumps(req.location_payload.model_dump(by_alias=True)) if req.location_payload else None
        reply_json = json.dumps(req.reply_to.model_dump(by_alias=True)) if req.reply_to else None

        msg = ChatMessage(
            channel_id=channel.id,
            sender_id=sender.id,
            sender_name=sender.full_name,
            sender_role=sender.role,
            type=req.type.value,
            content=req.content,
            status=MessageStatus.SENT.value,
            voice_payload_json=voice_json,
            media_attachment_json=media_json,
            location_payload_json=location_json,
            reply_to_json=reply_json,
        )
        await self.message_repo.create(msg)

        channel.last_message = req.content
        channel.last_message_time = datetime.now(timezone.utc)
        await self.session.flush()

        return self._to_message_model(msg, sender_id)
