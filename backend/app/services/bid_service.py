from typing import List
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.enums import AuditAction, BidNegotiationStatus, LoadStatus, NotificationCategory, UserRole
from app.core.exceptions import NotFoundError, PermissionDeniedError
from app.models.bid import Bid, NegotiationStep
from app.models.chat import ChatChannel
from app.services.notification_service import NotificationService
from app.repositories.bid_repo import BidRepository
from app.repositories.shipment_repo import ShipmentRepository
from app.repositories.user_repo import UserRepository
from app.repositories.audit_repo import AuditRepository
from app.schemas.bid import CounterBidRequest, SubmitBidRequest
from app.schemas.shipment import ShipmentModel
from app.services.shipment_service import ShipmentService

class BidService:
    def __init__(self, session: AsyncSession):
        self.session = session
        self.bid_repo = BidRepository(session)
        self.shipment_repo = ShipmentRepository(session)
        self.user_repo = UserRepository(session)
        self.audit_repo = AuditRepository(session)
        self.shipment_service = ShipmentService(session)

    async def submit_bid(self, shipment_id: str, carrier_user_id: str, req: SubmitBidRequest) -> ShipmentModel:
        shipment = await self.shipment_repo.get_by_id(shipment_id)
        if not shipment:
            raise NotFoundError("Shipment not found.")

        carrier = await self.user_repo.get_by_id(carrier_user_id)
        if not carrier:
            raise NotFoundError("Carrier not found.")

        bid = Bid(
            shipment_id=shipment.id,
            carrier_id=carrier.id,
            carrier_name=carrier.company_name or carrier.full_name,
            driver_name=req.driver_name or carrier.full_name,
            vehicle_model=req.vehicle_model or carrier.vehicle_model or "Volvo FH 500",
            plate_number=req.plate_number or carrier.vehicle_plate or "01 777 AAA",
            bid_amount=req.bid_amount,
            counter_price=req.counter_price,
            negotiation_status=BidNegotiationStatus.PENDING.value,
            carrier_rating=carrier.rating,
        )
        await self.bid_repo.create(bid)

        # Initial negotiation step
        step = NegotiationStep(
            bid_id=bid.id,
            author_role="carrier",
            author_name=carrier.full_name,
            proposed_price=req.bid_amount,
            comment=req.comment or "Initial offer submitted",
        )
        self.session.add(step)

        # Update shipment status to pendingBid if created
        if shipment.status == LoadStatus.CREATED.value:
            shipment.status = LoadStatus.PENDING_BID.value

        await self.audit_repo.log_event(
            action=AuditAction.BID_SUBMIT.value,
            resource_type="bid",
            resource_id=bid.id,
            user_id=carrier.id,
            changes=f"Submitted bid of {req.bid_amount} UZS on load {shipment.tracking_code}",
        )

        # Notify Shipper
        notif_service = NotificationService(self.session)
        await notif_service.create_notification(
            user_id=shipment.shipper_id,
            title="Yangi taklif!",
            body=f"{carrier.company_name or carrier.full_name} sizning yukingizga taklif yubordi.",
            category=NotificationCategory.SHIPMENTS,
            action_route=f"/shipments/{shipment.id}",
        )

        await self.session.flush()
        return await self.shipment_service.get_shipment_by_id(shipment.id)

    async def counter_bid(self, shipment_id: str, bid_id: str, user_id: str, user_role: str, req: CounterBidRequest) -> ShipmentModel:
        bid = await self.bid_repo.get_with_steps(bid_id)
        if not bid or bid.shipment_id != shipment_id:
            raise NotFoundError("Bid not found.")

        user = await self.user_repo.get_by_id(user_id)
        if not user:
            raise NotFoundError("User not found.")

        bid.counter_price = req.counter_price
        bid.negotiation_status = BidNegotiationStatus.COUNTERED.value

        step = NegotiationStep(
            bid_id=bid.id,
            author_role="shipper" if user_role == UserRole.SHIPPER.value else "driver",
            author_name=user.full_name,
            proposed_price=req.counter_price,
            comment=req.comment or f"Counter offer of {req.counter_price} proposed",
        )
        self.session.add(step)
        await self.session.flush()
        return await self.shipment_service.get_shipment_by_id(shipment_id)

    async def accept_bid(self, shipment_id: str, bid_id: str, shipper_user_id: str) -> ShipmentModel:
        shipment = await self.shipment_repo.get_with_relations(shipment_id)
        if not shipment:
            raise NotFoundError("Shipment not found.")

        if shipment.shipper_id != shipper_user_id:
            raise PermissionDeniedError("Only the shipment owner can accept bids.")

        bid = await self.bid_repo.get_by_id(bid_id)
        if not bid:
            raise NotFoundError("Bid not found.")

        bid.is_accepted = True
        bid.negotiation_status = BidNegotiationStatus.ACCEPTED.value

        # Assign carrier & vehicle to shipment
        shipment.carrier_id = bid.carrier_id
        shipment.carrier_name = bid.carrier_name
        shipment.driver_name = bid.driver_name
        shipment.vehicle_plate = f"{bid.plate_number} ({bid.vehicle_model})"
        shipment.price = bid.bid_amount
        shipment.status = LoadStatus.CARRIER_ASSIGNED.value

        # Create associated chat channel only upon assignment
        existing_channel = await self.session.execute(
            select(ChatChannel).where(ChatChannel.shipment_id == shipment.id)
        )
        channel = existing_channel.scalar_one_or_none()
        if not channel:
            channel = ChatChannel(
                shipment_id=shipment.id,
                shipment_title=shipment.cargo_title,
                tracking_code=shipment.tracking_code,
                last_message="Haydovchi tayinlandi. Muloqot ochildi.",
            )
            self.session.add(channel)

        await self.audit_repo.log_event(
            action=AuditAction.BID_ACCEPT.value,
            resource_type="shipment",
            resource_id=shipment.id,
            user_id=shipper_user_id,
            changes=f"Accepted bid {bid.id} from {bid.carrier_name}",
        )

        # Notify Driver/Carrier
        notif_service = NotificationService(self.session)
        await notif_service.create_notification(
            user_id=bid.carrier_id,
            title="Taklifingiz qabul qilindi!",
            body=f"Yuk egasi sizning taklifingizni tasdiqladi. Buyurtma: {shipment.cargo_title}",
            category=NotificationCategory.SHIPMENTS,
            action_route=f"/shipments/{shipment.id}",
        )

        await self.session.flush()
        return await self.shipment_service.get_shipment_by_id(shipment.id)
