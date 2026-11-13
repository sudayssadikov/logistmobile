import os
import uuid
from typing import List, Optional
from fastapi import APIRouter, Depends, File, Form, UploadFile
from sqlalchemy.ext.asyncio import AsyncSession
from app.config.settings import settings
from app.core.enums import MessageType
from app.core.exceptions import AppException
from app.dependencies.auth import get_current_user
from app.dependencies.db import get_db
from app.models.user import User
from app.schemas.chat import (
    ChatChannelModel,
    ChatMessageModel,
    SendMessageRequest,
    VoiceNotePayload,
)
from app.schemas.common import ApiResponse
from app.services.chat_service import ChatService
from app.websocket.connection_manager import ws_manager

router = APIRouter(tags=["Real-time Chat & Channels"])

@router.get("/chat/channels", response_model=ApiResponse[List[ChatChannelModel]])
async def get_channels(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    service = ChatService(db)
    results = await service.get_channels(current_user.id)
    return ApiResponse(data=results)

@router.get("/chat/channels/{channel_id}/messages", response_model=ApiResponse[List[ChatMessageModel]])
@router.get("/chat/{channel_id}", response_model=ApiResponse[List[ChatMessageModel]])
async def get_messages(
    channel_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    service = ChatService(db)
    results = await service.get_messages(channel_id, current_user.id)
    return ApiResponse(data=results)

@router.post("/chat/channels/{channel_id}/messages", response_model=ApiResponse[ChatMessageModel])
@router.post("/chat/{channel_id}", response_model=ApiResponse[ChatMessageModel])
async def send_message(
    channel_id: str,
    req: SendMessageRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    service = ChatService(db)
    result = await service.send_message(channel_id, current_user.id, req)
    
    # Broadcast to WebSocket channel
    await ws_manager.broadcast_to_topic(
        f"chat:{channel_id}",
        {
            "type": "chat_message",
            "channel_id": channel_id,
            "message": result.model_dump(by_alias=True, mode="json"),
        },
    )
    return ApiResponse(data=result, message="Message sent")

@router.post("/chat/channels/{channel_id}/voice", response_model=ApiResponse[ChatMessageModel])
@router.post("/chat/{channel_id}/voice", response_model=ApiResponse[ChatMessageModel])
async def upload_voice_message(
    channel_id: str,
    file: UploadFile = File(...),
    duration: int = Form(1),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    # Max 5MB file check
    content = await file.read()
    if len(content) > 5 * 1024 * 1024:
        raise AppException(
            status_code=400,
            detail="Voice message file size exceeds 5 MB limit.",
            error_code="FILE_TOO_LARGE",
        )

    # Magic Bytes Signature Validation for Genuine Audio Streams
    # Ogg/Opus: b'OggS', MP4/M4A: b'ftyp', MP3: b'ID3' or b'\xff\xfb', WAV: b'RIFF', WebM: b'\x1aE\xdf\xa3'
    is_valid_audio = (
        content.startswith(b"OggS")  # Ogg / Opus
        or (len(content) > 8 and content[4:8] == b"ftyp")  # M4A / AAC / MP4 Audio
        or content.startswith(b"ID3")  # MP3 with ID3 header
        or (len(content) > 2 and content[0] == 0xFF and (content[1] & 0xE0) == 0xE0)  # MP3 Sync word
        or (len(content) > 12 and content[:4] == b"RIFF" and content[8:12] == b"WAVE")  # WAV
        or content.startswith(b"\x1aE\xdf\xa3")  # Matroska / WebM Audio
    )
    if not is_valid_audio:
        raise AppException(
            status_code=400,
            detail="Invalid audio format. File content does not match allowed audio magic bytes (m4a/opus/mp3/wav/webm).",
            error_code="INVALID_AUDIO_FORMAT",
        )

    # Save to storage directory
    upload_dir = os.path.join(settings.STORAGE_DIR, "voice")
    os.makedirs(upload_dir, exist_ok=True)
    
    ext = os.path.splitext(file.filename or "")[1] or ".m4a"
    filename = f"voice_{uuid.uuid4().hex}{ext}"
    filepath = os.path.join(upload_dir, filename)
    with open(filepath, "wb") as f:
        f.write(content)

    voice_url = f"/uploads/voice/{filename}"
    
    # Create chat message
    service = ChatService(db)
    voice_payload = VoiceNotePayload(
        durationSeconds=duration,
        waveformSamples=[0.25, 0.45, 0.8, 0.6, 0.95, 0.7, 0.35, 0.65],
        isPlayed=False,
        playbackSpeed=1.0,
    )
    
    req = SendMessageRequest(
        type=MessageType.VOICE_NOTE,
        content=voice_url,
        voice_payload=voice_payload,
    )
    
    result = await service.send_message(channel_id, current_user.id, req)
    
    # Broadcast to WebSocket
    await ws_manager.broadcast_to_topic(
        f"chat:{channel_id}",
        {
            "type": "chat_message",
            "channel_id": channel_id,
            "message": result.model_dump(by_alias=True, mode="json"),
        },
    )
    return ApiResponse(data=result, message="Voice note uploaded and sent")
