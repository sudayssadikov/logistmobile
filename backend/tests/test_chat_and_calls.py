import pytest
from httpx import AsyncClient

@pytest.mark.asyncio
async def test_chat_and_call_lifecycle(client: AsyncClient):
    # 1. Register Shipper
    shipper_resp = await client.post("/api/v1/auth/register", json={
        "fullName": "Chat Shipper",
        "email": "chat_shipper@test.uz",
        "phone": "+998905551122",
        "password": "Password123!",
        "role": "shipper",
    })
    assert shipper_resp.status_code == 201
    shipper_token = shipper_resp.json()["data"]["access_token"]
    shipper_headers = {"Authorization": f"Bearer {shipper_token}"}
    shipper_id = shipper_resp.json()["data"]["user"]["id"]

    # 2. Register Driver
    driver_resp = await client.post("/api/v1/auth/register", json={
        "fullName": "Chat Driver",
        "email": "chat_driver@test.uz",
        "phone": "+998905553344",
        "password": "Password123!",
        "role": "driver",
    })
    assert driver_resp.status_code == 201
    driver_token = driver_resp.json()["data"]["access_token"]
    driver_headers = {"Authorization": f"Bearer {driver_token}"}
    driver_id = driver_resp.json()["data"]["user"]["id"]

    # 3. Create a Shipment
    shipment_resp = await client.post("/api/v1/shipments", headers=shipper_headers, json={
        "origin": {
            "city": "Tashkent",
            "address": "Chilanzar 12",
            "latitude": 41.28,
            "longitude": 69.20,
        },
        "destination": {
            "city": "Bukhara",
            "address": "Gijduvan 45",
            "latitude": 39.77,
            "longitude": 64.42,
        },
        "cargoTitle": "Textiles to Bukhara",
        "cargoType": "Standard Curtain",
        "weightTons": 14.5,
        "volumeM3": 60.0,
        "price": 8500000.0,
        "distanceKm": 560.0,
        "eta": "8 hours",
    })
    assert shipment_resp.status_code == 201
    shipment_id = shipment_resp.json()["data"]["id"]

    # 4. Send Chat message (Shipper owner can leave message)
    msg_resp = await client.post(f"/api/v1/chat/{shipment_id}", headers=shipper_headers, json={
        "type": "text",
        "content": "Salom haydovchi, yuk yuklashga tayyor!",
    })
    assert msg_resp.status_code == 200
    msg_data = msg_resp.json()["data"]
    assert msg_data["content"] == "Salom haydovchi, yuk yuklashga tayyor!"

    # 5. Verify Unassigned Driver cannot fetch messages (403 forbidden)
    unassigned_fetch = await client.get(f"/api/v1/chat/{shipment_id}", headers=driver_headers)
    assert unassigned_fetch.status_code == 403

    # 6. Driver bids and Shipper accepts bid -> Carrier assigned
    bid_resp = await client.post(f"/api/v1/shipments/{shipment_id}/bids", headers=driver_headers, json={
        "bid_amount": 8500000.0,
    })
    assert bid_resp.status_code == 200
    bid_id = bid_resp.json()["data"]["bids"][0]["id"]
    await client.post(f"/api/v1/shipments/{shipment_id}/bids/{bid_id}/accept", headers=shipper_headers)

    # Now assigned Driver can fetch messages
    get_msgs_resp = await client.get(f"/api/v1/chat/{shipment_id}", headers=driver_headers)
    assert get_msgs_resp.status_code == 200
    messages = get_msgs_resp.json()["data"]
    assert len(messages) >= 1

    # 7. Check WebRTC ICE servers endpoint
    ice_resp = await client.get("/api/v1/calls/ice-servers", headers=shipper_headers)
    assert ice_resp.status_code == 200
    assert "iceServers" in ice_resp.json()["data"]

    # 8. Verify Call blocked before escrow funding
    blocked_call = await client.post("/api/v1/calls/initiate", headers=shipper_headers, json={
        "receiverId": driver_id,
        "shipmentId": shipment_id,
        "type": "audio",
    })
    assert blocked_call.status_code in [400, 403]

    # Fund escrow via status update or escrow endpoint
    await client.post(f"/api/v1/shipments/{shipment_id}/status", headers=shipper_headers, json={
        "next_status": "escrowFunded",
    })

    # Initiate Audio Call (now succeeds because escrow is funded)
    call_resp = await client.post("/api/v1/calls/initiate", headers=shipper_headers, json={
        "receiverId": driver_id,
        "shipmentId": shipment_id,
        "type": "audio",
    })
    assert call_resp.status_code == 200
    call_id = call_resp.json()["data"]["id"]

    # 8. End Call & verify call log recorded
    end_resp = await client.post(f"/api/v1/calls/{call_id}/status", headers=shipper_headers, json={
        "status": "ended",
        "durationSeconds": 45,
    })
    assert end_resp.status_code == 200

    # 9. Verify Call History
    history_resp = await client.get("/api/v1/calls/history", headers=shipper_headers)
    assert history_resp.status_code == 200
    history = history_resp.json()["data"]
    assert len(history) >= 1
