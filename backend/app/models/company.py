import uuid
from typing import List, Optional
from sqlalchemy import Boolean, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.database.base import Base, TimestampMixin
from app.models.user import generate_uuid

class Company(Base, TimestampMixin):
    __tablename__ = "companies"

    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=generate_uuid)
    name: Mapped[str] = mapped_column(String(255), nullable=False, index=True)
    tax_id_stir: Mapped[Optional[str]] = mapped_column(String(64), unique=True, index=True, nullable=True)
    legal_address: Mapped[Optional[str]] = mapped_column(String(512), nullable=True)
    industry_type: Mapped[Optional[str]] = mapped_column(String(128), nullable=True)
    is_verified: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    owner_id: Mapped[str] = mapped_column(String(64), ForeignKey("users.id"), nullable=False)

    members: Mapped[List["CompanyMember"]] = relationship("CompanyMember", back_populates="company", cascade="all, delete-orphan")
    vehicles: Mapped[List["Vehicle"]] = relationship("Vehicle", back_populates="company")

class CompanyMember(Base, TimestampMixin):
    __tablename__ = "company_members"

    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=generate_uuid)
    company_id: Mapped[str] = mapped_column(String(64), ForeignKey("companies.id", ondelete="CASCADE"), nullable=False)
    user_id: Mapped[str] = mapped_column(String(64), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    role_in_company: Mapped[str] = mapped_column(String(64), default="employee", nullable=False) # owner, manager, dispatcher, driver

    company: Mapped["Company"] = relationship("Company", back_populates="members")
    user: Mapped["User"] = relationship("User")
