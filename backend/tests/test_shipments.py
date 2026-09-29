import pytest
from httpx import AsyncClient

@pytest.mark.asyncio
async def test_shipment_crud_and_bidding_lifecycle(client: AsyncClient):
    # 1. Register Shipper
    shipper_resp = await client.post("/api/v1/auth/register", json={
        "fullName": "Shipper Corp",
        "email": "shipper_corp@test.uz",
        "phone": "+998901110001",
        "password": "Password123!",
        "role": "shipper",
    })
    shipper_token = shipper_resp.json()["data"]["access_token"]
    shipper_headers = {"Authorization": f"Bearer {shipper_token}"}

    # 2. Register Carrier
    carrier_resp = await client.post("/api/v1/auth/register", json={
        "fullName": "Carrier Trans",
        "email": "carrier_trans@test.uz",
        "phone": "+998901110002",
        "password": "Password123!",
        "role": "carrier",
    })
    carrier_token = carrier_resp.json()["data"]["access_token"]
    carrier_headers = {"Authorization": f"Bearer {carrier_token}"}

    # 3. Shipper creates new freight load
    load_payload = {
        "origin": {
            "city": "Tashkent",
            "address": "Sergeli Hub",
            "latitude": 41.22,
            "longitude": 69.21,
        },
        "destination": {
            "city": "Samarkand",
            "address": "Registan Logistics",
            "latitude": 39.65,
            "longitude": 66.95,
        },
        "cargoTitle": "Textile Fabrics & Yarn",
        "cargoType": "Standard Curtain",
        "weightTons": 20.0,
        "volumeM3": 80.0,
        "price": 15000000.0,
        "distanceKm": 310.0,
        "eta": "4 hours",
    }
    create_resp = await client.post("/api/v1/loads", json=load_payload, headers=shipper_headers)
    assert create_resp.status_code == 201
    shipment = create_resp.json()["data"]
    shipment_id = shipment["id"]
    assert shipment["cargo_title"] == "Textile Fabrics & Yarn"
    assert shipment["status"] == "created"

    # 4. Carrier submits bid
    bid_payload = {
        "driverName": "Sardor Driver",
        "vehicleModel": "Volvo FH 500",
        "plateNumber": "01 777 ABC",
        "bidAmount": 14500000.0,
        "comment": "Ready for loading today at 14:00",
    }
    bid_resp = await client.post(f"/api/v1/loads/{shipment_id}/bids", json=bid_payload, headers=carrier_headers)
    assert bid_resp.status_code == 200
    updated_shipment = bid_resp.json()["data"]
    assert len(updated_shipment["bids"]) == 1
    bid_id = updated_shipment["bids"][0]["id"]
    assert updated_shipment["status"] == "pendingBid"

    # 5. Shipper accepts bid
    accept_resp = await client.post(f"/api/v1/loads/{shipment_id}/bids/{bid_id}/accept", headers=shipper_headers)
    assert accept_resp.status_code == 200
    accepted_shipment = accept_resp.json()["data"]
    assert accepted_shipment["status"] == "carrierAssigned"
    assert accepted_shipment["carrier_id"] is not None
