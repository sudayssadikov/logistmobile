import json
from datetime import datetime, timezone
from typing import List, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.enums import AuditAction, DisputeReason, DisputeStatus, EscrowStatus
from app.core.exceptions import NotFoundError
from app.models.dispute import Dispute, DisputeTimeline
from app.models.wallet import EscrowLock, LedgerTransaction, Wallet
from app.repositories.audit_repo import AuditRepository
from app.repositories.dispute_repo import DisputeRepository
from app.repositories.shipment_repo import ShipmentRepository
from app.repositories.user_repo import UserRepository
from app.repositories.wallet_repo import EscrowLockRepository, WalletRepository
from app.schemas.dispute import CreateDisputeRequest, DisputeModel, DisputeTimelineItem, ResolveDisputeRequest

class DisputeService:
    def __init__(self, session: AsyncSession):
        self.session = session
        self.dispute_repo = DisputeRepository(session)
        self.shipment_repo = ShipmentRepository(session)
        self.user_repo = UserRepository(session)
        self.wallet_repo = WalletRepository(session)
        self.escrow_repo = EscrowLockRepository(session)
        self.audit_repo = AuditRepository(session)

    def _to_dispute_model(self, d: Dispute) -> DisputeModel:
        timeline_items = [
            DisputeTimelineItem(status=t.status, message=t.message, timestamp=t.created_at)
            for t in d.timeline
        ]
        photos = []
        if d.evidence_photos_json:
            try:
                photos = json.loads(d.evidence_photos_json)
            except Exception:
                photos = []

        return DisputeModel(
            id=d.id,
            shipmentId=d.shipment_id,
            trackingCode=d.tracking_code,
            claimantName=d.claimant_name,
            reason=d.reason,
            description=d.description,
            claimAmount=d.claim_amount,
            evidencePhotos=photos,
            status=d.status,
            timeline=timeline_items,
            createdAt=d.created_at,
        )

    async def get_disputes(self, claimant_id: Optional[str] = None) -> List[DisputeModel]:
        disputes = await self.dispute_repo.get_all_with_timeline(claimant_id)
        return [self._to_dispute_model(d) for d in disputes]

    async def get_dispute_by_id(self, dispute_id: str) -> DisputeModel:
        d = await self.dispute_repo.get_with_timeline(dispute_id)
        if not d:
            raise NotFoundError("Dispute not found.")
        return self._to_dispute_model(d)

    async def create_dispute(self, claimant_user_id: str, req: CreateDisputeRequest) -> DisputeModel:
        claimant = await self.user_repo.get_by_id(claimant_user_id)
        if not claimant:
            raise NotFoundError("User not found.")

        tracking_code = req.tracking_code or "LF-UZ-8921"
        dispute = Dispute(
            shipment_id=req.shipment_id,
            tracking_code=tracking_code,
            claimant_id=claimant.id,
            claimant_name=claimant.full_name,
            reason=req.reason.value,
            description=req.description,
            claim_amount=req.claim_amount,
            evidence_photos_json=json.dumps(req.evidence_photos),
            status=DisputeStatus.UNDER_REVIEW.value,
        )
        await self.dispute_repo.create(dispute)

        t1 = DisputeTimeline(
            dispute_id=dispute.id,
            status=DisputeStatus.UNDER_REVIEW.value,
            message="Dispute registered. Arbitration team reviewing initial evidence.",
        )
        self.session.add(t1)

        await self.audit_repo.log_event(
            action=AuditAction.DISPUTE_FILED.value,
            resource_type="dispute",
            resource_id=dispute.id,
            user_id=claimant_user_id,
            changes=f"Filed claim of {req.claim_amount} UZS for reason {req.reason.value}",
        )

        await self.session.flush()
        return await self.get_dispute_by_id(dispute.id)

    async def resolve_dispute(self, dispute_id: str, admin_user_id: str, req: ResolveDisputeRequest) -> DisputeModel:
        d = await self.dispute_repo.get_with_timeline(dispute_id)
        if not d:
            raise NotFoundError("Dispute not found.")

        d.status = req.status.value
        t = DisputeTimeline(
            dispute_id=d.id,
            status=req.status.value,
            message=req.resolution_message,
        )
        self.session.add(t)

        # If refund processed, refund escrow back to claimant wallet
        if req.status == DisputeStatus.REFUND_PROCESSED and req.refund_amount:
            wallet = await self.wallet_repo.get_by_user_id_for_update(d.claimant_id)
            if wallet:
                wallet.available_balance += req.refund_amount
                txn = LedgerTransaction(
                    wallet_id=wallet.id,
                    type="refund",
                    title="Dispute Arbitration Refund",
                    tracking_code=d.tracking_code,
                    amount=req.refund_amount,
                )
                self.session.add(txn)

        await self.audit_repo.log_event(
            action=AuditAction.DISPUTE_RESOLVED.value,
            resource_type="dispute",
            resource_id=d.id,
            user_id=admin_user_id,
            changes=f"Resolved with status {req.status.value}",
        )

        await self.session.flush()
        return await self.get_dispute_by_id(dispute_id)
