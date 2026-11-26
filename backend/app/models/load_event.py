from datetime import datetime, timezone
from typing import Any, Dict, Optional
import uuid
import json
from sqlalchemy import DateTime, ForeignKey, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.database.base import Base

def generate_uuid() -> str:
    return str(uuid.uuid4())

class LoadEvent(Base):
    __tablename__ = "load_events"

    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=generate_uuid)
    load_id: Mapped[str] = mapped_column(String(64), ForeignKey("loads.id", ondelete="CASCADE"), nullable=False, index=True)
    event_type: Mapped[str] = mapped_column(String(64), nullable=False, index=True)  # CREATED, EDITED, CANCELLED, STATUS_CHANGED, DUPLICATED
    actor_id: Mapped[Optional[str]] = mapped_column(String(64), ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    payload_json: Mapped[str] = mapped_column(Text, default="{}", nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), nullable=False, index=True)

    load: Mapped["Load"] = relationship("Load", back_populates="events")
    actor: Mapped[Optional["User"]] = relationship("User", foreign_keys=[actor_id])

    @property
    def payload(self) -> Dict[str, Any]:
        if not self.payload_json:
            return {}
        try:
            return json.loads(self.payload_json)
        except Exception:
            return {}

    @payload.setter
    def payload(self, val: Dict[str, Any]):
        self.payload_json = json.dumps(val or {})
