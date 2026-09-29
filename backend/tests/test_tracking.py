import pytest
from httpx import AsyncClient

@pytest.mark.asyncio
async def test_tracking_and_pod_submission(client: AsyncClient):
    # Register Driver
    d_resp = await client.post("/api/v1/auth/register", json={
        "fullName": "GPS Driver",
        "email": "driver_gps@test.uz",
        "phone": "+998909998877",
        "password": "Password123!",
        "role": "driver",
    })
    d_token = d_resp.json()["data"]["access_token"]
    d_headers = {"Authorization": f"Bearer {d_token}"}

    # Create load directly
    create_resp = await client.post("/api/v1/loads", json={
        "origin": {"city": "Tashkent", "address": "Gate 1", "latitude": 41.29, "longitude": 69.24},
        "destination": {"city": "Navoiy", "address": "Terminal 2", "latitude": 40.08, "longitude": 65.37},
        "cargoTitle": "Industrial Pumps",
        "cargoType": "Heavy Machinery",
        "weightTons": 14.0,
        "volumeM3": 50.0,
        "price": 12000000.0,
    }, headers=d_headers)
    shipment_id = create_resp.json()["data"]["id"]

    # Send GPS update
    loc_resp = await client.post(f"/api/v1/tracking/{shipment_id}/location", json={
        "latitude": 41.15,
        "longitude": 68.80,
        "speedKmh": 78.5,
        "headingDegrees": 260.0,
        "altitudeMeters": 420.0,
        "batteryPercent": 92,
    }, headers=d_headers)
    assert loc_resp.status_code == 200
    trk = loc_resp.json()["data"]
    assert trk["currentTelemetry"]["speedKmh"] == 78.5

    # Submit electronic POD
    pod_resp = await client.post(f"/api/v1/shipments/{shipment_id}/pod", json={
        "shipmentId": shipment_id,
        "receiverName": "Bakhtiyor Consignee",
        "receiverPhone": "+998901230000",
        "notes": "Delivered with zero seal breakage",
        "latitude": 40.08,
        "longitude": 65.37,
        "cargoPhotos": ["https://cdn.logiflow.uz/photos/seal_intact.jpg"],
        "signatureStrokes": [[{"x": 10, "y": 20}, {"x": 30, "y": 40}]],
        "isApproved": True,
    }, headers=d_headers)
    assert pod_resp.status_code == 200
    assert pod_resp.json()["data"] is True

@pytest.mark.asyncio
async def test_chat_messaging(client: AsyncClient):
    # Register user
    u_resp = await client.post("/api/v1/auth/register", json={
        "fullName": "Chatter",
        "email": "chatter@test.uz",
        "phone": "+998907776655",
        "password": "Password123!",
        "role": "shipper",
    })
    token = u_resp.json()["data"]["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # Create load to get channel
    create_resp = await client.post("/api/v1/loads", json={
        "origin": {"city": "Tashkent", "address": "Hub"},
        "destination": {"city": "Samarkand", "address": "Hub"},
        "cargoTitle": "Chat Test Load",
        "cargoType": "Box",
        "weightTons": 5.0,
        "volumeM3": 20.0,
        "price": 5000000.0,
    }, headers=headers)
    shipment_id = create_resp.json()["data"]["id"]

    # Send message in shipment channel
    msg_resp = await client.post(f"/api/v1/chat/{shipment_id}", json={
        "type": "text",
        "content": "Assalomu alaykum! Haydovchi soat nechada keladi?",
    }, headers=headers)
    assert msg_resp.status_code == 200
    assert msg_resp.json()["data"]["content"] == "Assalomu alaykum! Haydovchi soat nechada keladi?"

@pytest.mark.asyncio
async def test_payme_and_click_webhooks(client: AsyncClient):
    # Payme CheckPerformTransaction
    payme_check = await client.post("/api/v1/payments/webhooks/payme", json={
        "method": "CheckPerformTransaction",
        "params": {"amount": 50000000},
        "id": 1,
    })
    assert payme_check.status_code == 200
    assert payme_check.json()["result"]["allow"] is True

    # Click prepare webhook
    click_resp = await client.post("/api/v1/payments/webhooks/click", json={
        "click_trans_id": 99881122,
        "service_id": 1234,
        "click_paydoc_id": 554433,
        "merchant_trans_id": "test_merchant_user",
        "amount": 250000.0,
        "action": 0,
        "error": 0,
        "error_note": "Success",
        "sign_time": "2026-08-21 12:00:00",
        "sign_string": "test_signature",
    })
    assert click_resp.status_code == 200
    assert click_resp.json()["error"] == 0
