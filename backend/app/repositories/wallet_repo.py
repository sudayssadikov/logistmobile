from typing import List, Optional
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload
from app.models.wallet import Wallet, EscrowLock, LedgerTransaction
from app.repositories.base import BaseRepository

class WalletRepository(BaseRepository[Wallet]):
    def __init__(self, session: AsyncSession):
        super().__init__(Wallet, session)

    async def get_by_user_id(self, user_id: str) -> Optional[Wallet]:
        stmt = (
            select(Wallet)
            .options(
                selectinload(Wallet.transactions),
                selectinload(Wallet.escrow_locks),
            )
            .where(Wallet.user_id == user_id)
        )
        result = await self.session.execute(stmt)
        return result.scalars().first()

    async def get_by_user_id_for_update(self, user_id: str) -> Optional[Wallet]:
        """Locks row with SELECT FOR UPDATE to guarantee ACID concurrency & zero race conditions."""
        stmt = (
            select(Wallet)
            .options(
                selectinload(Wallet.transactions),
                selectinload(Wallet.escrow_locks),
            )
            .where(Wallet.user_id == user_id)
            .with_for_update()
        )
        result = await self.session.execute(stmt)
        return result.scalars().first()

class LedgerTransactionRepository(BaseRepository[LedgerTransaction]):
    def __init__(self, session: AsyncSession):
        super().__init__(LedgerTransaction, session)

    async def get_by_idempotency_key(self, key: str) -> Optional[LedgerTransaction]:
        stmt = select(LedgerTransaction).where(LedgerTransaction.idempotency_key == key)
        result = await self.session.execute(stmt)
        return result.scalars().first()

class EscrowLockRepository(BaseRepository[EscrowLock]):
    def __init__(self, session: AsyncSession):
        super().__init__(EscrowLock, session)

    async def get_by_shipment_id(self, shipment_id: str) -> Optional[EscrowLock]:
        stmt = select(EscrowLock).where(EscrowLock.shipment_id == shipment_id)
        result = await self.session.execute(stmt)
        return result.scalars().first()
