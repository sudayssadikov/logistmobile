import pytest
from httpx import AsyncClient
from datetime import datetime, timezone, timedelta
from app.config.settings import settings

async def _register_and_login(client: AsyncClient, email: str, role: str, phone: str = "+998901112233") -> dict:
    await client.post(
        "/api/v1/auth/register",
        json={
            "fullName": f"User {email}",
            "email": email,
            "phone": phone,
            "password": "Password123!",
            "role": role,
        },
    )
    res = await client.post(
        "/api/v1/auth/login",
        json={
            "emailOrPhone": email,
            "password": "Password123!",
            "role": role,
        },
    )
    token = res.json()["data"]["access_token"]
    return {"Authorization": f"Bearer {token}"}

async def _create_test_load(client: AsyncClient, headers: dict, cargo_name: str = "G'ishtlar", price: float = 3000000.0) -> dict:
    payload = {
        "cargoName": cargo_name,
        "cargoType": "qurilish_materiallari",
        "weightTons": 10.0,
        "volumeM3": 25.0,
        "truckType": "TENT",
        "fromLat": 41.2995,
        "fromLng": 69.2401,
        "fromAddress": "Toshkent, Chilonzor",
        "fromRegion": "Toshkent shahri",
        "fromCity": "Toshkent",
        "toLat": 39.6542,
        "toLng": 66.9597,
        "toAddress": "Samarqand markaz",
        "toRegion": "Samarqand viloyati",
        "toCity": "Samarqand",
        "pickupDate": (datetime.now(timezone.utc) + timedelta(days=2)).isoformat(),
        "priceUzs": price,
        "priceNegotiable": False,
        "description": "Boshlang'ich izoh",
    }
    res = await client.post("/api/v1/loads", json=payload, headers=headers)
    assert res.status_code == 201
    return res.json()["data"]

# 1. PATCH matritsasi
@pytest.mark.asyncio
async def test_patch_matrix_rules(client: AsyncClient):
    headers = await _register_and_login(client, "patch_shipper@test.uz", "shipper", "+998902000001")
    load = await _create_test_load(client, headers, "Sinov Yuki 1")
    load_id = load["id"]
    updated_at = load["updatedAt"]

    # a) ACTIVE holatda barcha maydonlarni tahrirlash mumkin
    patch_active = await client.patch(
        f"/api/v1/loads/{load_id}",
        json={
            "updatedAt": updated_at,
            "cargoName": "Yangilangan Yuki",
            "weightTons": 14.0,
            "volumeM3": 35.0,
            "truckType": "REFRIGERATOR",
            "fromCity": "Chirchiq",
            "fromRegion": "Toshkent viloyati",
            "fromAddress": "Chirchiq sanoat hududi",
            "fromLat": 41.4689,
            "fromLng": 69.5828,
            "priceUzs": 3500000.0,
            "description": "Yangilangan izoh",
        },
        headers=headers,
    )
    assert patch_active.status_code == 200
    res_data = patch_active.json()["data"]
    assert res_data["cargoName"] == "Yangilangan Yuki"
    assert res_data["weightTons"] == 14.0
    assert res_data["truckType"] == "REFRIGERATOR"
    updated_at = res_data["updatedAt"]

    # b) ASSIGNED holatda faqat izoh/rasm/soat; marshrut/vazn/narx 409
    await client.post(f"/api/v1/loads/{load_id}/dev-status?new_status=ASSIGNED", headers=headers)
    
    forbidden_weight = await client.patch(
        f"/api/v1/loads/{load_id}",
        json={"updatedAt": updated_at, "weightTons": 18.0},
        headers=headers,
    )
    assert forbidden_weight.status_code == 409
    assert "Haydovchi tayinlangan" in forbidden_weight.json()["detail"]

    forbidden_price = await client.patch(
        f"/api/v1/loads/{load_id}",
        json={"updatedAt": updated_at, "priceUzs": 5000000.0},
        headers=headers,
    )
    assert forbidden_price.status_code == 409

    forbidden_route = await client.patch(
        f"/api/v1/loads/{load_id}",
        json={"updatedAt": updated_at, "toCity": "Buxoro"},
        headers=headers,
    )
    assert forbidden_route.status_code == 409

    # Izoh va olib ketish soatini o'zgartirish esa ruxsat etiladi
    allowed_patch = await client.patch(
        f"/api/v1/loads/{load_id}",
        json={
            "updatedAt": updated_at,
            "description": "Haydovchi uchun qo'shimcha eslatma",
            "pickupDate": (datetime.now(timezone.utc) + timedelta(days=2, hours=3)).isoformat(),
        },
        headers=headers,
    )
    assert allowed_patch.status_code == 200
    updated_at = allowed_patch.json()["data"]["updatedAt"]

    # c) IN_TRANSIT, DELIVERED, CANCELLED holatlarida tahrir 409
    for st in ["IN_TRANSIT", "DELIVERED", "CANCELLED"]:
        await client.post(f"/api/v1/loads/{load_id}/dev-status?new_status={st}", headers=headers)
        res_blocked = await client.patch(
            f"/api/v1/loads/{load_id}",
            json={"updatedAt": updated_at, "description": "Failed attempt"},
            headers=headers,
        )
        assert res_blocked.status_code == 409

