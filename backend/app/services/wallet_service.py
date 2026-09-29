from typing import Optional
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.enums import AuditAction, TransactionType
from app.core.exceptions import EscrowLedgerError, NotFoundError
from app.models.wallet import LedgerTransaction, Wallet
from app.repositories.audit_repo import AuditRepository
from app.repositories.wallet_repo import LedgerTransactionRepository, WalletRepository
from app.schemas.wallet import DepositRequest, EscrowTransactionModel, WalletModel, WithdrawalRequest
from app.services.escrow_service import EscrowService

class WalletService:
    def __init__(self, session: AsyncSession):
        self.session = session
        self.wallet_repo = WalletRepository(session)
        self.ledger_repo = LedgerTransactionRepository(session)
        self.audit_repo = AuditRepository(session)
        self.escrow_service = EscrowService(session)

    async def get_wallet_summary(self, user_id: str) -> WalletModel:
        return await self.escrow_service.get_wallet_summary(user_id)

    async def deposit(self, user_id: str, req: DepositRequest) -> WalletModel:
        if req.idempotency_key:
            existing = await self.ledger_repo.get_by_idempotency_key(req.idempotency_key)
            if existing:
                return await self.get_wallet_summary(user_id)

        wallet = await self.wallet_repo.get_by_user_id_for_update(user_id)
        if not wallet:
            wallet = Wallet(user_id=user_id, available_balance=0.0)
            self.session.add(wallet)
            await self.session.flush()

        wallet.available_balance += req.amount

        card_info = f" ({req.card_number})" if req.card_number else ""
        txn = LedgerTransaction(
            wallet_id=wallet.id,
            type=TransactionType.DEPOSIT.value,
            title=f"Direct Card Top-up{card_info}",
            amount=req.amount,
            idempotency_key=req.idempotency_key,
        )
        self.session.add(txn)

        await self.audit_repo.log_event(
            action=AuditAction.WALLET_DEPOSIT.value,
            resource_type="wallet",
            resource_id=wallet.id,
            user_id=user_id,
            changes=f"Deposited {req.amount} UZS",
        )

        await self.session.flush()
        return await self.get_wallet_summary(user_id)

    async def request_withdrawal(self, user_id: str, req: WithdrawalRequest) -> WalletModel:
        if req.idempotency_key:
            existing = await self.ledger_repo.get_by_idempotency_key(req.idempotency_key)
            if existing:
                return await self.get_wallet_summary(user_id)

        wallet = await self.wallet_repo.get_by_user_id_for_update(user_id)
        if not wallet:
            raise NotFoundError("Wallet not found.")

        if wallet.available_balance < req.amount:
            raise EscrowLedgerError("Insufficient available balance for withdrawal.")

        wallet.available_balance -= req.amount

        txn = LedgerTransaction(
            wallet_id=wallet.id,
            type=TransactionType.PAYOUT.value,
            title=f"Withdrawal to {req.card_number}",
            amount=req.amount,
            idempotency_key=req.idempotency_key,
        )
        self.session.add(txn)

        await self.audit_repo.log_event(
            action=AuditAction.WALLET_WITHDRAWAL.value,
            resource_type="wallet",
            resource_id=wallet.id,
            user_id=user_id,
            changes=f"Withdrew {req.amount} UZS to {req.card_number}",
        )

        await self.session.flush()
        return await self.get_wallet_summary(user_id)
