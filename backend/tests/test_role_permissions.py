from datetime import datetime, timedelta, timezone
import pytest
from httpx import AsyncClient
from app.core.enums import UserRole

@pytest.mark.asyncio
async def test_role_mismatch_login_prevention(client: AsyncClient):
    # 1. Ro'yxatdan haydovchi (DRIVER) sifatida o'tish
    driver_reg = {
        "fullName": "Haydovchi Ali",
        "email": "ali.driver@test.uz",
        "phone": "+998901234501",
        "password": "Password123!",
        "role": "driver",
    }
    reg_resp = await client.post("/api/v1/auth/register", json=driver_reg)
    assert reg_resp.status_code == 201

    # 2. Haydovchi akkauntiga YUK BERUVCHI (shipper) roli bilan kirishga urinish
    # Kirish rad etilishi kerak va aniq xato berilishi kerak
    mismatch_login = {
        "emailOrPhone": "ali.driver@test.uz",
        "password": "Password123!",
        "role": "shipper",
    }
    resp = await client.post("/api/v1/auth/login", json=mismatch_login)
    assert resp.status_code == 401
    res_data = resp.json()
    err_msg = res_data.get("message") or res_data.get("detail", "")
    assert "haydovchi sifatida ro'yxatdan o'tgan" in err_msg

    # 3. To'g'ri (DRIVER) roli bilan kirish muvaffaqiyatli bo'lishi kerak
    correct_login = {
        "emailOrPhone": "ali.driver@test.uz",
        "password": "Password123!",
        "role": "driver",
    }
    correct_resp = await client.post("/api/v1/auth/login", json=correct_login)
    assert correct_resp.status_code == 200
    data = correct_resp.json()["data"]
    assert data["user"]["role"] == "driver"

@pytest.mark.asyncio
async def test_shipper_role_mismatch_login_prevention(client: AsyncClient):
    # 1. Ro'yxatdan yuk beruvchi (SHIPPER) sifatida o'tish
    shipper_reg = {
        "fullName": "Zavod Valixon",
        "email": "vali.shipper@test.uz",
        "phone": "+998901234502",
        "password": "Password123!",
        "role": "shipper",
    }
    reg_resp = await client.post("/api/v1/auth/register", json=shipper_reg)
    assert reg_resp.status_code == 201

    # 2. Yuk beruvchi akkauntiga HAYDOVCHI (driver) roli bilan kirishga urinish
    mismatch_login = {
        "emailOrPhone": "vali.shipper@test.uz",
        "password": "Password123!",
        "role": "driver",
    }
    resp = await client.post("/api/v1/auth/login", json=mismatch_login)
    assert resp.status_code == 401
    res_data = resp.json()
    err_msg = res_data.get("message") or res_data.get("detail", "")
    assert "yuk beruvchi sifatida ro'yxatdan o'tgan" in err_msg

@pytest.mark.asyncio
async def test_require_role_shipper_protection(client: AsyncClient):
    # 1. Haydovchi va Shipper yaratamiz
    await client.post("/api/v1/auth/register", json={
        "fullName": "Driver Bobur",
        "email": "bobur@test.uz",
        "phone": "+998901234503",
        "password": "Password123!",
        "role": "driver",
    })
    driver_login = await client.post("/api/v1/auth/login", json={
        "emailOrPhone": "bobur@test.uz",
        "password": "Password123!",
        "role": "driver",
    })
    driver_token = driver_login.json()["data"]["access_token"]

    await client.post("/api/v1/auth/register", json={
        "fullName": "Shipper Sardor",
        "email": "sardor@test.uz",
        "phone": "+998901234504",
        "password": "Password123!",
        "role": "shipper",
    })
    shipper_login = await client.post("/api/v1/auth/login", json={
        "emailOrPhone": "sardor@test.uz",
        "password": "Password123!",
        "role": "shipper",
    })
    shipper_token = shipper_login.json()["data"]["access_token"]

    load_payload = {
        "cargoName": "Qurilish materiallari 20t",
        "cargoType": "qurilish_materiallari",
        "weightTons": 20.0,
        "volumeM3": 80.0,
        "truckType": "TENT",
        "fromLat": 41.22,
        "fromLng": 69.21,
        "fromAddress": "Toshkent, Sergeli sanoat zonasi",
        "fromRegion": "Toshkent shahri",
        "fromCity": "Sergeli",
        "toLat": 39.65,
        "toLng": 66.97,
        "toAddress": "Samarqand, Markaziy ombor",
        "toRegion": "Samarqand viloyati",
        "toCity": "Samarqand",
        "pickupDate": (datetime.now(timezone.utc) + timedelta(days=2)).isoformat(),
        "priceUzs": 5000000.0,
        "priceNegotiable": False,
    }

    # Haydovchi yuk qo'shishga urinsa -> 403 Forbidden
    driver_headers = {"Authorization": f"Bearer {driver_token}"}
    resp_driver = await client.post("/api/v1/loads", json=load_payload, headers=driver_headers)
    assert resp_driver.status_code == 403

    # Shipper yuk qo'shsa -> 201 Created
    shipper_headers = {"Authorization": f"Bearer {shipper_token}"}
    resp_shipper = await client.post("/api/v1/loads", json=load_payload, headers=shipper_headers)
    assert resp_shipper.status_code == 201

@pytest.mark.asyncio
async def test_switch_role_forbidden(client: AsyncClient):
    # Ro'yxatdan o'tgandan so'ng rolni o'zgartirish taqiqlangan (bitta akkaunt = bitta rol)
    await client.post("/api/v1/auth/register", json={
        "fullName": "Kamron",
        "email": "kamron@test.uz",
        "phone": "+998901234505",
        "password": "Password123!",
        "role": "driver",
    })
    login_resp = await client.post("/api/v1/auth/login", json={
        "emailOrPhone": "kamron@test.uz",
        "password": "Password123!",
        "role": "driver",
    })
    token = login_resp.json()["data"]["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    switch_resp = await client.post("/api/v1/auth/switch-role", json={"newRole": "shipper"}, headers=headers)
    assert switch_resp.status_code == 400
