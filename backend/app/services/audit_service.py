from typing import List, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.audit import AuditLog
from app.repositories.dispute_repo import AuditRepository

class AuditService:
    def __init__(self, session: AsyncSession):
        self.session = session
        self.audit_repo = AuditRepository(session)

    async def get_logs(self, skip: int = 0, limit: int = 100) -> List[AuditLog]:
        return await self.audit_repo.get_all(skip=skip, limit=limit, order_by=AuditLog.created_at.desc())
