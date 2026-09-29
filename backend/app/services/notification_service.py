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
        if not notifs:
            # Seed default notifications
            n1 = Notification(
                user_id=user_id,
                title="Yangi yuk taklifi qabul qilindi",
                body="Trans Logistics sizning LF-UZ-8921 reysingiz bo'yicha taklifingizni qabul qildi.",
                category=NotificationCategory.SHIPMENTS.value,
                action_route="/shipments/SHP-1001",
            )
            n2 = Notification(
                user_id=user_id,
                title="Eskrou hisobiga mablag' tushdi",
                body="16,500,000 UZS miqdoridagi to'lov kafolatli eskrou hisobiga muzlatildi.",
                category=NotificationCategory.PAYMENTS.value,
                action_route="/wallet",
            )
            self.session.add_all([n1, n2])
            await self.session.flush()
            notifs = [n1, n2]

        return [self._to_model(n) for n in notifs]

    async def mark_all_as_read(self, user_id: str) -> None:
        await self.notif_repo.mark_all_as_read(user_id)

    async def register_device_token(self, user_id: str, req: DeviceTokenRegister) -> bool:
        token = DeviceToken(user_id=user_id, token=req.token, platform=req.platform)
        self.session.add(token)
        await self.session.flush()
        return True
