from typing import List, Optional
from sqlalchemy import or_, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload
from app.models.shipment import Shipment, ShipmentStatusHistory
from app.models.bid import Bid
from app.repositories.base import BaseRepository

class ShipmentRepository(BaseRepository[Shipment]):
    def __init__(self, session: AsyncSession):
        super().__init__(Shipment, session)

    async def get_with_relations(self, id: str) -> Optional[Shipment]:
        stmt = (
            select(Shipment)
            .options(
                selectinload(Shipment.bids).selectinload(Bid.negotiation_steps),
                selectinload(Shipment.status_history),
                selectinload(Shipment.escrow_lock),
            )
            .where(Shipment.id == id)
        )
        result = await self.session.execute(stmt)
        return result.scalars().first()

    async def get_by_tracking_code(self, tracking_code: str) -> Optional[Shipment]:
        stmt = (
            select(Shipment)
            .options(
                selectinload(Shipment.bids).selectinload(Bid.negotiation_steps),
                selectinload(Shipment.status_history),
            )
            .where(Shipment.tracking_code == tracking_code)
        )
        result = await self.session.execute(stmt)
        return result.scalars().first()

    async def search_shipments(
        self,
        role: Optional[str] = None,
        user_id: Optional[str] = None,
        search_query: Optional[str] = None,
        filter_status: Optional[str] = None,
        skip: int = 0,
        limit: int = 100,
    ) -> List[Shipment]:
        stmt = select(Shipment).options(
            selectinload(Shipment.bids).selectinload(Bid.negotiation_steps),
            selectinload(Shipment.status_history),
        )

        # Role-based query filtering
        if role == "shipper" and user_id:
            stmt = stmt.where(Shipment.shipper_id == user_id)
        elif role == "driver" and user_id:
            stmt = stmt.where(or_(Shipment.driver_id == user_id, Shipment.status.in_(["pendingBid", "created"])))
        elif role == "carrier" and user_id:
            stmt = stmt.where(or_(Shipment.carrier_id == user_id, Shipment.status.in_(["pendingBid", "created"])))

        if filter_status:
            stmt = stmt.where(Shipment.status == filter_status)

        if search_query:
            q = f"%{search_query.strip().lower()}%"
            stmt = stmt.where(
                or_(
                    Shipment.tracking_code.ilike(q),
                    Shipment.cargo_title.ilike(q),
                    Shipment.origin_city.ilike(q),
                    Shipment.dest_city.ilike(q),
                )
            )

        stmt = stmt.order_by(Shipment.created_at.desc()).offset(skip).limit(limit)
        result = await self.session.execute(stmt)
        return list(result.scalars().all())
