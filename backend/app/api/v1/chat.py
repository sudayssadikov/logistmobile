from typing import List
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from app.dependencies.auth import get_current_user
from app.dependencies.db import get_db
from app.models.user import User
from app.schemas.chat import ChatChannelModel, ChatMessageModel, SendMessageRequest
from app.schemas.common import ApiResponse
from app.services.chat_service import ChatService

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
    return ApiResponse(data=result, message="Message sent")
