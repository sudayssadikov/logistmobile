from datetime import datetime, timezone
import json
from typing import List, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.exceptions import NotFoundError, PermissionDeniedError
from app.models.shipment import Shipment
from app.models.tracking import TelemetryLog, TrackingData
from app.repositories.shipment_repo import ShipmentRepository
from app.repositories.tracking_repo import TelemetryLogRepository, TrackingRepository
from app.repositories.user_repo import UserRepository
from app.schemas.tracking import LatLngPoint, SendLocationRequest, TelemetryUpdate, TrackingDataModel
from app.schemas.pod import PodSubmissionModel
from app.core.enums import AuditAction, LoadStatus
from app.repositories.audit_repo import AuditRepository

class TrackingService:
    def __init__(self, session: AsyncSession):
        self.session = session
        self.tracking_repo = TrackingRepository(session)
        self.telemetry_repo = TelemetryLogRepository(session)
        self.shipment_repo = ShipmentRepository(session)
        self.user_repo = UserRepository(session)
        self.audit_repo = AuditRepository(session)

    async def get_tracking_by_shipment_id(self, shipment_id: str) -> TrackingDataModel:
        shipment = await self.shipment_repo.get_by_id(shipment_id)
        if not shipment:
            raise NotFoundError("Shipment not found.")

        tracking = await self.tracking_repo.get_by_shipment_id(shipment_id)
        if not tracking:
            # Create tracking container if not exists
            tracking = TrackingData(
                shipment_id=shipment.id,
                tracking_code=shipment.tracking_code,
                vehicle_plate=shipment.vehicle_plate or "01 842 TAA",
                driver_name=shipment.driver_name or "Rustam Karimov",
                driver_phone=shipment.driver_phone or "+998 97 765 43 21",
                current_latitude=shipment.origin_latitude,
                current_longitude=shipment.origin_longitude,
                distance_remaining_km=shipment.distance_km,
                eta=shipment.eta,
            )
            await self.tracking_repo.create(tracking)

        polyline: List[LatLngPoint] = []
        if tracking.route_polyline_json:
            try:
                raw = json.loads(tracking.route_polyline_json)
                polyline = [LatLngPoint(**p) for p in raw]
            except Exception:
                polyline = []

        if not polyline:
            # Generate intermediate route points between origin and destination
            polyline = [
                LatLngPoint(latitude=shipment.origin_latitude, longitude=shipment.origin_longitude, label=shipment.origin_city),
                LatLngPoint(latitude=(shipment.origin_latitude + shipment.dest_latitude) / 2, longitude=(shipment.origin_longitude + shipment.dest_longitude) / 2, label="M39 Highway Waypoint"),
                LatLngPoint(latitude=shipment.dest_latitude, longitude=shipment.dest_longitude, label=shipment.dest_city),
            ]

        telemetry = TelemetryUpdate(
            latitude=tracking.current_latitude,
            longitude=tracking.current_longitude,
            speedKmh=tracking.current_speed_kmh,
            headingDegrees=tracking.current_heading_degrees,
            altitudeMeters=tracking.current_altitude_meters,
            batteryPercent=tracking.current_battery_percent,
            distanceRemainingKm=tracking.distance_remaining_km,
            eta=tracking.eta,
            nextWaypointName=tracking.next_waypoint_name,
            timestamp=tracking.telemetry_timestamp,
        )

        return TrackingDataModel(
            shipmentId=tracking.shipment_id,
            trackingCode=tracking.tracking_code,
            vehiclePlate=tracking.vehicle_plate,
            driverName=tracking.driver_name,
            driverPhone=tracking.driver_phone,
            origin=LatLngPoint(latitude=shipment.origin_latitude, longitude=shipment.origin_longitude, label=shipment.origin_city),
            destination=LatLngPoint(latitude=shipment.dest_latitude, longitude=shipment.dest_longitude, label=shipment.dest_city),
            routePolyline=polyline,
            currentTelemetry=telemetry,
        )

    async def update_location(self, shipment_id: str, driver_user_id: str, req: SendLocationRequest) -> TrackingDataModel:
        shipment = await self.shipment_repo.get_by_id(shipment_id)
        if not shipment:
            raise NotFoundError("Shipment not found.")

        tracking = await self.tracking_repo.get_by_shipment_id(shipment_id)
        if not tracking:
            tracking = TrackingData(
                shipment_id=shipment.id,
                tracking_code=shipment.tracking_code,
                vehicle_plate=shipment.vehicle_plate or "01 842 TAA",
                driver_name=shipment.driver_name or "Driver",
                driver_phone=shipment.driver_phone or "",
            )
            self.session.add(tracking)
            await self.session.flush()

        tracking.current_latitude = req.latitude
        tracking.current_longitude = req.longitude
        tracking.current_speed_kmh = req.speed_kmh or 0.0
        tracking.current_heading_degrees = req.heading_degrees or 0.0
        tracking.current_altitude_meters = req.altitude_meters or 450.0
        tracking.current_battery_percent = req.battery_percent or 100
        tracking.telemetry_timestamp = datetime.now(timezone.utc)

        # Log telemetry history breadcrumb
        log = TelemetryLog(
            tracking_id=tracking.id,
            driver_id=driver_user_id,
            latitude=req.latitude,
            longitude=req.longitude,
            speed_kmh=req.speed_kmh or 0.0,
            heading_degrees=req.heading_degrees or 0.0,
            altitude_meters=req.altitude_meters or 450.0,
            battery_percent=req.battery_percent or 100,
            accuracy_meters=req.accuracy_meters,
        )
        self.session.add(log)
        await self.session.flush()

        return await self.get_tracking_by_shipment_id(shipment_id)

    async def submit_pod(self, shipment_id: str, driver_user_id: str, req: PodSubmissionModel) -> bool:
        shipment = await self.shipment_repo.get_by_id(shipment_id)
        if not shipment:
            raise NotFoundError("Shipment not found.")

        shipment.pod_receiver_name = req.receiver_name
        shipment.pod_receiver_phone = req.receiver_phone
        shipment.pod_notes = req.notes
        shipment.pod_signed_at = req.signed_at or datetime.now(timezone.utc)
        shipment.pod_signature_strokes = json.dumps(req.signature_strokes)
        shipment.status = LoadStatus.DELIVERED.value

        await self.audit_repo.log_event(
            action="pod_submission",
            resource_type="shipment",
            resource_id=shipment.id,
            user_id=driver_user_id,
            changes=f"Signed electronic POD for {shipment.tracking_code} by {req.receiver_name}",
        )

        await self.session.flush()
        return True
