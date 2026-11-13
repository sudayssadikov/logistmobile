from datetime import datetime, timedelta, timezone
import pytest
from httpx import AsyncClient

@pytest.mark.asyncio
async def test_smoke_part2_end_to_end_flow(client: AsyncClient):
    # 1. Yuk beruvchi va Haydovchi akkauntlarini yaratish va login qilish
    shipper_email = "smoke_shipper@logiflow.uz"
    shipper_phone = "+998901239991"
    shipper_pass = "SmokePass123!"

    reg_shipper_resp = await client.post("/api/v1/auth/register", json={
        "fullName": "Smoke Shipper OOO",
        "email": shipper_email,
        "phone": shipper_phone,
        "password": shipper_pass,
        "role": "shipper",
        "companyName": "Smoke Logistics LLC",
    })
    assert reg_shipper_resp.status_code == 201, f"Shipper reg failed: {reg_shipper_resp.text}"

    login_shipper_resp = await client.post("/api/v1/auth/login", json={
        "emailOrPhone": shipper_email,
        "password": shipper_pass,
        "role": "shipper",
    })
    assert login_shipper_resp.status_code == 200, f"Shipper login failed: {login_shipper_resp.text}"
    shipper_token = login_shipper_resp.json()["data"]["access_token"]
    shipper_headers = {"Authorization": f"Bearer {shipper_token}"}

    driver_email = "smoke_driver@logiflow.uz"
    driver_phone = "+998901239992"
    driver_pass = "DriverPass123!"

    reg_driver_resp = await client.post("/api/v1/auth/register", json={
        "fullName": "Smoke Driver Botir",
        "email": driver_email,
        "phone": driver_phone,
        "password": driver_pass,
        "role": "driver",
    })
    assert reg_driver_resp.status_code == 201, f"Driver reg failed: {reg_driver_resp.text}"

    login_driver_resp = await client.post("/api/v1/auth/login", json={
        "emailOrPhone": driver_email,
        "password": driver_pass,
        "role": "driver",
    })
    assert login_driver_resp.status_code == 200, f"Driver login failed: {login_driver_resp.text}"
    driver_token = login_driver_resp.json()["data"]["access_token"]
    driver_headers = {"Authorization": f"Bearer {driver_token}"}

    # 2. Yuk beruvchi bilan POST /loads yuborish (xarita koordinatalari bilan)
    pickup_time = (datetime.now(timezone.utc) + timedelta(days=2)).isoformat()
    load_payload = {
        "cargoName": "Qurilish materiallari (Armatura)",
        "cargoType": "qurilish_materiallari",
        "weightTons": 22.0,
        "volumeM3": 85.0,
        "truckType": "TENT",
        "fromLat": 41.2995,
        "fromLng": 69.2401,
        "fromAddress": "Toshkent, Sergeli sanoat zonasi, 4-bino",
        "fromRegion": "Toshkent shahri",
        "fromCity": "Sergeli",
        "toLat": 39.6542,
        "toLng": 66.9597,
        "toAddress": "Samarqand, Temiryo'l ombori",
        "toRegion": "Samarqand viloyati",
        "toCity": "Samarqand",
        "pickupDate": pickup_time,
        "priceUzs": 4500000.0,
        "priceNegotiable": False,
        "description": "22t armatura, usti yopiq tent kerak",
        "photos": ["https://cdn.logiflow.uz/photos/armatura1.jpg"],
    }

    create_resp = await client.post("/api/v1/loads", json=load_payload, headers=shipper_headers)
    assert create_resp.status_code == 201, f"Create load failed: {create_resp.text}"
    create_data = create_resp.json()["data"]
    assert create_data["status"] == "ACTIVE"
    assert create_data["cargoName"] == "Qurilish materiallari (Armatura)"
    assert create_data["distanceKm"] > 250.0  # Toshkent-Samarqand masofasi ~270 km
    load_id = create_data["id"]

    # 3. GET /loads/{id} da barcha maydonlar to'g'ri saqlanganini tekshirish
    get_resp = await client.get(f"/api/v1/loads/{load_id}", headers=shipper_headers)
    assert get_resp.status_code == 200, f"Get load failed: {get_resp.text}"
    load_details = get_resp.json()["data"]
    assert load_details["id"] == load_id
    assert load_details["status"] == "ACTIVE"
    assert load_details["cargoName"] == "Qurilish materiallari (Armatura)"
    assert load_details["cargoType"] == "qurilish_materiallari"
    assert load_details["weightTons"] == 22.0
    assert load_details["volumeM3"] == 85.0
    assert load_details["truckType"] == "TENT"
    assert load_details["fromLat"] == 41.2995
    assert load_details["fromLng"] == 69.2401
    assert load_details["fromRegion"] == "Toshkent shahri"
    assert load_details["toLat"] == 39.6542
    assert load_details["toLng"] == 66.9597
    assert load_details["toRegion"] == "Samarqand viloyati"
    assert load_details["priceUzs"] == 4500000.0
    assert load_details["priceNegotiable"] is False
    assert "photos" in load_details
    assert len(load_details["photos"]) == 1

    # 4. Haydovchi tokeni bilan POST /loads yuborganda 403 qaytishini tekshirish
    driver_create_resp = await client.post("/api/v1/loads", json=load_payload, headers=driver_headers)
    assert driver_create_resp.status_code == 403, "Driver must be forbidden (403) from creating loads"

    # 5. Xato holatlar:
    # a) Narx ham yo'q, 'kelishiladi' ham yo'q -> 422
    invalid_price_payload = {**load_payload, "priceUzs": None, "priceNegotiable": False}
    resp_err_price = await client.post("/api/v1/loads", json=invalid_price_payload, headers=shipper_headers)
    assert resp_err_price.status_code == 422

    # b) Bir xil from/to nuqta (masofa < 1 km) -> 422
    same_coords_payload = {**load_payload, "toLat": 41.2996, "toLng": 69.2402}
    resp_err_coords = await client.post("/api/v1/loads", json=same_coords_payload, headers=shipper_headers)
    assert resp_err_coords.status_code == 422

    # c) O'tgan sana -> 422
    past_date_payload = {**load_payload, "pickupDate": (datetime.now(timezone.utc) - timedelta(days=3)).isoformat()}
    resp_err_date = await client.post("/api/v1/loads", json=past_date_payload, headers=shipper_headers)
    assert resp_err_date.status_code == 422

    # d) Og'irlik 0 (yoki 0.1 dan kichik) -> 422
    zero_weight_payload = {**load_payload, "weightTons": 0.0}
    resp_err_weight = await client.post("/api/v1/loads", json=zero_weight_payload, headers=shipper_headers)
    assert resp_err_weight.status_code == 422

