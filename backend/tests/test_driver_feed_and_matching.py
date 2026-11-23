import pytest
from httpx import AsyncClient
from datetime import datetime, timezone, timedelta
from app.core.enums import TruckType, CargoType, UserRole
from app.models.load import Load
from app.models.driver_vehicle import DriverVehicle, DriverPreferences
from app.services.matching import RuleBasedScorer, haversine_km

@pytest.mark.asyncio
async def test_scorer_hard_filters_and_components():
    scorer = RuleBasedScorer()
    
    # 1. Capacity Exceeded Check
    heavy_load = Load(
        cargo_name="Heavy Machinery",
        cargo_type=CargoType.TEXNIKA.value,
        weight_tons=25.0,
        truck_type=TruckType.FLATBED.value,
        from_lat=41.2995,
        from_lng=69.2401,
        from_region="Toshkent shahri",
        from_city="Toshkent",
        to_lat=39.6542,
        to_lng=66.9597,
        to_region="Samarqand viloyati",
        to_city="Samarqand",
        distance_km=300.0,
        pickup_date=datetime.now(timezone.utc) + timedelta(days=1),
        price_uzs=5000000.0,
        price_negotiable=False,
    )
    small_vehicle = DriverVehicle(
        driver_id="driver-1",
        truck_type=TruckType.FLATBED.value,
        capacity_tons=10.0, # Less than 25 tons
        is_primary=True,
    )
    prefs = DriverPreferences(
        driver_id="driver-1",
        home_region="Toshkent shahri",
    )
    
    pct, reasons, _ = scorer.calculate_match(heavy_load, small_vehicle, prefs)
    assert pct == 0
    assert "reason_capacity_exceeded" in reasons

    # 2. Truck Type Mismatch Check
    mismatched_vehicle = DriverVehicle(
        driver_id="driver-1",
        truck_type=TruckType.REFRIGERATOR.value, # Not FLATBED
        capacity_tons=30.0,
        is_primary=True,
    )
    pct, reasons, _ = scorer.calculate_match(heavy_load, mismatched_vehicle, prefs)
    assert pct == 0
    assert "reason_truck_type_mismatch" in reasons

    # 3. High Match Scenario
    compatible_vehicle = DriverVehicle(
        driver_id="driver-1",
        truck_type=TruckType.FLATBED.value,
        capacity_tons=28.0,
        is_primary=True,
    )
    pct, reasons, dist = scorer.calculate_match(
        heavy_load,
        compatible_vehicle,
        prefs,
        driver_lat=41.2995,
        driver_lng=69.2401,
    )
    assert pct >= 70
    assert "reason_truck_type_match" in reasons
    assert "reason_pickup_distance_close" in reasons

