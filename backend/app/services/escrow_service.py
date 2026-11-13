from datetime import datetime, timezone
from typing import Optional
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.enums import AuditAction, EscrowStatus, LoadStatus, TransactionType
from app.core.exceptions import ConflictError, EscrowLedgerError, NotFoundError, PermissionDeniedError
from app.models.wallet import EscrowLock, LedgerTransaction, Wallet
from app.repositories.audit_repo import AuditRepository
from app.repositories.shipment_repo import ShipmentRepository
from app.repositories.wallet_repo import EscrowLockRepository, LedgerTransactionRepository, WalletRepository
from app.schemas.wallet import EscrowTransactionModel, WalletModel

class EscrowService:
    def __init__(self, session: AsyncSession):
        self.session = session
        self.wallet_repo = WalletRepository(session)
        self.escrow_repo = EscrowLockRepository(session)
        self.ledger_repo = LedgerTransactionRepository(session)
        self.shipment_repo = ShipmentRepository(session)
        self.audit_repo = AuditRepository(session)

    @staticmethod
    def calculate_commission(price: float) -> float:
        """Calculates fixed platform commission deducted from carrier payout according to configurable tiers."""
        from app.config.settings import settings
        t1_limit = getattr(settings, "COMMISSION_TIER_1_LIMIT", 2000000.0)
        t1_fee = getattr(settings, "COMMISSION_TIER_1_FEE", 30000.0)
        t2_limit = getattr(settings, "COMMISSION_TIER_2_LIMIT", 5000000.0)
        t2_fee = getattr(settings, "COMMISSION_TIER_2_FEE", 50000.0)
        t3_fee = getattr(settings, "COMMISSION_TIER_3_FEE", 70000.0)

        if price <= t1_limit:
            return float(t1_fee)
        elif price <= t2_limit:
            return float(t2_fee)
        else:
            return float(t3_fee)

    async def _get_or_create_platform_wallet(self) -> Wallet:
        """Retrieves or initializes the system platform_revenue wallet for double-entry commission accounting."""
        platform_user_id = "USR-PLATFORM-REVENUE"
        w = await self.wallet_repo.get_by_user_id_for_update(platform_user_id)
        if not w:
            w = Wallet(user_id=platform_user_id, available_balance=0.0)
            self.session.add(w)
            await self.session.flush()
        return w

    async def fund_escrow(self, shipper_user_id: str, shipment_id: str, idempotency_key: Optional[str] = None) -> WalletModel:
        if idempotency_key:
            existing_txn = await self.ledger_repo.get_by_idempotency_key(idempotency_key)
            if existing_txn:
                return await self.get_wallet_summary(shipper_user_id)

        shipment = await self.shipment_repo.get_with_relations(shipment_id)
        if not shipment:
            raise NotFoundError("Shipment not found.")

        if shipment.shipper_id != shipper_user_id:
            raise PermissionDeniedError("Only the shipment creator can fund escrow.")

        # Check existing escrow
        existing_escrow = await self.escrow_repo.get_by_shipment_id(shipment.id)
        if existing_escrow and existing_escrow.status == EscrowStatus.HELD.value:
            raise ConflictError("Escrow is already funded for this shipment.")

        # Shipper pays EXACT agreed price. No extra fee added to shipper.
        amount = float(shipment.price)

        # Calculate and lock platform commission once at fund time
        commission = self.calculate_commission(amount)
        carrier_payout = max(0.0, amount - commission)

        # Persist locked values directly on shipment so future tariff changes do not affect existing load
        shipment.commission_amount = commission
        shipment.carrier_payout = carrier_payout

        # Lock shipper wallet with row-level lock (SELECT FOR UPDATE)
        shipper_wallet = await self.wallet_repo.get_by_user_id_for_update(shipper_user_id)
        if not shipper_wallet:
            raise NotFoundError("Shipper wallet not found.")

        if shipper_wallet.available_balance < amount:
            raise EscrowLedgerError(f"Insufficient funds: Balance is {shipper_wallet.available_balance}, required {amount} UZS.")

        # Double-entry movement on Shipper wallet
        shipper_wallet.available_balance -= amount
        shipper_wallet.in_escrow_hold_balance += amount

        # Record escrow lock with locked commission and net payout
        escrow_lock = EscrowLock(
            wallet_id=shipper_wallet.id,
            shipment_id=shipment.id,
            tracking_code=shipment.tracking_code,
            amount=amount,
            commission_amount=commission,
            carrier_payout=carrier_payout,
            status=EscrowStatus.HELD.value,
            recipient_carrier_id=shipment.carrier_id,
        )
        self.session.add(escrow_lock)

        # Record shipper ledger transaction (Held)
        txn = LedgerTransaction(
            wallet_id=shipper_wallet.id,
            type=TransactionType.ESCROW_HOLD.value,
            title="Escrow Hold Locked",
            tracking_code=shipment.tracking_code,
            amount=amount,
            idempotency_key=idempotency_key,
            metadata_json=f'{{"commission_reserved": {commission}, "carrier_payout": {carrier_payout}}}',
        )
        self.session.add(txn)

        # Advance shipment status
        shipment.is_escrow_funded = True
        shipment.status = LoadStatus.ESCROW_FUNDED.value

        await self.audit_repo.log_event(
            action=AuditAction.ESCROW_FUND.value,
            resource_type="escrow",
            resource_id=escrow_lock.id,
            user_id=shipper_user_id,
            changes=f"Locked {amount} UZS (Reserved fee: {commission} UZS, Carrier payout: {carrier_payout} UZS) for {shipment.tracking_code}",
        )

        await self.session.flush()
        return await self.get_wallet_summary(shipper_user_id)

    async def release_escrow(self, shipment_id: str, authorized_by_user_id: str) -> bool:
        shipment = await self.shipment_repo.get_with_relations(shipment_id)
        if not shipment:
            raise NotFoundError("Shipment not found.")

        escrow_lock = await self.escrow_repo.get_by_shipment_id(shipment.id)
        if not escrow_lock or escrow_lock.status != EscrowStatus.HELD.value:
            raise ConflictError("No active held escrow found for this shipment.")

        if not shipment.carrier_id:
            raise EscrowLedgerError("No assigned carrier found to receive payout.")

        # Lock shipper, carrier, and platform revenue wallets (SELECT FOR UPDATE)
        shipper_wallet = await self.wallet_repo.get_by_user_id_for_update(shipment.shipper_id)
        carrier_wallet = await self.wallet_repo.get_by_user_id_for_update(shipment.carrier_id)
        if not carrier_wallet:
            carrier_wallet = Wallet(user_id=shipment.carrier_id, available_balance=0.0)
            self.session.add(carrier_wallet)
            await self.session.flush()

        platform_wallet = await self._get_or_create_platform_wallet()

        total_held = float(escrow_lock.amount)
        # Use locked commission & net payout from escrow lock / shipment
        commission = float(escrow_lock.commission_amount if escrow_lock.commission_amount > 0 else (shipment.commission_amount or self.calculate_commission(total_held)))
        payout_net = float(escrow_lock.carrier_payout if escrow_lock.carrier_payout > 0 else (shipment.carrier_payout or max(0.0, total_held - commission)))

        # 1. Release hold from Shipper
        shipper_wallet.in_escrow_hold_balance -= total_held

        # 2. Credit net payout to Carrier (Carrier receives exact price minus commission)
        carrier_wallet.available_balance += payout_net
        carrier_wallet.total_lifetime_earnings += payout_net

        # 3. Credit platform revenue wallet (double-entry accounting)
        platform_wallet.available_balance += commission
        platform_wallet.total_lifetime_earnings += commission

        # Update escrow lock state
        escrow_lock.status = EscrowStatus.RELEASED.value
        escrow_lock.released_at = datetime.now(timezone.utc)

        # Record carrier payout ledger entry
        carrier_txn = LedgerTransaction(
            wallet_id=carrier_wallet.id,
            type=TransactionType.ESCROW_RELEASE.value,
            title="Escrow Payout Released",
            tracking_code=shipment.tracking_code,
            amount=payout_net,
        )
        self.session.add(carrier_txn)

        # Record carrier service fee ledger entry (Xizmat haqi)
        carrier_fee_txn = LedgerTransaction(
            wallet_id=carrier_wallet.id,
            type=TransactionType.COMMISSION.value,
            title="Xizmat haqi (Platforma komissiyasi)",
            tracking_code=shipment.tracking_code,
            amount=commission,
        )
        self.session.add(carrier_fee_txn)

        # Record platform revenue ledger entry
        platform_rev_txn = LedgerTransaction(
            wallet_id=platform_wallet.id,
            type=TransactionType.COMMISSION.value,
            title=f"Platform Commission Received ({shipment.tracking_code})",
            tracking_code=shipment.tracking_code,
            amount=commission,
        )
        self.session.add(platform_rev_txn)

        # Advance shipment status
        shipment.status = LoadStatus.COMPLETED_PAYOUT_RELEASED.value

        await self.audit_repo.log_event(
            action=AuditAction.ESCROW_RELEASE.value,
            resource_type="escrow",
            resource_id=escrow_lock.id,
            user_id=authorized_by_user_id,
            changes=f"Released {payout_net} UZS to carrier {shipment.carrier_id}, {commission} UZS commission to platform",
        )

        await self.session.flush()
        return True

    async def refund_escrow(self, shipment_id: str, authorized_by_user_id: str, reason: str = "Cancellation or Dispute resolved in favor of Shipper") -> bool:
        """Full refund of escrow funds to Shipper. Zero platform commission is charged."""
        shipment = await self.shipment_repo.get_with_relations(shipment_id)
        if not shipment:
            raise NotFoundError("Shipment not found.")

        escrow_lock = await self.escrow_repo.get_by_shipment_id(shipment.id)
        if not escrow_lock or escrow_lock.status != EscrowStatus.HELD.value:
            raise ConflictError("No active held escrow found for refund.")

        shipper_wallet = await self.wallet_repo.get_by_user_id_for_update(shipment.shipper_id)
        if not shipper_wallet:
            raise NotFoundError("Shipper wallet not found.")

        full_amount = float(escrow_lock.amount)

        # 1. Reverse hold and return FULL amount to shipper available balance (no commission deducted)
        shipper_wallet.in_escrow_hold_balance -= full_amount
        shipper_wallet.available_balance += full_amount

        # 2. Mark escrow lock as refunded
        escrow_lock.status = EscrowStatus.REFUNDED.value
        escrow_lock.released_at = datetime.now(timezone.utc)

        # 3. Record refund ledger entry
        refund_txn = LedgerTransaction(
            wallet_id=shipper_wallet.id,
            type=TransactionType.REFUND.value,
            title="Escrow Full Refund (No commission)",
            tracking_code=shipment.tracking_code,
            amount=full_amount,
            metadata_json=f'{{"reason": "{reason}"}}',
        )
        self.session.add(refund_txn)

        # 4. Advance shipment status
        shipment.status = LoadStatus.CANCELLED.value

        await self.audit_repo.log_event(
            action=AuditAction.ESCROW_REFUND.value,
            resource_type="escrow",
            resource_id=escrow_lock.id,
            user_id=authorized_by_user_id,
            changes=f"Refunded full {full_amount} UZS to shipper without commission. Reason: {reason}",
        )

        await self.session.flush()
        return True

    async def get_wallet_summary(self, user_id: str) -> WalletModel:
        wallet = await self.wallet_repo.get_by_user_id(user_id)
        if not wallet:
            wallet = Wallet(user_id=user_id, available_balance=0.0)
            self.session.add(wallet)
            await self.session.flush()

        txns: list[EscrowTransactionModel] = []
        if wallet.transactions:
            for t in wallet.transactions:
                txns.append(
                    EscrowTransactionModel(
                        id=t.id,
                        type=TransactionType(t.type),
                        title=t.title,
                        trackingCode=t.tracking_code,
                        amount=t.amount,
                        timestamp=t.created_at,
                        isCompleted=t.is_completed,
                    )
                )

        return WalletModel(
            availableBalance=wallet.available_balance,
            inEscrowHoldBalance=wallet.in_escrow_hold_balance,
            pendingPayouts=wallet.pending_payouts,
            totalLifetimeEarnings=wallet.total_lifetime_earnings,
            transactions=txns,
        )
