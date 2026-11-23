import pytest
from httpx import AsyncClient
from app.models.wallet import Wallet
from app.core.enums import LoadStatus, UserRole

@pytest.mark.asyncio
async def test_full_logiflow_lifecycle_e2e(client: AsyncClient, db_session):
    """
    Comprehensive End-to-End Lifecycle Test:
    1. Register & Login Shipper & Driver
    2. Shipper posts freight load
    3. Driver bids on load
    4. Shipper accepts bid -> carrierAssigned -> Chat channel created
    5. VoIP call & unmasked phone protected before escrow
    6. Shipper funds escrow -> held balance, tiered commission calculated
    7. VoIP call allowed after escrow
    8. Interactive Chat messaging between Shipper and Driver
    9. Driver advances status: inTransit -> delivered
    10. Shipper releases escrow -> Net payout to Driver, Commission to Platform
    11. Chat becomes read-only after completion
    12. Cancellation flow: 100% refund to Shipper, 0 commission deducted
    """

    # --- 1. Register & Login Shipper & Driver ---
    shipper_reg = await client.post("/api/v1/auth/register", json={
        "email": "alisher@logiflow.uz",
        "phone": "+998901112233",
        "fullName": "Alisher Yuk Egasi",
        "role": "shipper",
        "password": "Password123!",
    })
    assert shipper_reg.status_code == 201, shipper_reg.text
    shipper_token = shipper_reg.json()["data"]["access_token"]
    shipper_id = shipper_reg.json()["data"]["user"]["id"]
    shipper_headers = {"Authorization": f"Bearer {shipper_token}"}

    driver_reg = await client.post("/api/v1/auth/register", json={
        "email": "sardor@logiflow.uz",
        "phone": "+998904445566",
        "fullName": "Sardor Haydovchi",
        "role": "driver",
        "password": "Password123!",
    })
    assert driver_reg.status_code == 201, driver_reg.text
    driver_token = driver_reg.json()["data"]["access_token"]
    driver_id = driver_reg.json()["data"]["user"]["id"]
    driver_headers = {"Authorization": f"Bearer {driver_token}"}

    # Deposit funds to Shipper's wallet for escrow testing (e.g. 10,000,000 UZS)
    dep_res = await client.post("/api/v1/wallet/deposit", json={"amount": 10000000.0}, headers=shipper_headers)
    assert dep_res.status_code == 200, dep_res.text

    # --- 2. Shipper posts freight load ---
    load_payload = {
        "origin": {
            "city": "Toshkent",
            "address": "Chilonzor 9",
            "latitude": 41.2858,
            "longitude": 69.2035,
            "scheduled_time": "2026-11-20T09:00:00Z",
        },
        "destination": {
            "city": "Samarqand",
            "address": "Registon ko'chasi 1",
            "latitude": 39.6542,
            "longitude": 66.9597,
            "scheduled_time": "2026-11-20T18:00:00Z",
        },
        "cargo_title": "Oziq-ovqat mahsulotlari",
        "cargo_type": "food",
        "weight_tons": 18.5,
        "volume_m3": 72.0,
        "price": 3500000.0,  # Tier 2 (>2M and <=5M) -> Fixed fee 50,000 UZS
        "distance_km": 310.0,
        "eta": "4h 45m",
        "cargo_photos": [],
    }

    create_res = await client.post("/api/v1/shipments", json=load_payload, headers=shipper_headers)
    assert create_res.status_code == 201, create_res.text
    shipment_data = create_res.json()["data"]
    shipment_id = shipment_data["id"]
    assert shipment_data["status"] == LoadStatus.CREATED.value

    # --- 3. Driver views loads and submits bid ---
    feed_res = await client.get("/api/v1/shipments", headers=driver_headers)
    assert feed_res.status_code == 200
    assert any(s["id"] == shipment_id for s in feed_res.json()["data"])

    bid_res = await client.post(f"/api/v1/shipments/{shipment_id}/bids", json={
        "bid_amount": 3500000.0,
        "vehicle_model": "Mercedes-Benz Actros",
        "plate_number": "01 777 AAA",
    }, headers=driver_headers)
    assert bid_res.status_code == 200, bid_res.text
    bid_id = bid_res.json()["data"]["bids"][0]["id"]

    # Verify Shipper received a notification for new bid
    notif_res = await client.get("/api/v1/notifications", headers=shipper_headers)
    assert notif_res.status_code == 200
    assert any("taklif" in n["title"].lower() or "bid" in n["title"].lower() for n in notif_res.json()["data"])

    # --- 4. Shipper accepts bid -> CARRIER_ASSIGNED -> Chat channel created ---
    accept_res = await client.post(f"/api/v1/shipments/{shipment_id}/bids/{bid_id}/accept", headers=shipper_headers)
    assert accept_res.status_code == 200, accept_res.text
    assert accept_res.json()["data"]["status"] == LoadStatus.CARRIER_ASSIGNED.value

    # --- 5. VoIP calling is BLOCKED before escrow funding ---
    call_blocked_res = await client.post("/api/v1/calls/initiate", json={
        "shipment_id": shipment_id,
        "receiver_id": driver_id,
        "type": "audio",
    }, headers=shipper_headers)
    assert call_blocked_res.status_code in [400, 403]
    assert "escrow" in call_blocked_res.json()["message"].lower()

    # --- 6. Shipper funds escrow ---
    fund_res = await client.post(f"/api/v1/shipments/{shipment_id}/escrow/fund", headers=shipper_headers)
    assert fund_res.status_code == 200, fund_res.text

    # Verify shipment is escrow funded and commission calculated
    shp_detail = await client.get(f"/api/v1/shipments/{shipment_id}", headers=shipper_headers)
    assert shp_detail.status_code == 200
    shp_obj = shp_detail.json()["data"]
    assert shp_obj["is_escrow_funded"] is True
    assert shp_obj["commission_amount"] == 50000.0  # Tier 2 fee for 3.5M
    assert shp_obj["carrier_payout"] == 3450000.0  # 3.5M - 50k

    # Verify Driver received Escrow Funded notification
    driver_notif = await client.get("/api/v1/notifications", headers=driver_headers)
    assert any("escrow" in n["title"].lower() or "muzlatildi" in n["title"].lower() for n in driver_notif.json()["data"])

    # --- 7. VoIP calling is now ALLOWED after escrow ---
    call_allowed_res = await client.post("/api/v1/calls/initiate", json={
        "shipment_id": shipment_id,
        "receiver_id": driver_id,
        "type": "audio",
    }, headers=shipper_headers)
    assert call_allowed_res.status_code == 200, call_allowed_res.text

    # --- 8. Interactive Chat messaging between Shipper and Driver ---
    channels_res = await client.get("/api/v1/chat/channels", headers=driver_headers)
    assert channels_res.status_code == 200
    channel_id = channels_res.json()["data"][0]["id"]

    msg1 = await client.post(f"/api/v1/chat/{channel_id}/messages", json={
        "content": "Assalomu alaykum, yukni yuklashga kelyapman.",
        "type": "text",
    }, headers=driver_headers)
    assert msg1.status_code == 200, msg1.text

    msg2 = await client.post(f"/api/v1/chat/{channel_id}/messages", json={
        "content": "Va alaykum assalom, omborda kutmoqdamiz.",
        "type": "text",
    }, headers=shipper_headers)
    assert msg2.status_code == 200, msg2.text

    messages_list = await client.get(f"/api/v1/chat/{channel_id}/messages", headers=shipper_headers)
    assert len(messages_list.json()["data"]) == 2

    # --- 9. Driver advances status: inTransit -> delivered ---
    in_transit_res = await client.post(f"/api/v1/shipments/{shipment_id}/status", json={
        "next_status": "inTransit",
        "comments": "Yuk yuklandi, yo'lga chiqdik.",
    }, headers=driver_headers)
    assert in_transit_res.status_code == 200
    assert in_transit_res.json()["data"]["status"] in [LoadStatus.IN_TRANSIT.value, "inTransit"]

    delivered_res = await client.post(f"/api/v1/shipments/{shipment_id}/status", json={
        "next_status": "delivered",
        "comments": "Manzilga yetib keldik, yuk topshirildi.",
    }, headers=driver_headers)
    assert delivered_res.status_code == 200
    assert delivered_res.json()["data"]["status"] in [LoadStatus.DELIVERED.value, "delivered"]

    # --- 10. Shipper releases escrow payout to Driver ---
    release_res = await client.post(f"/api/v1/shipments/{shipment_id}/escrow/release", headers=shipper_headers)
    assert release_res.status_code == 200, release_res.text

    # Check Driver wallet received net payout (3,450,000 UZS)
    driver_wallet_res = await client.get("/api/v1/wallet/summary", headers=driver_headers)
    assert driver_wallet_res.status_code == 200
    assert driver_wallet_res.json()["data"]["availableBalance"] >= 3450000.0

    # --- 11. Chat is now READ-ONLY ---
    msg_after_done = await client.post(f"/api/v1/chat/{channel_id}/messages", json={
        "content": "Yangi xabar",
        "type": "text",
    }, headers=driver_headers)
    assert msg_after_done.status_code == 403
    assert "o'qish rejimida" in msg_after_done.json()["message"] or "read-only" in msg_after_done.json()["message"].lower()

    # --- 12. Cancellation and 100% Refund Flow ---
    # Record shipper balance before 2nd load
    shipper_before_load2 = (await client.get("/api/v1/wallet/summary", headers=shipper_headers)).json()["data"]["availableBalance"]

    # Shipper creates 2nd load
    load2_res = await client.post("/api/v1/shipments", json={
        **load_payload,
        "cargo_title": "Ikkinchi yuk (Bekor qilish uchun)",
        "price": 2000000.0,
    }, headers=shipper_headers)
    shipment2_id = load2_res.json()["data"]["id"]

    # Driver bids and Shipper accepts
    bid2_res = await client.post(f"/api/v1/shipments/{shipment2_id}/bids", json={
        "bid_amount": 2000000.0,
    }, headers=driver_headers)
    assert bid2_res.status_code == 200
    bid2_id = bid2_res.json()["data"]["bids"][0]["id"]
    await client.post(f"/api/v1/shipments/{shipment2_id}/bids/{bid2_id}/accept", headers=shipper_headers)

    # Fund escrow for load 2
    await client.post(f"/api/v1/shipments/{shipment2_id}/escrow/fund", headers=shipper_headers)

    # Cancel load 2 and verify full refund (zero fee)
    cancel_res = await client.post(f"/api/v1/shipments/{shipment2_id}/escrow/refund", headers=shipper_headers)
    assert cancel_res.status_code == 200

    # Shipper available balance should have the 2,000,000 UZS returned back in full (equal to shipper_before_load2)
    shipper_wallet_final = await client.get("/api/v1/wallet/summary", headers=shipper_headers)
    assert shipper_wallet_final.json()["data"]["availableBalance"] == shipper_before_load2