@pytest.mark.asyncio
async def test_driver_feed_api_flow(client: AsyncClient):
    # 1. Register Shipper and create load
    shipper_res = await client.post(
        "/api/v1/auth/register",
        json={
            "full_name": "Test Shipper Part 4",
            "email": "shipper_part4@test.uz",
            "phone": "+998901239988",
            "password": "Password123!",
            "role": "shipper",
        },
    )
    assert shipper_res.status_code == 201

    shipper_login = await client.post(
        "/api/v1/auth/login",
        json={
            "email_or_phone": "shipper_part4@test.uz",
            "password": "Password123!",
            "role": "shipper",
        },
    )
    assert shipper_login.status_code == 200
    shipper_token = shipper_login.json()["data"]["access_token"]
    shipper_headers = {"Authorization": f"Bearer {shipper_token}"}

    create_load_payload = {
        "cargoName": "Qurilish g'ishti",
        "cargoType": "qurilish_materiallari",
        "weightTons": 18.5,
        "volumeM3": 25.0,
        "truckType": "TENT",
        "fromLat": 41.2995,
        "fromLng": 69.2401,
        "fromAddress": "Chilonzor 9, Toshkent",
        "fromRegion": "Toshkent shahri",
        "fromCity": "Toshkent",
        "toLat": 39.6542,
        "toLng": 66.9597,
        "toAddress": "Registondan 2 km, Samarqand",
        "toRegion": "Samarqand viloyati",
        "toCity": "Samarqand",
        "pickupDate": (datetime.now(timezone.utc) + timedelta(days=2)).isoformat(),
        "priceUzs": 4200000.0,
        "priceNegotiable": False,
        "description": "20 pallet qizil g'isht",
    }
    load_res = await client.post("/api/v1/loads", json=create_load_payload, headers=shipper_headers)
    assert load_res.status_code == 201
    load_id = load_res.json()["data"]["id"]

    # 2. Shipper CANNOT access /api/v1/driver/feed (Forbidden 403)
    forbidden_feed = await client.get("/api/v1/driver/feed", headers=shipper_headers)
    assert forbidden_feed.status_code == 403

    # 3. Register Driver
    driver_res = await client.post(
        "/api/v1/auth/register",
        json={
            "full_name": "Test Driver Part 4",
            "email": "driver_part4@test.uz",
            "phone": "+998909876655",
            "password": "Password123!",
            "role": "driver",
        },
    )
    assert driver_res.status_code == 201

    driver_login = await client.post(
        "/api/v1/auth/login",
        json={
            "email_or_phone": "driver_part4@test.uz",
            "password": "Password123!",
            "role": "driver",
        },
    )
    assert driver_login.status_code == 200
    driver_token = driver_login.json()["data"]["access_token"]
    driver_headers = {"Authorization": f"Bearer {driver_token}"}

    # 4. Feed before adding vehicle (has_vehicle=False)
    feed_res1 = await client.get("/api/v1/driver/feed", headers=driver_headers)
    assert feed_res1.status_code == 200
    feed_data1 = feed_res1.json()["data"]
    assert feed_data1["has_vehicle"] is False
    assert any(item["id"] == load_id for item in feed_data1["items"])
    target_item = next(item for item in feed_data1["items"] if item["id"] == load_id)
    assert target_item["match_percent"] == 0
    # Shipper phone or contact must NOT be leaked
    assert "shipper_phone" not in target_item
    assert "phone" not in target_item

    # 5. Driver adds vehicle
    add_veh_res = await client.post(
        "/api/v1/driver/vehicles",
        json={
            "truck_type": "TENT",
            "capacity_tons": 20.0,
            "plate_number": "01A777AA",
            "is_primary": True,
        },
        headers=driver_headers,
    )
    assert add_veh_res.status_code == 201
    assert add_veh_res.json()["data"]["truck_type"] == "TENT"

    # 6. Driver updates location
    loc_res = await client.put(
        "/api/v1/driver/location",
        json={
            "lat": 41.3111,
            "lng": 69.2797,
        },
        headers=driver_headers,
    )
    assert loc_res.status_code == 200

    # 7. Feed after vehicle + location (has_vehicle=True, match > 0)
    feed_res2 = await client.get("/api/v1/driver/feed?sort=match", headers=driver_headers)
    assert feed_res2.status_code == 200
    feed_data2 = feed_res2.json()["data"]
    assert feed_data2["has_vehicle"] is True
    target_item2 = next(item for item in feed_data2["items"] if item["id"] == load_id)
    assert target_item2["match_percent"] >= 60
    assert len(target_item2["match_reasons"]) > 0
    assert target_item2["pickup_distance_km"] is not None

    # 8. Test Filtering:
    # Filter by different truck type should exclude our TENT load
    feed_filtered = await client.get("/api/v1/driver/feed?truck_types=TANKER", headers=driver_headers)
    assert feed_filtered.status_code == 200
    assert not any(item["id"] == load_id for item in feed_filtered.json()["data"]["items"])

    # Filter by matching truck type should include it
    feed_tent = await client.get("/api/v1/driver/feed?truck_types=TENT", headers=driver_headers)
    assert feed_tent.status_code == 200
    assert any(item["id"] == load_id for item in feed_tent.json()["data"]["items"])
