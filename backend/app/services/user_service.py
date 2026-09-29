from typing import Optional
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.exceptions import NotFoundError
from app.models.user import User
from app.repositories.user_repo import UserRepository
from app.repositories.wallet_repo import WalletRepository
from app.schemas.user import UserModel, UserUpdate

class UserService:
    def __init__(self, session: AsyncSession):
        self.session = session
        self.user_repo = UserRepository(session)
        self.wallet_repo = WalletRepository(session)

    async def get_user_by_id(self, user_id: str) -> UserModel:
        user = await self.user_repo.get_by_id(user_id)
        if not user:
            raise NotFoundError("User not found.")
        wallet = await self.wallet_repo.get_by_user_id(user_id)
        balance = wallet.available_balance if wallet else 0.0
        return UserModel(
            id=user.id,
            full_name=user.full_name,
            email=user.email,
            phone=user.phone,
            role=user.role,
            company_name=user.company_name,
            avatar_url=user.avatar_url,
            is_verified=user.is_verified,
            rating=user.rating,
            completed_trips=user.completed_trips,
            wallet_balance=balance,
            vehicle_model=user.vehicle_model,
            vehicle_plate=user.vehicle_plate,
            driver_license_number=user.driver_license_number,
            bank_card_number=user.bank_card_number,
        )

    async def update_profile(self, user_id: str, update_data: UserUpdate) -> UserModel:
        user = await self.user_repo.get_by_id(user_id)
        if not user:
            raise NotFoundError("User not found.")

        if update_data.full_name is not None:
            user.full_name = update_data.full_name
        if update_data.email is not None:
            user.email = update_data.email
        if update_data.phone is not None:
            user.phone = update_data.phone
        if update_data.company_name is not None:
            user.company_name = update_data.company_name
        if update_data.avatar_url is not None:
            user.avatar_url = update_data.avatar_url
        if update_data.vehicle_model is not None:
            user.vehicle_model = update_data.vehicle_model
        if update_data.vehicle_plate is not None:
            user.vehicle_plate = update_data.vehicle_plate
        if update_data.driver_license_number is not None:
            user.driver_license_number = update_data.driver_license_number
        if update_data.bank_card_number is not None:
            user.bank_card_number = update_data.bank_card_number

        await self.session.flush()
        return await self.get_user_by_id(user_id)
