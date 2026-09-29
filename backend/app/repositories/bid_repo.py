from typing import List, Optional
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload
from app.models.bid import Bid, NegotiationStep
from app.repositories.base import BaseRepository

class BidRepository(BaseRepository[Bid]):
    def __init__(self, session: AsyncSession):
        super().__init__(Bid, session)

    async def get_by_shipment_id(self, shipment_id: str) -> List[Bid]:
        stmt = (
            select(Bid)
            .options(selectinload(Bid.negotiation_steps))
            .where(Bid.shipment_id == shipment_id)
            .order_by(Bid.created_at.desc())
        )
        result = await self.session.execute(stmt)
        return list(result.scalars().all())

    async def get_with_steps(self, bid_id: str) -> Optional[Bid]:
        stmt = (
            select(Bid)
            .options(selectinload(Bid.negotiation_steps))
            .where(Bid.id == bid_id)
        )
        result = await self.session.execute(stmt)
        return result.scalars().first()
