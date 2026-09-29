from typing import Optional
from sqlalchemy import or_, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload
from app.models.user import User, UserSession, UserOTP, LoginHistory
from app.repositories.base import BaseRepository

class UserRepository(BaseRepository[User]):
    def __init__(self, session: AsyncSession):
        super().__init__(User, session)

    async def get_by_id(self, id: str) -> Optional[User]:
        stmt = select(User).options(selectinload(User.wallet)).where(User.id == id)
        result = await self.session.execute(stmt)
        return result.scalars().first()

    async def get_by_email(self, email: str) -> Optional[User]:
        stmt = select(User).options(selectinload(User.wallet)).where(User.email == email.strip().lower())
        result = await self.session.execute(stmt)
        return result.scalars().first()

    async def get_by_phone(self, phone: str) -> Optional[User]:
        clean_phone = phone.strip().replace(" ", "")
        stmt = select(User).options(selectinload(User.wallet)).where(User.phone == clean_phone)
        result = await self.session.execute(stmt)
        return result.scalars().first()

    async def get_by_email_or_phone(self, identifier: str) -> Optional[User]:
        clean_input = identifier.strip().lower()
        clean_phone = identifier.strip().replace(" ", "")
        stmt = select(User).options(selectinload(User.wallet)).where(
            or_(
                User.email == clean_input,
                User.phone == clean_phone,
            )
        )
        result = await self.session.execute(stmt)
        return result.scalars().first()

class SessionRepository(BaseRepository[UserSession]):
    def __init__(self, session: AsyncSession):
        super().__init__(UserSession, session)

    async def get_by_refresh_token(self, token: str) -> Optional[UserSession]:
        stmt = select(UserSession).where(UserSession.refresh_token == token, UserSession.is_active == True)
        result = await self.session.execute(stmt)
        return result.scalars().first()

    async def get_active_sessions_for_user(self, user_id: str) -> list[UserSession]:
        stmt = select(UserSession).where(UserSession.user_id == user_id, UserSession.is_active == True)
        result = await self.session.execute(stmt)
        return list(result.scalars().all())

    async def deactivate_all_for_user(self, user_id: str) -> None:
        stmt = select(UserSession).where(UserSession.user_id == user_id, UserSession.is_active == True)
        result = await self.session.execute(stmt)
        for s in result.scalars().all():
            s.is_active = False
        await self.session.flush()

class OTPRepository(BaseRepository[UserOTP]):
    def __init__(self, session: AsyncSession):
        super().__init__(UserOTP, session)

    async def get_latest_valid_otp(self, phone: str) -> Optional[UserOTP]:
        clean_phone = phone.strip().replace(" ", "")
        stmt = (
            select(UserOTP)
            .where(UserOTP.phone == clean_phone, UserOTP.is_used == False)
            .order_by(UserOTP.created_at.desc())
        )
        result = await self.session.execute(stmt)
        return result.scalars().first()
