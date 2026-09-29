import json
from datetime import datetime, timezone
import random
from typing import List, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.enums import AuditAction, LoadStatus, UserRole
from app.core.exceptions import InvalidStateTransitionError, NotFoundError, PermissionDeniedError
from app.models.shipment import Shipment, ShipmentStatusHistory
from app.models.tracking import TrackingData
from app.models.chat import ChatChannel
from app.repositories.shipment_repo import ShipmentRepository
from app.repositories.audit_repo import AuditRepository
from app.repositories.user_repo import UserRepository
from app.schemas.shipment import CreateShipmentRequest, LocationPoint, ShipmentModel
from app.schemas.bid import BidModel, NegotiationStep

class ShipmentService:
    def __init__(self, session: AsyncSession):
        self.session = session
        self.shipment_repo = ShipmentRepository(session)
        self.audit_repo = AuditRepository(session)
        self.user_repo = UserRepository(session)

    def _to_shipment_model(self, s: Shipment) -> ShipmentModel:
        bids_list: List[BidModel] = []
        if s.bids:
            for b in s.bids:
                steps: List[NegotiationStep] = []
                if b.negotiation_steps:
                    for st in b.negotiation_steps:
                        steps.append(
                            NegotiationStep(
                                id=st.id,
                                author_role=st.author_role,
                                author_name=st.author_name,
                                proposed_price=st.proposed_price,
                                comment=st.comment,
                                timestamp=st.created_at,
                            )
                        )
                bids_list.append(
                    BidModel(
                        id=b.id,
                        carrier_id=b.carrier_id,
                        carrier_name=b.carrier_name,
                        driver_name=b.driver_name,
                        vehicle_model=b.vehicle_model,
                        plate_number=b.plate_number,
                        bid_amount=b.bid_amount,
                        counter_price=b.counter_price,
                        negotiation_status=b.negotiation_status,
                        negotiation_history=steps,
                        carrier_rating=b.carrier_rating,
                        created_at=b.created_at,
                        is_accepted=b.is_accepted,
                    )
                )

        photos: List[str] = []
        if s.cargo_photos_json:
            try:
                photos = json.loads(s.cargo_photos_json)
            except Exception:
                photos = []

        return ShipmentModel(
            id=s.id,
            tracking_code=s.tracking_code,
            shipper_id=s.shipper_id,
            shipper_name=s.shipper_name,
            carrier_id=s.carrier_id,
            carrier_name=s.carrier_name,
            driver_name=s.driver_name,
            driver_phone=s.driver_phone,
            vehicle_plate=s.vehicle_plate,
            status=s.status,
            origin=LocationPoint(
                city=s.origin_city,
                address=s.origin_address,
                latitude=s.origin_latitude,
                longitude=s.origin_longitude,
                scheduled_time=s.origin_scheduled_time,
            ),
            destination=LocationPoint(
                city=s.dest_city,
                address=s.dest_address,
                latitude=s.dest_latitude,
                longitude=s.dest_longitude,
                scheduled_time=s.dest_scheduled_time,
            ),
            cargo_title=s.cargo_title,
            cargo_type=s.cargo_type,
            weight_tons=s.weight_tons,
            volume_m3=s.volume_m3,
            price=s.price,
            is_escrow_funded=s.is_escrow_funded,
            distance_km=s.distance_km,
            eta=s.eta,
            bids=bids_list,
            pod_signature_url=s.pod_signature_url,
            cargo_photos=photos,
            created_at=s.created_at,
        )

    async def get_shipments(
        self,
        role: Optional[str] = None,
        user_id: Optional[str] = None,
        search_query: Optional[str] = None,
        filter_status: Optional[str] = None,
    ) -> List[ShipmentModel]:
        shipments = await self.shipment_repo.search_shipments(
            role=role,
            user_id=user_id,
            search_query=search_query,
            filter_status=filter_status,
        )
        return [self._to_shipment_model(s) for s in shipments]

    async def get_shipment_by_id(self, shipment_id: str) -> ShipmentModel:
        s = await self.shipment_repo.get_with_relations(shipment_id)
        if not s:
            raise NotFoundError("Shipment not found.")
        return self._to_shipment_model(s)

    async def create_shipment(self, user_id: str, req: CreateShipmentRequest) -> ShipmentModel:
        user = await self.user_repo.get_by_id(user_id)
        if not user:
            raise NotFoundError("User not found.")

        # Generate unique tracking code e.g. LF-UZ-8921
        rand_code = f"LF-UZ-{random.randint(1000, 9999)}"
        photos_json = json.dumps(req.cargo_photos)

        shipment = Shipment(
            tracking_code=rand_code,
            shipper_id=user.id,
            shipper_name=user.company_name or user.full_name,
            status=LoadStatus.CREATED.value,
            origin_city=req.origin.city,
            origin_address=req.origin.address,
            origin_latitude=req.origin.latitude,
            origin_longitude=req.origin.longitude,
            origin_scheduled_time=req.origin.scheduled_time,
            dest_city=req.destination.city,
            dest_address=req.destination.address,
            dest_latitude=req.destination.latitude,
            dest_longitude=req.destination.longitude,
            dest_scheduled_time=req.destination.scheduled_time,
            cargo_title=req.cargo_title,
            cargo_type=req.cargo_type,
            weight_tons=req.weight_tons,
            volume_m3=req.volume_m3,
            price=req.price,
            distance_km=req.distance_km or 300.0,
            eta=req.eta or "4h 30m",
            cargo_photos_json=photos_json,
        )
        await self.shipment_repo.create(shipment)

        # Create tracking entry for the shipment
        tracking = TrackingData(
            shipment_id=shipment.id,
            tracking_code=shipment.tracking_code,
            vehicle_plate="Not Assigned",
            driver_name="Unassigned Driver",
            driver_phone="",
            current_latitude=req.origin.latitude,
            current_longitude=req.origin.longitude,
            distance_remaining_km=shipment.distance_km,
            eta=shipment.eta,
        )
        self.session.add(tracking)

        # Create associated chat channel
        chat_channel = ChatChannel(
            shipment_id=shipment.id,
            shipment_title=shipment.cargo_title,
            tracking_code=shipment.tracking_code,
            last_message="Shipment channel initialized.",
        )
        self.session.add(chat_channel)

        # Add initial status history
        history = ShipmentStatusHistory(
            shipment_id=shipment.id,
            from_status=None,
            to_status=LoadStatus.CREATED.value,
            changed_by_user_id=user.id,
            comments="Shipment created by Shipper",
        )
        self.session.add(history)

        await self.audit_repo.log_event(
            action=AuditAction.SHIPMENT_CREATE.value,
            resource_type="shipment",
            resource_id=shipment.id,
            user_id=user.id,
            changes=f"Created load {rand_code}",
        )

        await self.session.flush()
        return await self.get_shipment_by_id(shipment.id)

    async def advance_status(
        self,
        shipment_id: str,
        user_id: str,
        user_role: str,
        next_status: LoadStatus,
        comments: Optional[str] = None,
    ) -> ShipmentModel:
        shipment = await self.shipment_repo.get_with_relations(shipment_id)
        if not shipment:
            raise NotFoundError("Shipment not found.")

        # RBAC and workflow validation
        prev_status = shipment.status

        # Shipper permission transitions
        if next_status == LoadStatus.ESCROW_FUNDED:
            if user_role not in [UserRole.SHIPPER.value, UserRole.ADMIN.value, UserRole.SUPER_ADMIN.value]:
                raise PermissionDeniedError("Only the shipper can fund escrow.")
            shipment.is_escrow_funded = True

        # Complete and release escrow
        elif next_status == LoadStatus.COMPLETED_PAYOUT_RELEASED:
            if user_role not in [UserRole.SHIPPER.value, UserRole.ADMIN.value, UserRole.SUPER_ADMIN.value]:
                raise PermissionDeniedError("Only the shipper or admin can release completed payout.")

        # Driver transit transitions
        elif next_status in [
            LoadStatus.GOING_TO_PICKUP,
            LoadStatus.ARRIVED_AT_PICKUP,
            LoadStatus.LOADING,
            LoadStatus.IN_TRANSIT,
            LoadStatus.ARRIVED_AT_DESTINATION,
            LoadStatus.UNLOADING,
            LoadStatus.DELIVERED,
        ]:
            if user_role not in [UserRole.DRIVER.value, UserRole.CARRIER.value, UserRole.ADMIN.value, UserRole.SUPER_ADMIN.value]:
                raise PermissionDeniedError("Only the assigned driver/carrier can update transit progress.")

        shipment.status = next_status.value

        # Log status history
        history = ShipmentStatusHistory(
            shipment_id=shipment.id,
            from_status=prev_status,
            to_status=next_status.value,
            changed_by_user_id=user_id,
            comments=comments or f"Advanced status to {next_status.value}",
        )
        self.session.add(history)

        await self.audit_repo.log_event(
            action=AuditAction.SHIPMENT_STATUS_UPDATE.value,
            resource_type="shipment",
            resource_id=shipment.id,
            user_id=user_id,
            changes=f"Status changed from {prev_status} to {next_status.value}",
        )

        await self.session.flush()
        return await self.get_shipment_by_id(shipment.id)
