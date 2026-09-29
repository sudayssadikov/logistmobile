from datetime import datetime
from typing import List, Optional
from pydantic import EmailStr, Field
from app.schemas.common import BaseSchema
from app.core.enums import UserRole

class LoginRequest(BaseSchema):
    email_or_phone: str = Field(..., alias="emailOrPhone")
    password: str
    role: UserRole = UserRole.SHIPPER

class RegisterRequest(BaseSchema):
    full_name: str = Field(..., alias="fullName")
    email: EmailStr
    phone: str
    password: str
    role: UserRole = UserRole.SHIPPER
    company_name: Optional[str] = Field(None, alias="companyName")
    industry_type: Optional[str] = Field(None, alias="industryType")
    vehicle_model: Optional[str] = Field(None, alias="vehicleModel")
    vehicle_plate: Optional[str] = Field(None, alias="vehiclePlate")
    driver_license_number: Optional[str] = Field(None, alias="driverLicenseNumber")
    capacity_tons: Optional[float] = Field(None, alias="capacityTons")
    body_type: Optional[str] = Field(None, alias="bodyType")

class SendOtpRequest(BaseSchema):
    phone: str

class VerifyOtpRequest(BaseSchema):
    phone: str
    otp: str
    role: UserRole = UserRole.SHIPPER

class BiometricLoginRequest(BaseSchema):
    role: UserRole = UserRole.SHIPPER

class SwitchRoleRequest(BaseSchema):
    new_role: UserRole = Field(..., alias="newRole")

class TokenResponse(BaseSchema):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int
    user: "UserModel"

class RefreshTokenRequest(BaseSchema):
    refresh_token: str = Field(..., alias="refreshToken")

class ActiveSessionResponse(BaseSchema):
    id: str
    device_model: str = Field(..., alias="deviceModel")
    ip_address: str = Field(..., alias="ipAddress")
    location: str
    last_active: datetime = Field(..., alias="lastActive")
    is_current: bool = Field(False, alias="isCurrent")

class SecuritySettingsResponse(BaseSchema):
    is_biometric_enabled: bool = Field(True, alias="isBiometricEnabled")
    is_2fa_enabled: bool = Field(False, alias="is2FAEnabled")
    sessions: List[ActiveSessionResponse] = []

class UpdateSecuritySettingsRequest(BaseSchema):
    is_biometric_enabled: Optional[bool] = Field(None, alias="isBiometricEnabled")
    is_2fa_enabled: Optional[bool] = Field(None, alias="is2FAEnabled")

# Import circular reference resolver
from app.schemas.user import UserModel
TokenResponse.model_rebuild()
