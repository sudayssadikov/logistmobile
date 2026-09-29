import pytest
from httpx import AsyncClient

@pytest.mark.asyncio
async def test_escrow_funding_and_release_ledger(client: AsyncClient):
    # 1. Register Shipper & Carrier
    s_resp = await client.post("/api/v1/auth/register", json={
        "fullName": "Agro Shipper",
        "email": "agro@escrow.uz",
        "phone": "+998905551122",
        "password": "Password123!",
        "role": "shipper",
    })
    s_token = s_resp.json()["data"]["access_token"]
    s_headers = {"Authorization": f"Bearer {s_token}"}

    c_resp = await client.post("/api/v1/auth/register", json={
        "fullName": "Fast Carrier",
        "email": "fast@escrow.uz",
        "phone": "+998905551133",
        "password": "Password123!",
        "role": "carrier",
    })
    c_token = c_resp.json()["data"]["access_token"]
    c_headers = {"Authorization": f"Bearer {c_token}"}

    # 2. Create load & assign carrier
    create_resp = await client.post("/api/v1/loads", json={
        "origin": {"city": "Tashkent", "address": "Hub A"},
        "destination": {"city": "Bukhara", "address": "Terminal B"},
        "cargoTitle": "Apples",
        "cargoType": "Refrigerated",
        "weightTons": 20.0,
        "volumeM3": 80.0,
        "price": 10000000.0,
    }, headers=s_headers)
    shipment_id = create_resp.json()["data"]["id"]

    # Carrier bids
    bid_resp = await client.post(f"/api/v1/loads/{shipment_id}/bids", json={
        "bidAmount": 10000000.0,
    }, headers=c_headers)
    bid_id = bid_resp.json()["data"]["bids"][0]["id"]

    # Shipper accepts
    await client.post(f"/api/v1/loads/{shipment_id}/bids/{bid_id}/accept", headers=s_headers)

    # 3. Shipper funds escrow
    fund_resp = await client.post("/api/v1/escrow/fund", json={
        "shipmentId": shipment_id,
        "idempotencyKey": "unique_escrow_key_101",
    }, headers=s_headers)
    assert fund_resp.status_code == 200
    wallet_data = fund_resp.json()["data"]
    assert wallet_data["inEscrowHoldBalance"] >= 10000000.0

    # 4. Advance status to delivered and release escrow
    await client.post(f"/api/v1/loads/{shipment_id}/status", json={
        "nextStatus": "delivered",
    }, headers=c_headers)

    release_resp = await client.post(f"/api/v1/escrow/release/{shipment_id}", headers=s_headers)
    assert release_resp.status_code == 200
    assert release_resp.json()["data"] is True

    # 5. Check carrier wallet increased
    carrier_wallet_resp = await client.get("/api/v1/wallet", headers=c_headers)
    assert carrier_wallet_resp.status_code == 200
    # Net payout: 10,000,000 - 1.5% fee (150,000) = 9,850,000
    assert carrier_wallet_resp.json()["data"]["availableBalance"] >= 9850000.0
