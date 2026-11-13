from datetime import datetime, timedelta, timezone
from typing import Optional
from sqlalchemy.ext.asyncio import AsyncSession
from app.config.settings import settings
from app.core.enums import UserRole
from app.core.exceptions import AppException, AuthenticationError, ConflictError, NotFoundError
from app.core.security import (
    create_access_token,
    create_refresh_token,
    decode_token,
    get_password_hash,
    verify_password,
)
from app.models.user import LoginHistory, User, UserOTP, UserSession
from app.models.wallet import Wallet
from app.repositories.user_repo import OTPRepository, SessionRepository, UserRepository
from app.repositories.wallet_repo import WalletRepository
from app.schemas.auth import (
    ActiveSessionResponse,
    LoginRequest,
    RegisterRequest,
    SecuritySettingsResponse,
    TokenResponse,
    VerifyOtpRequest,
)
from app.schemas.user import UserModel
from app.services.sms_service import SmsService

class AuthService:
    def __init__(self, session: AsyncSession):
        self.session = session
        self.user_repo = UserRepository(session)
        self.session_repo = SessionRepository(session)
        self.otp_repo = OTPRepository(session)
        self.wallet_repo = WalletRepository(session)

    def _to_user_model(self, user: User, wallet_balance: float = 0.0) -> UserModel:
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
            wallet_balance=wallet_balance,
            vehicle_model=user.vehicle_model,
            vehicle_plate=user.vehicle_plate,
            driver_license_number=user.driver_license_number,
            bank_card_number=user.bank_card_number,
        )

    async def register(self, req: RegisterRequest) -> TokenResponse:
        existing_email = await self.user_repo.get_by_email(req.email)
        if existing_email:
            raise ConflictError("A user with this email address already exists.")

        existing_phone = await self.user_repo.get_by_phone(req.phone)
        if existing_phone:
            raise ConflictError("A user with this phone number already exists.")

        hashed = get_password_hash(req.password)
        company = req.company_name
        if req.industry_type and company:
            company = f"{company} ({req.industry_type})"

        user = User(
            full_name=req.full_name,
            email=req.email.lower(),
            phone=req.phone.replace(" ", ""),
            hashed_password=hashed,
            role=req.role.value,
            company_name=company,
            vehicle_model=req.vehicle_model,
            vehicle_plate=req.vehicle_plate,
            driver_license_number=req.driver_license_number,
            is_verified=True,
            rating=5.0,
            completed_trips=0,
        )
        await self.user_repo.create(user)

        # Create wallet with default starting test balance
        init_balance = 42500000.0 if req.role == UserRole.SHIPPER else 28900000.0
        wallet = Wallet(
            user_id=user.id,
            available_balance=init_balance,
            in_escrow_hold_balance=0.0,
            pending_payouts=0.0,
            total_lifetime_earnings=0.0,
        )
        self.session.add(wallet)
        await self.session.flush()

        return await self._generate_auth_tokens(user, wallet.available_balance)

    async def login(self, req: LoginRequest, ip: str = "127.0.0.1", user_agent: str = "Client") -> TokenResponse:


        session = await self.session_repo.get_by_refresh_token(refresh_token)
        if not session or not session.is_active:
            raise AuthenticationError("Session expired or revoked")

        user = await self.user_repo.get_by_id(session.user_id)
        if not user:
            raise NotFoundError("User not found")

        # Invalidate old session and rotate
        session.is_active = False
        wallet = await self.wallet_repo.get_by_user_id(user.id)
        wallet_balance = wallet.available_balance if wallet else 0.0
        return await self._generate_auth_tokens(user, wallet_balance)

    async def logout(self, user_id: str, token: Optional[str] = None) -> None:
        if token:
            session = await self.session_repo.get_by_refresh_token(token)
            if session:
                session.is_active = False
        await self.session.flush()

    async def logout_all_sessions(self, user_id: str) -> None:
        await self.session_repo.deactivate_all_for_user(user_id)

    async def get_security_settings(self, user_id: str, current_token: Optional[str] = None) -> SecuritySettingsResponse:
        user = await self.user_repo.get_by_id(user_id)
        if not user:
            raise NotFoundError("User not found.")
        sessions = await self.session_repo.get_active_sessions_for_user(user_id)
        session_responses = [
            ActiveSessionResponse(
                id=s.id,
                device_model=s.device_model,
                ip_address=s.ip_address,
                location=s.location,
                last_active=s.last_active,
                is_current=(s.refresh_token == current_token),
            )
            for s in sessions
        ]
        return SecuritySettingsResponse(
            is_biometric_enabled=user.is_biometric_enabled,
            is_2fa_enabled=user.is_2fa_enabled,
            sessions=session_responses,
        )

    async def _generate_auth_tokens(self, user: User, wallet_balance: float, ip: str = "127.0.0.1") -> TokenResponse:
        user_model = self._to_user_model(user, wallet_balance)
        access_token = create_access_token(user.id, user.role)
        refresh_token = create_refresh_token(user.id, user.role)

        # Store session in database
        expires_at = datetime.now(timezone.utc) + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)
        session = UserSession(
            user_id=user.id,
            refresh_token=refresh_token,
            device_model="Mobile App Client",
            ip_address=ip,
            location="Tashkent, UZ",
            expires_at=expires_at,
        )
        await self.session_repo.create(session)

        return TokenResponse(
            access_token=access_token,
            refresh_token=refresh_token,
            token_type="bearer",
            expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
            user=user_model,
        )
