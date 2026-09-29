from typing import Optional
from pydantic import Field
from app.schemas.common import BaseSchema
from app.core.enums import TruckBodyType

class TruckModel(BaseSchema):
    id: str
    plateNumber: str = Field(..., alias="plate_number")
    model: str
    bodyType: str = Field(TruckBodyType.TENT.value, alias="body_type")
    maxWeightTons: float = Field(22.0, alias="max_weight_tons")
    maxVolumeM3: float = Field(86.0, alias="max_volume_m3")
    assignedDriverId: Optional[str] = Field(None, alias="assigned_driver_id")
    assignedDriverName: Optional[str] = Field(None, alias="assigned_driver_name")
    isAvailable: bool = Field(True, alias="is_available")

class CreateTruckRequest(BaseSchema):
    plate_number: str = Field(..., alias="plateNumber")
    model: str
    body_type: str = Field(TruckBodyType.TENT.value, alias="bodyType")
    max_weight_tons: float = Field(22.0, alias="maxWeightTons")
    max_volume_m3: float = Field(86.0, alias="maxVolumeM3")
    assigned_driver_id: Optional[str] = Field(None, alias="assignedDriverId")
    assigned_driver_name: Optional[str] = Field(None, alias="assignedDriverName")
    is_available: bool = Field(True, alias="isAvailable")

class UpdateTruckRequest(BaseSchema):
    plate_number: Optional[str] = Field(None, alias="plateNumber")
    model: Optional[str] = None
    body_type: Optional[str] = Field(None, alias="bodyType")
    max_weight_tons: Optional[float] = Field(None, alias="maxWeightTons")
    max_volume_m3: Optional[float] = Field(None, alias="maxVolumeM3")
    assigned_driver_id: Optional[str] = Field(None, alias="assignedDriverId")
    assigned_driver_name: Optional[str] = Field(None, alias="assignedDriverName")
    is_available: Optional[bool] = Field(None, alias="isAvailable")
