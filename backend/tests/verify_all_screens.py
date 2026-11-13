import asyncio
import sys
import os
from httpx import AsyncClient, ASGITransport
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))
os.environ["DATABASE_URL"] = "sqlite+aiosqlite:///:memory:"
os.environ["DEBUG"] = "true"

from app.database.base import Base
from app.database.session import get_async_db
from app.dependencies.db import get_db
from app.main import app

test_engine = create_async_engine("sqlite+aiosqlite:///:memory:", echo=False)
TestAsyncSessionLocal = async_sessionmaker(
    bind=test_engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autocommit=False,
    autoflush=False,
)

async def run_verification():
    # 1. Print all registered routes
    print("=== REGISTERED FASTAPI ROUTES ===")
    for route in app.routes:
        methods = getattr(route, "methods", None)
        path = getattr(route, "path", None)
        if methods and path:
            print(f"{','.join(methods):15s} {path}")

    # 2. Setup tables
    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    async with TestAsyncSessionLocal() as session:
        async def override_get_db():
            yield session

        app.dependency_overrides[get_db] = override_get_db
        app.dependency_overrides[get_async_db] = override_get_db

        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://testserver") as client:
            # Register a test Shipper
            reg_s = await client.post("/api/v1/auth/register", json={
                "phone": "+998901111111", "password": "Password123!",
                "full_name": "Shipper Alisher", "role": "shipper"
            })
            token_shipper = reg_s.json().get("access_token")
            h_shipper = {"Authorization": f"Bearer {token_shipper}"}

            # Register a test Carrier
            reg_c = await client.post("/api/v1/auth/register", json={
                "phone": "+998902222222", "password": "Password123!",
                "full_name": "Carrier Botir", "role": "carrier"
            })
            token_carrier = reg_c.json().get("access_token")
            h_carrier = {"Authorization": f"Bearer {token_carrier}"}

            # Register an Admin
            reg_a = await client.post("/api/v1/auth/register", json={
                "phone": "+998903333333", "password": "Password123!",
                "full_name": "Admin Super", "role": "admin"
            })
            token_admin = reg_a.json().get("access_token")
            h_admin = {"Authorization": f"Bearer {token_admin}"}

            print("\n=== VERIFYING SCREEN ENDPOINTS ===")
            checks = [
                # Auth screens
                ("LoginScreen", "/api/v1/auth/login", "POST", {"phone": "+998901111111", "password": "Password123!"}, {}),
                ("RegisterScreen", "/api/v1/auth/register", "POST", {"phone": "+998904444444", "password": "Password123!", "full_name": "New Driver", "role": "driver"}, {}),
                ("OtpVerificationScreen", "/api/v1/auth/otp/send", "POST", {"phone": "+998901111111"}, {}),
                ("OtpVerificationScreen:verify", "/api/v1/auth/otp/verify", "POST", {"phone": "+998901111111", "otp_code": "123456"}, {}),
                
                # ProfileScreen / EditProfileScreen
                ("ProfileScreen", "/api/v1/users/me", "GET", None, h_shipper),
                
                # Shipper / Carrier / Admin: Shipment screens
                ("ShipmentListScreen", "/api/v1/loads", "GET", None, h_shipper),
                ("CreateLoadWizardScreen", "/api/v1/loads", "POST", {
                    "origin_city": "Toshkent", "destination_city": "Samarqand",
                    "cargo_title": "Oziq-ovqat mahsulotlari",
                    "cargo_type": "Tent", "weight_tons": 18.5,
                    "volume_m3": 82.0, "initial_price": 3000000.0
                }, h_shipper),
                ("AILoadMatcherScreen", "/api/v1/loads/ai-match", "GET", None, h_carrier),
                
                # WalletScreen
                ("WalletScreen:balance", "/api/v1/wallet/balance", "GET", None, h_shipper),
                ("WalletScreen:transactions", "/api/v1/wallet/transactions", "GET", None, h_shipper),
                
                # ChatListScreen & ChatConversationScreen
                ("ChatListScreen", "/api/v1/chat/conversations", "GET", None, h_shipper),
                
                # ActiveCallScreen & CallHistoryScreen
                ("CallHistoryScreen", "/api/v1/calls/history", "GET", None, h_shipper),
                
                # DisputeListScreen, CreateDisputeScreen
                ("DisputeListScreen", "/api/v1/disputes", "GET", None, h_shipper),
                
                # FleetManagementScreen
                ("FleetManagementScreen:trucks", "/api/v1/fleet/trucks", "GET", None, h_carrier),
                ("FleetManagementScreen:drivers", "/api/v1/fleet/drivers", "GET", None, h_carrier),
                
                # DocumentVaultScreen
                ("DocumentVaultScreen", "/api/v1/documents", "GET", None, h_shipper),
                
                # NotificationCenterScreen
                ("NotificationCenterScreen:list", "/api/v1/notifications", "GET", None, h_shipper),
                ("NotificationCenterScreen:read", "/api/v1/notifications/read-all", "POST", {}, h_shipper),
                
                # SosRoadsideScreen
                ("SosRoadsideScreen:nearby", "/api/v1/sos/nearby?lat=41.3&lng=69.2", "GET", None, h_carrier),
                
                # AdminControlCenterScreen
                ("AdminControlCenterScreen:stats", "/api/v1/admin/stats", "GET", None, h_admin),
            ]

            for screen_name, path, method, payload, headers in checks:
                if method == "GET":
                    res = await client.get(path, headers=headers)
                elif method == "POST":
                    res = await client.post(path, json=payload, headers=headers)
                print(f"[{res.status_code}] {screen_name:32s} -> {method:4s} {path}")

if __name__ == "__main__":
    asyncio.run(run_verification())
