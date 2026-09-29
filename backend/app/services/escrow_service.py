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

        amount = shipment.price

        # Lock shipper wallet with row-level lock
        shipper_wallet = await self.wallet_repo.get_by_user_id_for_update(shipper_user_id)
        if not shipper_wallet:
            raise NotFoundError("Shipper wallet not found.")

        if shipper_wallet.available_balance < amount:
            raise EscrowLedgerError(f"Insufficient funds: Balance is {shipper_wallet.available_balance}, required {amount} UZS.")

        # Double-entry movement
        shipper_wallet.available_balance -= amount
        shipper_wallet.in_escrow_hold_balance += amount

        # Record escrow lock
        escrow_lock = EscrowLock(
            wallet_id=shipper_wallet.id,
            shipment_id=shipment.id,
            tracking_code=shipment.tracking_code,
            amount=amount,
            status=EscrowStatus.HELD.value,
            recipient_carrier_id=shipment.carrier_id,
        )
        self.session.add(escrow_lock)

        # Record ledger transaction
        txn = LedgerTransaction(
            wallet_id=shipper_wallet.id,
            type=TransactionType.ESCROW_HOLD.value,
            title="Escrow Hold Locked",
            tracking_code=shipment.tracking_code,
            amount=amount,
            idempotency_key=idempotency_key,
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
            changes=f"Locked {amount} UZS for shipment {shipment.tracking_code}",
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

        # Lock both shipper and carrier wallets
        shipper_wallet = await self.wallet_repo.get_by_user_id_for_update(shipment.shipper_id)
        carrier_wallet = await self.wallet_repo.get_by_user_id_for_update(shipment.carrier_id)
        if not carrier_wallet:
            carrier_wallet = Wallet(user_id=shipment.carrier_id, available_balance=0.0)
            self.session.add(carrier_wallet)
            await self.session.flush()

        amount = escrow_lock.amount
        commission = amount * 0.015 # 1.5% platform fee
        payout_net = amount - commission

        # Deduct hold from shipper
        shipper_wallet.in_escrow_hold_balance -= amount

        # Credit net payout to carrier
        carrier_wallet.available_balance += payout_net
        carrier_wallet.total_lifetime_earnings += payout_net

        # Update escrow lock
        escrow_lock.status = EscrowStatus.RELEASED.value
        escrow_lock.released_at = datetime.now(timezone.utc)

        # Create carrier ledger entry
        carrier_txn = LedgerTransaction(
            wallet_id=carrier_wallet.id,
            type=TransactionType.ESCROW_RELEASE.value,
            title="Escrow Payout Released",
            tracking_code=shipment.tracking_code,
            amount=payout_net,
        )
        self.session.add(carrier_txn)

        # Create commission entry
        fee_txn = LedgerTransaction(
            wallet_id=carrier_wallet.id,
            type=TransactionType.COMMISSION.value,
            title="Platform Service Fee (1.5%)",
            tracking_code=shipment.tracking_code,
            amount=commission,
        )
        self.session.add(fee_txn)

        # Advance shipment status
        shipment.status = LoadStatus.COMPLETED_PAYOUT_RELEASED.value

        await self.audit_repo.log_event(
            action=AuditAction.ESCROW_RELEASE.value,
            resource_type="escrow",
            resource_id=escrow_lock.id,
            user_id=authorized_by_user_id,
            changes=f"Released {payout_net} UZS to carrier {shipment.carrier_id}",
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
