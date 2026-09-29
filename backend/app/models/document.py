from datetime import datetime
from typing import Optional
from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.database.base import Base, TimestampMixin
from app.models.user import generate_uuid
from app.core.enums import DocumentVerificationStatus, LogisticsDocType, UserRole

class Document(Base, TimestampMixin):
    __tablename__ = "documents"

    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=generate_uuid)
    user_id: Mapped[str] = mapped_column(String(64), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    doc_type: Mapped[str] = mapped_column(String(64), default=LogisticsDocType.DRIVER_LICENSE.value, nullable=False)
    doc_number: Mapped[str] = mapped_column(String(128), nullable=False)
    issue_date: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    expiry_date: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    verification_status: Mapped[str] = mapped_column(String(32), default=DocumentVerificationStatus.PENDING_REVIEW.value, nullable=False)
    file_url: Mapped[Optional[str]] = mapped_column(String(512), nullable=True)
    file_name: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    rejection_reason: Mapped[Optional[str]] = mapped_column(String(512), nullable=True)
    user_role: Mapped[str] = mapped_column(String(32), default=UserRole.CARRIER.value, nullable=False)

    user: Mapped["User"] = relationship("User")
