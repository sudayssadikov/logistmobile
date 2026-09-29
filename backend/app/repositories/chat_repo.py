from typing import List, Optional
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload
from app.models.chat import ChatChannel, ChatMessage
from app.repositories.base import BaseRepository

class ChatRepository(BaseRepository[ChatChannel]):
    def __init__(self, session: AsyncSession):
        super().__init__(ChatChannel, session)

    async def get_by_shipment_id(self, shipment_id: str) -> Optional[ChatChannel]:
        stmt = (
            select(ChatChannel)
            .options(selectinload(ChatChannel.messages))
            .where(ChatChannel.shipment_id == shipment_id)
        )
        result = await self.session.execute(stmt)
        return result.scalars().first()

    async def get_channels_for_user(self, user_id: str) -> List[ChatChannel]:
        stmt = (
            select(ChatChannel)
            .options(selectinload(ChatChannel.messages))
            .order_by(ChatChannel.last_message_time.desc())
        )
        result = await self.session.execute(stmt)
        return list(result.scalars().all())

class ChatMessageRepository(BaseRepository[ChatMessage]):
    def __init__(self, session: AsyncSession):
        super().__init__(ChatMessage, session)

    async def get_messages_for_channel(
        self,
        channel_id: str,
        skip: int = 0,
        limit: int = 100,
    ) -> List[ChatMessage]:
        stmt = (
            select(ChatMessage)
            .where(ChatMessage.channel_id == channel_id)
            .order_by(ChatMessage.created_at.asc())
            .offset(skip)
            .limit(limit)
        )
        result = await self.session.execute(stmt)
        return list(result.scalars().all())
