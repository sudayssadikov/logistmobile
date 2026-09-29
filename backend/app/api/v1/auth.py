from typing import Optional
from fastapi import APIRouter, Depends, Header, Request, status
from sqlalchemy.ext.asyncio import AsyncSession
from app.dependencies.auth import get_current_user
from app.dependencies.db import get_db
from app.models.user import User
from app.schemas.auth import (
    BiometricLoginRequest,
    LoginRequest,
    RefreshTokenRequest,
    RegisterRequest,
    SecuritySettingsResponse,
    SendOtpRequest,
    SwitchRoleRequest,
    TokenResponse,
    UpdateSecuritySettingsRequest,
    VerifyOtpRequest,
)
from app.schemas.common import ApiResponse
from app.schemas.user import UserModel
from app.services.auth_service import AuthService
from app.services.user_service import UserService

router = APIRouter(prefix="/auth", tags=["Authentication & Security"])

@router.post("/register", response_model=ApiResponse[TokenResponse], status_code=status.HTTP_201_CREATED)
async def register(
    req: RegisterRequest,
    db: AsyncSession = Depends(get_db),
):
    service = AuthService(db)
    result = await service.register(req)
    return ApiResponse(data=result, message="User registered successfully")

@router.post("/login", response_model=ApiResponse[TokenResponse])
async def login(
    req: LoginRequest,
    request: Request,
    db: AsyncSession = Depends(get_db),
):
    ip = request.client.host if request.client else "127.0.0.1"
    user_agent = request.headers.get("user-agent", "Mobile App")
    service = AuthService(db)
    result = await service.login(req, ip=ip, user_agent=user_agent)
    return ApiResponse(data=result, message="Login successful")

@router.post("/send-otp", response_model=ApiResponse[bool])
async def send_otp(
    req: SendOtpRequest,
    db: AsyncSession = Depends(get_db),
):
    service = AuthService(db)
    success = await service.send_otp(req.phone)
    return ApiResponse(data=success, message="OTP verification code sent")

@router.post("/verify-otp", response_model=ApiResponse[TokenResponse])
async def verify_otp(
    req: VerifyOtpRequest,
    request: Request,
    db: AsyncSession = Depends(get_db),
):
    ip = request.client.host if request.client else "127.0.0.1"
    service = AuthService(db)
    result = await service.verify_otp(req, ip=ip)
    return ApiResponse(data=result, message="OTP verified successfully")

@router.post("/refresh", response_model=ApiResponse[TokenResponse])
async def refresh_token(
    req: RefreshTokenRequest,
    db: AsyncSession = Depends(get_db),
):
    service = AuthService(db)
    result = await service.refresh_access_token(req.refresh_token)
    return ApiResponse(data=result, message="Token refreshed successfully")

@router.get("/me", response_model=ApiResponse[UserModel])
async def get_me(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    service = UserService(db)
    user_model = await service.get_user_by_id(current_user.id)
    return ApiResponse(data=user_model, message="Profile retrieved")

@router.post("/biometric", response_model=ApiResponse[TokenResponse])
async def biometric_login(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    service = AuthService(db)
    result = await service.biometric_login(current_user.id)
    return ApiResponse(data=result, message="Biometric authentication successful")

@router.post("/switch-role", response_model=ApiResponse[TokenResponse])
async def switch_role(
    req: SwitchRoleRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    service = AuthService(db)
    result = await service.switch_role(current_user.id, req.new_role)
    return ApiResponse(data=result, message=f"Role switched to {req.new_role.value}")

@router.post("/logout", response_model=ApiResponse[bool])
async def logout(
    current_user: User = Depends(get_current_user),
    authorization: Optional[str] = Header(None),
    db: AsyncSession = Depends(get_db),
):
    service = AuthService(db)
    await service.logout(current_user.id)
    return ApiResponse(data=True, message="Logged out successfully")

@router.get("/security-settings", response_model=ApiResponse[SecuritySettingsResponse])
async def get_security_settings(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    service = AuthService(db)
    result = await service.get_security_settings(current_user.id)
    return ApiResponse(data=result, message="Security settings retrieved")

@router.post("/logout-all-devices", response_model=ApiResponse[bool])
async def logout_all_devices(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    service = AuthService(db)
    await service.logout_all_sessions(current_user.id)
    return ApiResponse(data=True, message="All active sessions terminated")
