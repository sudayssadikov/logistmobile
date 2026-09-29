from datetime import datetime, timezone
from typing import List, Optional
import uuid
from sqlalchemy import Boolean, DateTime, Float, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.database.base import Base, TimestampMixin
from app.core.enums import UserRole

def generate_uuid() -> str:
    return str(uuid.uuid4())

class User(Base, TimestampMixin):
    __tablename__ = "users"

    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=generate_uuid)
    full_name: Mapped[str] = mapped_column(String(255), nullable=False, index=True)
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True, nullable=False)
    phone: Mapped[str] = mapped_column(String(64), unique=True, index=True, nullable=False)
    hashed_password: Mapped[str] = mapped_column(String(255), nullable=False)
    role: Mapped[str] = mapped_column(String(32), default=UserRole.SHIPPER.value, nullable=False, index=True)
    
    # Profile & Identity
    company_name: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    avatar_url: Mapped[Optional[str]] = mapped_column(String(512), nullable=True)
    is_verified: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    is_superuser: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    
    # Metrics
    rating: Mapped[float] = mapped_column(Float, default=5.0, nullable=False)
    completed_trips: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    
    # Financial & Vehicle Details
    vehicle_model: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    vehicle_plate: Mapped[Optional[str]] = mapped_column(String(64), nullable=True)
    driver_license_number: Mapped[Optional[str]] = mapped_column(String(64), nullable=True)
    bank_card_number: Mapped[Optional[str]] = mapped_column(String(64), nullable=True)
    
    # Security preferences
    is_biometric_enabled: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    is_2fa_enabled: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    failed_login_attempts: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    locked_until: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    
    # Relationships
    sessions: Mapped[List["UserSession"]] = relationship("UserSession", back_populates="user", cascade="all, delete-orphan")
    login_history: Mapped[List["LoginHistory"]] = relationship("LoginHistory", back_populates="user", cascade="all, delete-orphan")
    wallet: Mapped[Optional["Wallet"]] = relationship("Wallet", back_populates="user", uselist=False, lazy="selectin", cascade="all, delete-orphan")

class UserSession(Base, TimestampMixin):
    __tablename__ = "user_sessions"

    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=generate_uuid)
    user_id: Mapped[str] = mapped_column(String(64), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    refresh_token: Mapped[str] = mapped_column(String(512), unique=True, index=True, nullable=False)
    device_model: Mapped[str] = mapped_column(String(255), default="Unknown Device")
    ip_address: Mapped[str] = mapped_column(String(64), default="127.0.0.1")
    location: Mapped[str] = mapped_column(String(255), default="Tashkent, Uzbekistan")
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    last_active: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)

    user: Mapped["User"] = relationship("User", back_populates="sessions")

class LoginHistory(Base, TimestampMixin):
    __tablename__ = "login_history"

    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=generate_uuid)
    user_id: Mapped[str] = mapped_column(String(64), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    ip_address: Mapped[str] = mapped_column(String(64), nullable=False)
    user_agent: Mapped[str] = mapped_column(String(512), nullable=False)
    is_successful: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    failure_reason: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)

    user: Mapped["User"] = relationship("User", back_populates="login_history")

class UserOTP(Base, TimestampMixin):
    __tablename__ = "user_otps"

    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=generate_uuid)
    phone: Mapped[str] = mapped_column(String(64), index=True, nullable=False)
    code: Mapped[str] = mapped_column(String(16), nullable=False)
    is_used: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    attempts: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
