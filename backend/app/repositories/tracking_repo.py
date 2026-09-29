from typing import List, Optional
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload
from app.models.tracking import TrackingData, TelemetryLog
from app.repositories.base import BaseRepository

class TrackingRepository(BaseRepository[TrackingData]):
    def __init__(self, session: AsyncSession):
        super().__init__(TrackingData, session)

    async def get_by_shipment_id(self, shipment_id: str) -> Optional[TrackingData]:
        stmt = (
            select(TrackingData)
            .options(selectinload(TrackingData.telemetry_history))
            .where(TrackingData.shipment_id == shipment_id)
        )
        result = await self.session.execute(stmt)
        return result.scalars().first()

class TelemetryLogRepository(BaseRepository[TelemetryLog]):
    def __init__(self, session: AsyncSession):
        super().__init__(TelemetryLog, session)

    async def get_history_for_tracking(self, tracking_id: str, limit: int = 200) -> List[TelemetryLog]:
        stmt = (
            select(TelemetryLog)
            .where(TelemetryLog.tracking_id == tracking_id)
            .order_by(TelemetryLog.timestamp.desc())
            .limit(limit)
        )
        result = await self.session.execute(stmt)
        return list(result.scalars().all())
