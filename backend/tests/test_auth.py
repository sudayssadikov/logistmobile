import pytest
from httpx import AsyncClient

@pytest.mark.asyncio
async def test_register_and_login_flow(client: AsyncClient):
    # 1. Register new shipper
    reg_payload = {
        "fullName": "Test Shipper",
        "email": "shipper@test.uz",
        "phone": "+998901112233",
        "password": "SecurePassword123!",
        "role": "shipper",
        "companyName": "Test Logistics LLC",
    }
    resp = await client.post("/api/v1/auth/register", json=reg_payload)
    assert resp.status_code == 201
    data = resp.json()
    assert data["success"] is True
    assert "access_token" in data["data"]
    assert data["data"]["user"]["email"] == "shipper@test.uz"

    # 2. Login with correct credentials
    login_payload = {
        "emailOrPhone": "shipper@test.uz",
        "password": "SecurePassword123!",
        "role": "shipper",
    }
    login_resp = await client.post("/api/v1/auth/login", json=login_payload)
    assert login_resp.status_code == 200
    login_data = login_resp.json()
    assert login_data["success"] is True
    token = login_data["data"]["access_token"]
    refresh_token = login_data["data"]["refresh_token"]

    # 3. Access protected profile endpoint
    headers = {"Authorization": f"Bearer {token}"}
    me_resp = await client.get("/api/v1/auth/me", headers=headers)
    assert me_resp.status_code == 200
    assert me_resp.json()["data"]["full_name"] == "Test Shipper"

    # 4. Refresh token rotation
    ref_resp = await client.post("/api/v1/auth/refresh", json={"refreshToken": refresh_token})
    assert ref_resp.status_code == 200
    assert "access_token" in ref_resp.json()["data"]

@pytest.mark.asyncio
async def test_login_invalid_password(client: AsyncClient):
    # Register user first
    await client.post("/api/v1/auth/register", json={
        "fullName": "Carrier Test",
        "email": "carrier@test.uz",
        "phone": "+998902223344",
        "password": "CorrectPassword123",
        "role": "carrier",
    })

    # Wrong password attempt
    resp = await client.post("/api/v1/auth/login", json={
        "emailOrPhone": "carrier@test.uz",
        "password": "WrongPassword!",
        "role": "carrier",
    })
    assert resp.status_code == 401
    assert resp.json()["success"] is False

@pytest.mark.asyncio
async def test_otp_verification_flow(client: AsyncClient):
    # Send OTP
    send_resp = await client.post("/api/v1/auth/send-otp", json={"phone": "+998909876543"})
    assert send_resp.status_code == 200
    assert send_resp.json()["data"] is True

    # Verify OTP
    verify_resp = await client.post("/api/v1/auth/verify-otp", json={
        "phone": "+998909876543",
        "otp": "1234",
        "role": "driver",
    })
    assert verify_resp.status_code == 200
    assert "access_token" in verify_resp.json()["data"]