# 2. Parallel tahrir (Optimistic lock)
@pytest.mark.asyncio
async def test_parallel_edit_optimistic_concurrency(client: AsyncClient):
    headers = await _register_and_login(client, "concurrency_shipper@test.uz", "shipper", "+998902000002")
    load = await _create_test_load(client, headers, "Parallel Test Yuki")
    load_id = load["id"]
    updated_at = load["updatedAt"]

    # 1-mijoz tahrir qildi
    patch1 = await client.patch(
        f"/api/v1/loads/{load_id}",
        json={"updatedAt": updated_at, "cargoName": "Birinchi mijoz tahriri"},
        headers=headers,
    )
    assert patch1.status_code == 200

    # 2-mijoz eski updated_at bilan tahrirlamoqchi -> 409 Conflict
    patch2 = await client.patch(
        f"/api/v1/loads/{load_id}",
        json={"updatedAt": updated_at, "cargoName": "Eski versiya tahriri"},
        headers=headers,
    )
    assert patch2.status_code == 409
    assert "Yuk boshqa joyda o'zgartirilgan" in patch2.json()["detail"]

# 3. Cancel matritsasi
@pytest.mark.asyncio
async def test_cancel_matrix_rules(client: AsyncClient):
    headers = await _register_and_login(client, "cancel_shipper@test.uz", "shipper", "+998902000003")
    
    # a) ACTIVE yukni bekor qilish -> 200 OK
    load_active = await _create_test_load(client, headers, "Active Cancel")
    res_cancel_active = await client.post(f"/api/v1/loads/{load_active['id']}/cancel", headers=headers)
    assert res_cancel_active.status_code == 200
    assert res_cancel_active.json()["data"]["status"] == "CANCELLED"

    # b) Qayta bekor qilish -> 409 Conflict
    res_recancel = await client.post(f"/api/v1/loads/{load_active['id']}/cancel", headers=headers)
    assert res_recancel.status_code == 409

    # c) ASSIGNED yukni bekor qilish -> 200 OK
    load_assigned = await _create_test_load(client, headers, "Assigned Cancel")
    await client.post(f"/api/v1/loads/{load_assigned['id']}/dev-status?new_status=ASSIGNED", headers=headers)
    res_cancel_assigned = await client.post(f"/api/v1/loads/{load_assigned['id']}/cancel", headers=headers)
    assert res_cancel_assigned.status_code == 200
    assert res_cancel_assigned.json()["data"]["status"] == "CANCELLED"

    # d) IN_TRANSIT yukni bekor qilish -> 409 Conflict
    load_intransit = await _create_test_load(client, headers, "In Transit Cancel")
    await client.post(f"/api/v1/loads/{load_intransit['id']}/dev-status?new_status=IN_TRANSIT", headers=headers)
    res_cancel_intransit = await client.post(f"/api/v1/loads/{load_intransit['id']}/cancel", headers=headers)
    assert res_cancel_intransit.status_code == 409
    assert "Yo'ldagi yukni bekor qilish" in res_cancel_intransit.json()["detail"]

    # e) DELIVERED yukni bekor qilish -> 409 Conflict
    load_delivered = await _create_test_load(client, headers, "Delivered Cancel")
    await client.post(f"/api/v1/loads/{load_delivered['id']}/dev-status?new_status=DELIVERED", headers=headers)
    res_cancel_delivered = await client.post(f"/api/v1/loads/{load_delivered['id']}/cancel", headers=headers)
    assert res_cancel_delivered.status_code == 409

