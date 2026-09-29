import asyncio
from datetime import datetime, timedelta, timezone
import json
from sqlalchemy import select
from app.core.enums import (
    BidNegotiationStatus,
    DocumentVerificationStatus,
    DriverStatus,
    LoadStatus,
    LogisticsDocType,
    NotificationCategory,
    SosServiceType,
    TransactionType,
    TruckBodyType,
    UserRole,
)
from app.core.security import get_password_hash
from app.database.base import Base
from app.database.session import AsyncSessionLocal, engine
from app.models.bid import Bid, NegotiationStep
from app.models.chat import ChatChannel, ChatMessage
from app.models.dispute import Dispute, DisputeTimeline
from app.models.document import Document
from app.models.notification import Notification
from app.models.shipment import Shipment, ShipmentStatusHistory
from app.models.sos import SosProvider
from app.models.tracking import TrackingData
from app.models.user import User
from app.models.vehicle import Vehicle
from app.models.wallet import LedgerTransaction, Wallet

async def seed_database():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    async with AsyncSessionLocal() as session:
        # Check if already seeded
        result = await session.execute(select(User).limit(1))
        if result.scalars().first():
            print("Database already contains records. Skipping seed.")
            return

        print("Seeding LogiFlow database with Sudays Admin...")

        admin = User(
            id="USR-ADMIN-001",
            full_name="Sudays Admin",
            email="sudaysadmin",
            phone="+998900000000",
            hashed_password=get_password_hash("sudaysbrat1109"),
            role=UserRole.ADMIN.value,
            company_name="LogiFlow Enterprise HQ",
            is_verified=True,
            is_superuser=True,
            rating=5.0,
            completed_trips=1500,
        )

        w_admin = Wallet(
            user_id=admin.id,
            available_balance=150000000.0,
            in_escrow_hold_balance=0.0,
            pending_payouts=0.0,
            total_lifetime_earnings=500000000.0,
        )

        session.add(admin)
        await session.flush()
        session.add(w_admin)
        await session.commit()
        print("Database initialized with only Sudays Admin account.")

if __name__ == "__main__":
    asyncio.run(seed_database())
