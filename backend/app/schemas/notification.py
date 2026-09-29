from datetime import datetime, timezone
from typing import Optional
from pydantic import Field
from app.schemas.common import BaseSchema
from app.core.enums import NotificationCategory

class NotificationModel(BaseSchema):
    id: str
    title: str
    body: str
    category: NotificationCategory = NotificationCategory.SHIPMENTS
    created_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc), alias="createdAt")
    is_read: bool = Field(False, alias="isRead")
    action_route: Optional[str] = Field(None, alias="actionRoute")

class DeviceTokenRegister(BaseSchema):
    token: str
    platform: str = "android" # android, ios, web
