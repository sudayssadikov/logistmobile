from typing import List, Optional
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload
from app.models.dispute import Dispute, DisputeTimeline
from app.models.document import Document
from app.models.vehicle import Vehicle
from app.models.driver import DriverProfile
from app.models.notification import Notification, DeviceToken
from app.models.sos import SosProvider, SosRequest
from app.models.audit import AuditLog
from app.repositories.base import BaseRepository

class DisputeRepository(BaseRepository[Dispute]):
    def __init__(self, session: AsyncSession):
        super().__init__(Dispute, session)

    async def get_with_timeline(self, dispute_id: str) -> Optional[Dispute]:
        stmt = (
            select(Dispute)
            .options(selectinload(Dispute.timeline))
            .where(Dispute.id == dispute_id)
        )
        result = await self.session.execute(stmt)
        return result.scalars().first()

    async def get_all_with_timeline(self, claimant_id: Optional[str] = None) -> List[Dispute]:
        stmt = select(Dispute).options(selectinload(Dispute.timeline))
        if claimant_id:
            stmt = stmt.where(Dispute.claimant_id == claimant_id)
        stmt = stmt.order_by(Dispute.created_at.desc())
        result = await self.session.execute(stmt)
        return list(result.scalars().all())

class DocumentRepository(BaseRepository[Document]):
    def __init__(self, session: AsyncSession):
        super().__init__(Document, session)

    async def get_by_user_id(self, user_id: str) -> List[Document]:
        stmt = select(Document).where(Document.user_id == user_id).order_by(Document.created_at.desc())
        result = await self.session.execute(stmt)
        return list(result.scalars().all())

class VehicleRepository(BaseRepository[Vehicle]):
    def __init__(self, session: AsyncSession):
        super().__init__(Vehicle, session)

    async def get_by_plate(self, plate: str) -> Optional[Vehicle]:
        stmt = select(Vehicle).where(Vehicle.plate_number == plate)
        result = await self.session.execute(stmt)
        return result.scalars().first()

class DriverProfileRepository(BaseRepository[DriverProfile]):
    def __init__(self, session: AsyncSession):
        super().__init__(DriverProfile, session)

    async def get_by_user_id(self, user_id: str) -> Optional[DriverProfile]:
        stmt = select(DriverProfile).where(DriverProfile.user_id == user_id)
        result = await self.session.execute(stmt)
        return result.scalars().first()

class NotificationRepository(BaseRepository[Notification]):
    def __init__(self, session: AsyncSession):
        super().__init__(Notification, session)

    async def get_for_user(self, user_id: str, category: Optional[str] = None) -> List[Notification]:
        stmt = select(Notification).where(Notification.user_id == user_id)
        if category and category != "all":
            stmt = stmt.where(Notification.category == category)
        stmt = stmt.order_by(Notification.created_at.desc())
        result = await self.session.execute(stmt)
        return list(result.scalars().all())

    async def mark_all_as_read(self, user_id: str) -> None:
        stmt = select(Notification).where(Notification.user_id == user_id, Notification.is_read == False)
        result = await self.session.execute(stmt)
        for n in result.scalars().all():
            n.is_read = True
        await self.session.flush()

class SosRepository(BaseRepository[SosRequest]):
    def __init__(self, session: AsyncSession):
        super().__init__(SosRequest, session)

    async def get_active_providers(self) -> List[SosProvider]:
        stmt = select(SosProvider).where(SosProvider.is_active == True)
        result = await self.session.execute(stmt)
        return list(result.scalars().all())

class AuditRepository(BaseRepository[AuditLog]):
    def __init__(self, session: AsyncSession):
        super().__init__(AuditLog, session)

    async def log_event(
        self,
        action: str,
        resource_type: str,
        resource_id: Optional[str] = None,
        user_id: Optional[str] = None,
        ip_address: str = "127.0.0.1",
        user_agent: str = "Client",
        changes: Optional[str] = None,
        status: str = "SUCCESS",
    ) -> AuditLog:
        log = AuditLog(
            action=action,
            resource_type=resource_type,
            resource_id=resource_id,
            user_id=user_id,
            ip_address=ip_address,
            user_agent=user_agent,
            changes_json=changes,
            status=status,
        )
        self.session.add(log)
        await self.session.flush()
        return log
