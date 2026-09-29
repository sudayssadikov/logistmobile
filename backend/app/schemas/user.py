from typing import Optional
from pydantic import EmailStr, Field
from app.schemas.common import BaseSchema
from app.core.enums import UserRole

class UserModel(BaseSchema):
    id: str
    full_name: str = Field(..., alias="full_name")
    email: str
    phone: str
    role: str # 'shipper', 'carrier', 'driver', 'admin', etc.
    company_name: Optional[str] = Field(None, alias="company_name")
    avatar_url: Optional[str] = Field(None, alias="avatar_url")
    is_verified: bool = Field(False, alias="is_verified")
    rating: float = 5.0
    completed_trips: int = Field(0, alias="completed_trips")
    wallet_balance: float = Field(0.0, alias="wallet_balance")
    vehicle_model: Optional[str] = Field(None, alias="vehicle_model")
    vehicle_plate: Optional[str] = Field(None, alias="vehicle_plate")
    driver_license_number: Optional[str] = Field(None, alias="driver_license_number")
    bank_card_number: Optional[str] = Field(None, alias="bank_card_number")

class UserUpdate(BaseSchema):
    full_name: Optional[str] = Field(None, alias="fullName")
    email: Optional[EmailStr] = None
    phone: Optional[str] = None
    company_name: Optional[str] = Field(None, alias="companyName")
    avatar_url: Optional[str] = Field(None, alias="avatarUrl")
    vehicle_model: Optional[str] = Field(None, alias="vehicleModel")
    vehicle_plate: Optional[str] = Field(None, alias="vehiclePlate")
    driver_license_number: Optional[str] = Field(None, alias="driverLicenseNumber")
    bank_card_number: Optional[str] = Field(None, alias="bankCardNumber")