# 4. Cancel + Escrow qaytarilishi
@pytest.mark.asyncio
async def test_cancel_with_escrow_refund_and_zero_commission(client: AsyncClient):
    headers = await _register_and_login(client, "escrow_shipper@test.uz", "shipper", "+998902000004")
    load = await _create_test_load(client, headers, "Escrow Refund Load", price=4000000.0)
    load_id = load["id"]

    # Yukni ASSIGNED qilib, escrow_funded va carrier bog'laymiz
    await client.post(f"/api/v1/loads/{load_id}/dev-status?new_status=ASSIGNED", headers=headers)

    # Bekor qilamiz
    res_cancel = await client.post(
        f"/api/v1/loads/{load_id}/cancel",
        json={"reason": "Haydovchi kelmadi"},
        headers=headers,
    )
    assert res_cancel.status_code == 200
    assert res_cancel.json()["data"]["status"] == "CANCELLED"
    assert res_cancel.json()["data"]["isEscrowFunded"] is False

# 5. Duplicate
@pytest.mark.asyncio
async def test_duplicate_load(client: AsyncClient):
    headers = await _register_and_login(client, "dup_shipper@test.uz", "shipper", "+998902000005")
    load = await _create_test_load(client, headers, "Asl Yuk")
    load_id = load["id"]

    res_dup = await client.post(f"/api/v1/loads/{load_id}/duplicate", headers=headers)
    assert res_dup.status_code == 201
    dup_load = res_dup.json()["data"]

    # Yangi ACTIVE yuk, id har xil, sana tozalangan
    assert dup_load["id"] != load_id
    assert dup_load["status"] == "ACTIVE"
    assert "(Nusxa)" in dup_load["cargoName"]
    assert dup_load["pickupDate"] is not None

    # Asl yuk o'zgarmagan
    res_orig = await client.get(f"/api/v1/loads/{load_id}", headers=headers)
    assert res_orig.status_code == 200
    assert res_orig.json()["data"]["cargoName"] == "Asl Yuk"

# 6. Events tartibi va qayd etilishi
@pytest.mark.asyncio
async def test_load_events_recorded_and_ordered(client: AsyncClient):
    headers = await _register_and_login(client, "events_shipper@test.uz", "shipper", "+998902000006")
    load = await _create_test_load(client, headers, "Hodisali Yuk")
    load_id = load["id"]
    updated_at = load["updatedAt"]

    # Tahrir
    patch_res = await client.patch(
        f"/api/v1/loads/{load_id}",
        json={"updatedAt": updated_at, "cargoName": "Tahrirlangan Hodisali Yuk"},
        headers=headers,
    )
    assert patch_res.status_code == 200

    # Bekor qilish
    cancel_res = await client.post(f"/api/v1/loads/{load_id}/cancel", headers=headers)
    assert cancel_res.status_code == 200

    # Events tekshirish
    events_res = await client.get(f"/api/v1/loads/{load_id}/events", headers=headers)
    assert events_res.status_code == 200
    events = events_res.json()["data"]
    types = [e["eventType"] for e in events]

    assert "CREATED" in types
    assert "EDITED" in types
    assert "CANCELLED" in types
    # Tartibli (eng yangisi birinchi yoki desc)
    assert len(events) >= 3

