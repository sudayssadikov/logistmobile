from datetime import datetime, timezone
from typing import List, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.enums import NotificationCategory
from app.models.notification import DeviceToken, Notification
from app.repositories.dispute_repo import NotificationRepository
from app.schemas.notification import DeviceTokenRegister, NotificationModel

class NotificationService:
    def __init__(self, session: AsyncSession):
        self.session = session
        self.notif_repo = NotificationRepository(session)

    def _to_model(self, n: Notification) -> NotificationModel:
        return NotificationModel(
            id=n.id,
            title=n.title,
            body=n.body,
            category=NotificationCategory(n.category),
            createdAt=n.created_at,
            isRead=n.is_read,
            actionRoute=n.action_route,
        )

    async def get_user_notifications(self, user_id: str, category: Optional[str] = None) -> List[NotificationModel]:
        notifs = await self.notif_repo.get_for_user(user_id, category)
        return [self._to_model(n) for n in notifs]

    async def mark_as_read(self, notif_id: str, user_id: str) -> None:
        notif = await self.notif_repo.get_by_id(notif_id)
        if notif and notif.user_id == user_id:
            notif.is_read = True
            await self.session.flush()

    async def mark_all_as_read(self, user_id: str) -> None:
        await self.notif_repo.mark_all_as_read(user_id)

    async def register_device_token(self, user_id: str, req: DeviceTokenRegister) -> bool:
        token = DeviceToken(user_id=user_id, token=req.token, platform=req.platform)
        self.session.add(token)
        await self.session.flush()
        return True

    async def create_notification(
        self,
        user_id: str,
        title: str,
        body: str,
        category: NotificationCategory = NotificationCategory.SHIPMENTS,
        action_route: Optional[str] = None,
    ) -> NotificationModel:
        notif = Notification(
            user_id=user_id,
            title=title,
            body=body,
            category=category.value if isinstance(category, NotificationCategory) else str(category),
            action_route=action_route,
            is_read=False,
        )
        self.session.add(notif)
        await self.session.flush()
        return self._to_model(notif)
