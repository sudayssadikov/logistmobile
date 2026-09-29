from typing import Optional
from pydantic import Field
from app.schemas.common import BaseSchema
from app.core.enums import DriverStatus

class DriverModel(BaseSchema):
    id: str
    fullName: str = Field(..., alias="full_name")
    phone: str
    email: str
    rating: float = 5.0
    completedTrips: int = Field(0, alias="completed_trips")
    status: str = Field(DriverStatus.IDLE.value, alias="status")
    assignedVehiclePlate: Optional[str] = Field(None, alias="assigned_vehicle_plate")
    assignedTruckId: Optional[str] = Field(None, alias="assigned_truck_id")

class DriverPreferences(BaseSchema):
    currentCity: str = Field("Tashkent", alias="current_city")
    maxRadiusKm: float = Field(50.0, alias="max_radius_km")
    truckType: str = Field("Refrigerated", alias="truck_type")
    maxWeightTons: float = Field(24.0, alias="max_weight_tons")
    minRatePerKm: float = Field(14000.0, alias="min_rate_per_km")
    hasRefrigeration: bool = Field(True, alias="has_refrigeration")

class UpdateDriverStatusRequest(BaseSchema):
    status: DriverStatus
    assigned_vehicle_plate: Optional[str] = Field(None, alias="assignedVehiclePlate")
    assigned_truck_id: Optional[str] = Field(None, alias="assignedTruckId")