# 7. GET /loads/mine va status_group
@pytest.mark.asyncio
async def test_get_loads_mine_status_group_and_pagination(client: AsyncClient):
    headers = await _register_and_login(client, "mine_shipper@test.uz", "shipper", "+998902000007")

    # 1 ta active
    load_act = await _create_test_load(client, headers, "Active 1")
    # 1 ta in_progress (ASSIGNED)
    load_prog = await _create_test_load(client, headers, "Progress 1")
    await client.post(f"/api/v1/loads/{load_prog['id']}/dev-status?new_status=ASSIGNED", headers=headers)
    # 1 ta history (CANCELLED)
    load_hist = await _create_test_load(client, headers, "History 1")
    await client.post(f"/api/v1/loads/{load_hist['id']}/cancel", headers=headers)

    # Active segment
    res_act = await client.get("/api/v1/loads/mine?status_group=active", headers=headers)
    assert res_act.status_code == 200
    act_ids = [item["id"] for item in res_act.json()["data"]["items"]]
    assert load_act["id"] in act_ids
    assert load_prog["id"] not in act_ids

    # In_progress segment
    res_prog = await client.get("/api/v1/loads/mine?status_group=in_progress", headers=headers)
    assert res_prog.status_code == 200
    prog_ids = [item["id"] for item in res_prog.json()["data"]["items"]]
    assert load_prog["id"] in prog_ids
    assert load_act["id"] not in prog_ids

    # History segment
    res_hist = await client.get("/api/v1/loads/mine?status_group=history", headers=headers)
    assert res_hist.status_code == 200
    hist_ids = [item["id"] for item in res_hist.json()["data"]["items"]]
    assert load_hist["id"] in hist_ids

    # Sahifalash
    res_page = await client.get("/api/v1/loads/mine?status_group=active&page=1&limit=1", headers=headers)
    assert res_page.status_code == 200
    assert len(res_page.json()["data"]["items"]) <= 1

# 8. Egalik va rol himoyasi (403)
@pytest.mark.asyncio
async def test_ownership_and_role_guards(client: AsyncClient):
    headers1 = await _register_and_login(client, "owner_shipper1@test.uz", "shipper", "+998902000008")
    headers2 = await _register_and_login(client, "other_shipper2@test.uz", "shipper", "+998902000009")
    driver_headers = await _register_and_login(client, "hacker_driver@test.uz", "driver", "+998902000010")

    load = await _create_test_load(client, headers1, "Maxfiy Yuk")
    load_id = load["id"]
    updated_at = load["updatedAt"]

    # Boshqa shipper murojaat qilsa -> 403
    assert (await client.get(f"/api/v1/loads/{load_id}", headers=headers2)).status_code == 403
    assert (await client.patch(f"/api/v1/loads/{load_id}", json={"updatedAt": updated_at, "cargoName": "Hacked"}, headers=headers2)).status_code == 403
    assert (await client.post(f"/api/v1/loads/{load_id}/cancel", headers=headers2)).status_code == 403
    assert (await client.post(f"/api/v1/loads/{load_id}/duplicate", headers=headers2)).status_code == 403
    assert (await client.get(f"/api/v1/loads/{load_id}/events", headers=headers2)).status_code == 403

    # DRIVER roli shipper endpointlariga kirishga urinsa -> 403
    assert (await client.get(f"/api/v1/loads/{load_id}", headers=driver_headers)).status_code == 403
    assert (await client.post("/api/v1/loads", json={}, headers=driver_headers)).status_code == 403
    assert (await client.get("/api/v1/loads/mine", headers=driver_headers)).status_code == 403

# 9. Dev-status endpointi faqat ENABLE_DEV_ENDPOINTS=true bo'lganda ishlaydi
@pytest.mark.asyncio
async def test_dev_status_endpoint_flag_guard(client: AsyncClient):
    headers = await _register_and_login(client, "dev_flag_shipper@test.uz", "shipper", "+998902000011")
    load = await _create_test_load(client, headers, "Dev Flag Yuk")
    load_id = load["id"]

    # Flag o'chiq bo'lganda 404 qaytarishi kerak
    settings.ENABLE_DEV_ENDPOINTS = False
    res_disabled = await client.post(f"/api/v1/loads/{load_id}/dev-status?new_status=ASSIGNED", headers=headers)
    assert res_disabled.status_code == 404

    # Flag yoqilganda ishlaydi
    settings.ENABLE_DEV_ENDPOINTS = True
    res_enabled = await client.post(f"/api/v1/loads/{load_id}/dev-status?new_status=ASSIGNED", headers=headers)
    assert res_enabled.status_code == 200
    assert res_enabled.json()["data"]["status"] == "ASSIGNED"
