from datetime import datetime, timedelta, timezone
import pytest
from httpx import AsyncClient

@pytest.mark.asyncio
async def test_driver_cannot_create_load(client: AsyncClient):
    # 1. Driver ro'yxatdan o'tadi va kiradi
    await client.post("/api/v1/auth/register", json={
        "fullName": "Haydovchi Shokir",
        "email": "shokir.driver@test.uz",
        "phone": "+998901239901",
        "password": "Password123!",
        "role": "driver",
    })
    login_resp = await client.post("/api/v1/auth/login", json={
        "emailOrPhone": "shokir.driver@test.uz",
        "password": "Password123!",
        "role": "driver",
    })
    token = login_resp.json()["data"]["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    payload = {
        "cargoName": "Meva-sabzavot",
        "cargoType": "oziq_ovqat",
        "weightTons": 15.0,
        "volumeM3": 60.0,
        "truckType": "REFRIGERATOR",
        "fromLat": 41.2995,
        "fromLng": 69.2401,
        "fromAddress": "Toshkent, Chilonzor ombori",
        "fromRegion": "Toshkent shahri",
        "fromCity": "Chilonzor",
        "toLat": 39.6542,
        "toLng": 66.9597,
        "toAddress": "Samarqand, Markaziy bozor",
        "toRegion": "Samarqand viloyati",
        "toCity": "Samarqand",
        "pickupDate": (datetime.now(timezone.utc) + timedelta(days=2)).isoformat(),
        "priceUzs": 4500000.0,
        "priceNegotiable": False,
    }

    # Driver yuk yaratolmasligi kerak -> 403 Forbidden
    resp = await client.post("/api/v1/loads", json=payload, headers=headers)
    assert resp.status_code == 403

@pytest.mark.asyncio
async def test_shipper_create_load_success_and_owner_get(client: AsyncClient):
    # 1. Shipper yaratamiz
    await client.post("/api/v1/auth/register", json={
        "fullName": "Yukchi Akmal",
        "email": "akmal.shipper@test.uz",
        "phone": "+998901239902",
        "password": "Password123!",
        "role": "shipper",
    })
    login_resp = await client.post("/api/v1/auth/login", json={
        "emailOrPhone": "akmal.shipper@test.uz",
        "password": "Password123!",
        "role": "shipper",
    })
    token = login_resp.json()["data"]["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    payload = {
        "cargoName": "Qurilish g'ishti",
        "cargoType": "qurilish_materiallari",
        "weightTons": 22.5,
        "truckType": "TENT",
        "fromLat": 41.2995,
        "fromLng": 69.2401,
        "fromAddress": "Toshkent, Sergeli",
        "fromRegion": "Toshkent shahri",
        "fromCity": "Sergeli",
        "toLat": 40.8154,
        "toLng": 68.6611,
        "toAddress": "Guliston, Sanoat hududi",
        "toRegion": "Sirdaryo viloyati",
        "toCity": "Guliston",
        "pickupDate": (datetime.now(timezone.utc) + timedelta(days=1)).isoformat(),
        "priceUzs": 3200000.0,
        "priceNegotiable": False,
        "description": "22 tonna qizil g'isht, palletda",
    }

    resp = await client.post("/api/v1/loads", json=payload, headers=headers)
    assert resp.status_code == 201
    data = resp.json()["data"]
    assert data["status"] == "ACTIVE"
    assert data["distanceKm"] > 50.0
    load_id = data["id"]

    # Egasi yukni o'qiy olishi kerak
    get_resp = await client.get(f"/api/v1/loads/{load_id}", headers=headers)
    assert get_resp.status_code == 200
    assert get_resp.json()["data"]["id"] == load_id

@pytest.mark.asyncio
async def test_shipper_create_load_price_negotiable(client: AsyncClient):
    await client.post("/api/v1/auth/register", json={
        "fullName": "Zavod Jamshid",
        "email": "jamshid@test.uz",
        "phone": "+998901239903",
        "password": "Password123!",
        "role": "shipper",
    })
    login_resp = await client.post("/api/v1/auth/login", json={
        "emailOrPhone": "jamshid@test.uz",
        "password": "Password123!",
        "role": "shipper",
    })
    token = login_resp.json()["data"]["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # Narx ko'rsatilmagan, lekin priceNegotiable=True
    payload = {
        "cargoName": "Mebel jamlanmasi",
        "cargoType": "mebel_maishiy",
        "weightTons": 5.0,
        "truckType": "ISOTHERMAL",
        "fromLat": 41.2995,
        "fromLng": 69.2401,
        "fromAddress": "Toshkent, Yakkasaroy",
        "fromRegion": "Toshkent shahri",
        "fromCity": "Yakkasaroy",
        "toLat": 40.5000,
        "toLng": 70.9000,
        "toAddress": "Qo'qon, Markaz",
        "toRegion": "Farg'ona viloyati",
        "toCity": "Qo'qon",
        "pickupDate": (datetime.now(timezone.utc) + timedelta(days=3)).isoformat(),
        "priceUzs": None,
        "priceNegotiable": True,
    }

    resp = await client.post("/api/v1/loads", json=payload, headers=headers)
    assert resp.status_code == 201
    assert resp.json()["data"]["priceNegotiable"] is True
    assert resp.json()["data"]["priceUzs"] is None

@pytest.mark.asyncio
async def test_validation_rules(client: AsyncClient):
    await client.post("/api/v1/auth/register", json={
        "fullName": "Test Val",
        "email": "val@test.uz",
        "phone": "+998901239904",
        "password": "Password123!",
        "role": "shipper",
    })
    login_resp = await client.post("/api/v1/auth/login", json={
        "emailOrPhone": "val@test.uz",
        "password": "Password123!",
        "role": "shipper",
    })
    token = login_resp.json()["data"]["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    base_payload = {
        "cargoName": "Test yuk",
        "cargoType": "boshqa",
        "weightTons": 10.0,
        "truckType": "TENT",
        "fromLat": 41.3000,
        "fromLng": 69.2400,
        "fromAddress": "A nuqta",
        "fromRegion": "Toshkent",
        "fromCity": "Toshkent",
        "toLat": 41.4000,
        "toLng": 69.3000,
        "toAddress": "B nuqta",
        "toRegion": "Toshkent viloyati",
        "toCity": "Chirchiq",
        "pickupDate": (datetime.now(timezone.utc) + timedelta(days=1)).isoformat(),
        "priceUzs": 1000000.0,
        "priceNegotiable": False,
    }

    # 1. Og'irlik xatosi (> 60t)
    p1 = {**base_payload, "weightTons": 75.0}
    r1 = await client.post("/api/v1/loads", json=p1, headers=headers)
    assert r1.status_code == 422

    # 2. Bir xil nuqta (masofa < 1 km)
    p2 = {**base_payload, "toLat": 41.3001, "toLng": 69.2401}
    r2 = await client.post("/api/v1/loads", json=p2, headers=headers)
    assert r2.status_code == 422

    # 3. O'tgan sana
    p3 = {**base_payload, "pickupDate": (datetime.now(timezone.utc) - timedelta(days=2)).isoformat()}
    r3 = await client.post("/api/v1/loads", json=p3, headers=headers)
    assert r3.status_code == 422

    # 4. Narx ham yo'q, kelishiladi ham False
    p4 = {**base_payload, "priceUzs": None, "priceNegotiable": False}
    r4 = await client.post("/api/v1/loads", json=p4, headers=headers)
    assert r4.status_code == 422

