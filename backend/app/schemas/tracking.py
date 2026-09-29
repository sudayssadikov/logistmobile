from datetime import datetime, timezone
from typing import List, Optional
from pydantic import Field
from app.schemas.common import BaseSchema

class LatLngPoint(BaseSchema):
    latitude: float
    longitude: float
    label: Optional[str] = None

class TelemetryUpdate(BaseSchema):
    latitude: float
    longitude: float
    speed_kmh: float = Field(0.0, alias="speedKmh")
    heading_degrees: float = Field(0.0, alias="headingDegrees")
    altitude_meters: float = Field(450.0, alias="altitudeMeters")
    battery_percent: int = Field(95, alias="batteryPercent")
    distance_remaining_km: float = Field(0.0, alias="distanceRemainingKm")
    eta: str = "On Schedule"
    next_waypoint_name: str = Field("Tashkent Checkpoint", alias="nextWaypointName")
    timestamp: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))

class TrackingDataModel(BaseSchema):
    shipment_id: str = Field(..., alias="shipmentId")
    tracking_code: str = Field(..., alias="trackingCode")
    vehicle_plate: str = Field(..., alias="vehiclePlate")
    driver_name: str = Field(..., alias="driverName")
    driver_phone: str = Field(..., alias="driverPhone")
    origin: LatLngPoint
    destination: LatLngPoint
    route_polyline: List[LatLngPoint] = Field([], alias="routePolyline")
    current_telemetry: TelemetryUpdate = Field(..., alias="currentTelemetry")

class SendLocationRequest(BaseSchema):
    latitude: float
    longitude: float
    speed_kmh: Optional[float] = Field(0.0, alias="speedKmh")
    heading_degrees: Optional[float] = Field(0.0, alias="headingDegrees")
    altitude_meters: Optional[float] = Field(450.0, alias="altitudeMeters")
    battery_percent: Optional[int] = Field(100, alias="batteryPercent")
    accuracy_meters: Optional[float] = Field(5.0, alias="accuracyMeters")
