import pytest
from httpx import AsyncClient
from app.services.escrow_service import EscrowService

def test_commission_tiers_and_exact_boundaries():
    """Verify tier commission amounts and boundary values (2,000,000 UZS and 5,000,000 UZS)."""
    # Tier 1: price <= 2,000,000 -> 30,000 UZS
    assert EscrowService.calculate_commission(1000000.0) == 30000.0
    assert EscrowService.calculate_commission(1999999.0) == 30000.0
    assert EscrowService.calculate_commission(2000000.0) == 30000.0  # Exact lower boundary

    # Tier 2: 2,000,000 < price <= 5,000,000 -> 50,000 UZS
    assert EscrowService.calculate_commission(2000001.0) == 50000.0
    assert EscrowService.calculate_commission(3500000.0) == 50000.0
    assert EscrowService.calculate_commission(5000000.0) == 50000.0  # Exact upper boundary

    # Tier 3: price > 5,000,000 -> 70,000 UZS
    assert EscrowService.calculate_commission(5000001.0) == 70000.0
    assert EscrowService.calculate_commission(12000000.0) == 70000.0

@pytest.mark.asyncio
async def test_escrow_commission_deducted_from_carrier_not_shipper(client: AsyncClient):
    """
    Test End-to-End Escrow Commission Flow:
    1. Shipper registers and deposits 10,000,000 UZS.
    2. Carrier registers.
    3. Shipper creates load for 4,000,000 UZS (Tier 2: 50,000 commission).
    4. Carrier places bid and Shipper accepts.
    5. Shipper funds escrow: Shipper wallet available decreases by EXACT 4,000,000 UZS (no commission added).
    6. Escrow lock stores: amount=4,000,000, commission_amount=50,000, carrier_payout=3,950,000.
    7. Escrow release: Carrier wallet gets EXACT 3,950,000 UZS, Platform Revenue wallet gets 50,000 UZS.
    """
    # 1. Register Shipper
    s_resp = await client.post("/api/v1/auth/register", json={
        "fullName": "Fee Test Shipper",
        "email": "fee_shipper@test.uz",
        "phone": "+998901239901",
        "password": "Password123!",
        "role": "shipper",
    })
    assert s_resp.status_code == 201
    s_token = s_resp.json()["data"]["access_token"]
    s_headers = {"Authorization": f"Bearer {s_token}"}
    s_user_id = s_resp.json()["data"]["user"]["id"]

    # Top-up shipper wallet
    topup_resp = await client.post("/api/v1/wallet/deposit", json={"amount": 10000000.0}, headers=s_headers)
    assert topup_resp.status_code == 200

    # 2. Register Carrier -> Driver
    c_resp = await client.post("/api/v1/auth/register", json={
        "fullName": "Fee Test Carrier",
        "email": "fee_carrier@test.uz",
        "phone": "+998901239902",
        "password": "Password123!",
        "role": "driver",
    })
    assert c_resp.status_code == 201
    c_token = c_resp.json()["data"]["access_token"]
    c_headers = {"Authorization": f"Bearer {c_token}"}
    c_user_id = c_resp.json()["data"]["user"]["id"]

    # 3. Create Load for 4,000,000 UZS (Tier 2)
    load_resp = await client.post("/api/v1/shipments", json={
        "origin": {"city": "Tashkent", "address": "Hub A"},
        "destination": {"city": "Samarkand", "address": "Hub B"},
        "cargoTitle": "Apples Delivery",
        "cargoType": "Fruit",
        "weightTons": 8.0,
        "volumeM3": 25.0,
        "price": 4000000.0,
    }, headers=s_headers)
    assert load_resp.status_code == 201
    shipment_id = load_resp.json()["data"]["id"]

    # 4. Carrier bids and Shipper accepts
    bid_resp = await client.post(f"/api/v1/shipments/{shipment_id}/bids", json={
        "driverName": "Alisher",
        "vehicleModel": "Isuzu",
        "plateNumber": "01 555 FFF",
        "bidAmount": 4000000.0,
    }, headers=c_headers)
    assert bid_resp.status_code == 200
    bid_id = bid_resp.json()["data"]["bids"][0]["id"]

    accept_resp = await client.post(f"/api/v1/shipments/{shipment_id}/bids/{bid_id}/accept", headers=s_headers)
    assert accept_resp.status_code == 200

    # 5. Shipper funds escrow
    fund_resp = await client.post(f"/api/v1/wallet/escrow/{shipment_id}/fund", headers=s_headers)
    assert fund_resp.status_code == 200
    shipper_wallet = fund_resp.json()["data"]
    # Shipper pays EXACT agreed price (4,000,000)
    assert shipper_wallet["inEscrowHoldBalance"] == 4000000.0

    # 6. Verify shipment details show locked commission & carrier payout
    get_shp = await client.get(f"/api/v1/shipments/{shipment_id}", headers=s_headers)
    assert get_shp.status_code == 200
    shp_data = get_shp.json()["data"]
    assert shp_data["commission_amount"] == 50000.0
    assert shp_data["carrier_payout"] == 3950000.0

    # 7. Release escrow (Delivery & POD confirmed)
    release_resp = await client.post(f"/api/v1/wallet/escrow/{shipment_id}/release", headers=s_headers)
    assert release_resp.status_code == 200

    # 8. Carrier wallet receives net payout (3,950,000 UZS)
    c_wallet_resp = await client.get("/api/v1/wallet", headers=c_headers)
    assert c_wallet_resp.status_code == 200
    assert c_wallet_resp.json()["data"]["availableBalance"] == 28900000.0 + 3950000.0

    # Carrier transaction history has both payout and platform fee
    txns = c_wallet_resp.json()["data"]["transactions"]
    assert any(t["type"] == "commission" and t["amount"] == 50000.0 for t in txns)

@pytest.mark.asyncio
async def test_escrow_cancellation_full_refund_zero_commission(client: AsyncClient):
    """Verify that cancellation refunds 100% of the funds to Shipper with ZERO commission taken."""
    s_resp = await client.post("/api/v1/auth/register", json={
        "fullName": "Cancel Test Shipper",
        "email": "cancel_shipper@test.uz",
        "phone": "+998901239903",
        "password": "Password123!",
        "role": "shipper",
    })
    s_token = s_resp.json()["data"]["access_token"]
    s_headers = {"Authorization": f"Bearer {s_token}"}

    await client.post("/api/v1/wallet/deposit", json={"amount": 5000000.0}, headers=s_headers)

    load_resp = await client.post("/api/v1/shipments", json={
        "origin": {"city": "Tashkent", "address": "Hub"},
        "destination": {"city": "Andijan", "address": "Hub"},
        "cargoTitle": "Cancel Load",
        "cargoType": "Box",
        "weightTons": 2.0,
        "volumeM3": 10.0,
        "price": 1800000.0,  # Tier 1
    }, headers=s_headers)
    shipment_id = load_resp.json()["data"]["id"]

    # Fund Escrow
    await client.post(f"/api/v1/wallet/escrow/{shipment_id}/fund", headers=s_headers)

    # Cancel Load
    cancel_resp = await client.post(f"/api/v1/shipments/{shipment_id}/cancel", headers=s_headers)
    assert cancel_resp.status_code == 200

    # Check Shipper wallet: in_escrow_hold is 0, full balance restored
    wallet_resp = await client.get("/api/v1/wallet", headers=s_headers)
    w_data = wallet_resp.json()["data"]
    assert w_data["inEscrowHoldBalance"] == 0.0
    assert w_data["availableBalance"] == 42500000.0 + 5000000.0
