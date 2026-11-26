import pytest
from datetime import datetime, timezone, timedelta
from sqlalchemy import text, select
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.user import User, generate_uuid
from app.models.shipment import Shipment
from app.models.bid import Bid
from app.models.escrow import EscrowLock
from app.models.tracking import TrackingData
from app.models.load import Load
from app.models.load_event import LoadEvent
from app.core.enums import UserRole, LoadStatus

@pytest.mark.asyncio
async def test_shipments_to_loads_data_migration(db_session: AsyncSession):
    # 1. Create a shipper user and a carrier user
    shipper = User(
        id=generate_uuid(),
        phone="+998901230001",
        email="mig_shipper@test.uz",
        password_hash="hashed_pw",
        full_name="Migration Shipper",
        role=UserRole.SHIPPER.value,
        is_active=True,
    )
    carrier = User(
        id=generate_uuid(),
        phone="+998901230002",
        email="mig_carrier@test.uz",
        password_hash="hashed_pw",
        full_name="Migration Carrier",
        role=UserRole.DRIVER.value,
        is_active=True,
    )
    db_session.add_all([shipper, carrier])
    await db_session.flush()

    # 2. Insert two legacy shipments (one CREATED, one CARRIER_ASSIGNED)
    shp1_id = generate_uuid()
    shp1 = Shipment(
        id=shp1_id,
        tracking_code="TRK-MIG-001",
        shipper_id=shipper.id,
        shipper_name="Migration Shipper",
        status=LoadStatus.CREATED.value,
        origin_city="Toshkent",
        origin_address="Chilonzor 5",
        origin_latitude=41.2995,
        origin_longitude=69.2401,
        origin_scheduled_time=datetime.now(timezone.utc) + timedelta(days=2),
        dest_city="Buxoro",
        dest_address="Markaz 1",
        dest_latitude=39.7747,
        dest_longitude=64.4286,
        dest_scheduled_time=datetime.now(timezone.utc) + timedelta(days=3),
        cargo_title="To'qimachilik mahsulotlari",
        cargo_type="kiyim_tekstil",
        weight_tons=12.5,
        volume_m3=35.0,
        price=5500000.0,
        commission_amount=0.0,
        carrier_payout=5500000.0,
        is_escrow_funded=False,
        distance_km=560.0,
    )

    shp2_id = generate_uuid()
    shp2 = Shipment(
        id=shp2_id,
        tracking_code="TRK-MIG-002",
        shipper_id=shipper.id,
        shipper_name="Migration Shipper",
        carrier_id=carrier.id,
        carrier_name="Migration Carrier",
        status=LoadStatus.CARRIER_ASSIGNED.value,
        origin_city="Samarqand",
        origin_address="Registon 2",
        origin_latitude=39.6542,
        origin_longitude=66.9597,
        origin_scheduled_time=datetime.now(timezone.utc) + timedelta(days=1),
        dest_city="Navoiy",
        dest_address="Zarafshon 10",
        dest_latitude=40.0844,
        dest_longitude=65.3792,
        dest_scheduled_time=datetime.now(timezone.utc) + timedelta(days=2),
        cargo_title="Metall buyumlar",
        cargo_type="qurilish_materiallari",
        weight_tons=18.0,
        volume_m3=40.0,
        price=4000000.0,
        commission_amount=50000.0,
        carrier_payout=3950000.0,
        is_escrow_funded=True,
        distance_km=180.0,
    )

    db_session.add_all([shp1, shp2])
    await db_session.flush()

    # 3. Add legacy Bid, EscrowLock, and TrackingData without load_id
    bid1 = Bid(
        id=generate_uuid(),
        shipment_id=shp1_id,
        load_id=None,
        carrier_id=carrier.id,
        carrier_name="Migration Carrier",
        proposed_price=5300000.0,
        status="PENDING",
    )
    escrow2 = EscrowLock(
        id=generate_uuid(),
        shipment_id=shp2_id,
        load_id=None,
        shipper_id=shipper.id,
        carrier_id=carrier.id,
        locked_amount=4000000.0,
        commission_amount=50000.0,
        status="HELD",
    )
    tracking2 = TrackingData(
        id=generate_uuid(),
        shipment_id=shp2_id,
        load_id=None,
        current_latitude=39.8000,
        current_longitude=66.0000,
    )

    db_session.add_all([bid1, escrow2, tracking2])
    await db_session.commit()

    # 4. Execute the migration logic on db_session
    status_map = {
        'CREATED': 'ACTIVE',
        'PENDING_BID': 'ACTIVE',
        'CARRIER_ASSIGNED': 'ASSIGNED',
        'ESCROW_FUNDED': 'ASSIGNED',
        'AT_PICKUP': 'IN_TRANSIT',
        'IN_TRANSIT': 'IN_TRANSIT',
        'CUSTOMS_INSPECTION': 'IN_TRANSIT',
        'BORDER_CROSSING': 'IN_TRANSIT',
        'ARRIVED_DESTINATION': 'IN_TRANSIT',
        'POD_SUBMITTED': 'IN_TRANSIT',
        'DELIVERED': 'DELIVERED',
        'COMPLETED_PAYOUT_RELEASED': 'DELIVERED',
        'CANCELLED': 'CANCELLED',
    }

    # Fetch shipments not yet in loads
    result = await db_session.execute(
        text("SELECT * FROM shipments WHERE id NOT IN (SELECT id FROM loads)")
    )
    shipments_to_migrate = result.mappings().all()
    assert len(shipments_to_migrate) == 2

    for s in shipments_to_migrate:
        target_status = status_map.get(s["status"], "ACTIVE")
        await db_session.execute(
            text("""
                INSERT INTO loads (
                    id, shipper_id, status, cargo_name, cargo_type, weight_tons, volume_m3,
                    truck_type, from_lat, from_lng, from_address, from_region, from_city,
                    to_lat, to_lng, to_address, to_region, to_city, distance_km, pickup_date,
                    price_uzs, price_negotiable, description, photos_json, tracking_code,
                    carrier_id, driver_id, driver_name, driver_phone, vehicle_plate,
                    is_escrow_funded, commission_amount, carrier_payout, eta,
                    pod_signature_url, created_at, updated_at
                ) VALUES (
                    :id, :shipper_id, :status, :cargo_name, :cargo_type, :weight_tons, :volume_m3,
                    :truck_type, :from_lat, :from_lng, :from_address, :from_region, :from_city,
                    :to_lat, :to_lng, :to_address, :to_region, :to_city, :distance_km, :pickup_date,
                    :price_uzs, :price_negotiable, :description, :photos_json, :tracking_code,
                    :carrier_id, :driver_id, :driver_name, :driver_phone, :vehicle_plate,
                    :is_escrow_funded, :commission_amount, :carrier_payout, :eta,
                    :pod_signature_url, :created_at, :updated_at
                )
            """),
            {
                'id': s["id"],
                'shipper_id': s["shipper_id"],
                'status': target_status,
                'cargo_name': s["cargo_title"],
                'cargo_type': s["cargo_type"] or 'boshqa',
                'weight_tons': s["weight_tons"],
                'volume_m3': s["volume_m3"],
                'truck_type': 'TENT',
                'from_lat': s["origin_latitude"],
                'from_lng': s["origin_longitude"],
                'from_address': s["origin_address"],
                'from_region': s["origin_city"],
                'from_city': s["origin_city"],
                'to_lat': s["dest_latitude"],
                'to_lng': s["dest_longitude"],
                'to_address': s["dest_address"],
                'to_region': s["dest_city"],
                'to_city': s["dest_city"],
                'distance_km': s["distance_km"],
                'pickup_date': s["origin_scheduled_time"],
                'price_uzs': s["price"],
                'price_negotiable': False,
                'description': None,
                'photos_json': s["cargo_photos_json"] or '[]',
                'tracking_code': s["tracking_code"],
                'carrier_id': s["carrier_id"],
                'driver_id': s["driver_id"],
                'driver_name': s["driver_name"],
                'driver_phone': s["driver_phone"],
                'vehicle_plate': s["vehicle_plate"],
                'is_escrow_funded': s["is_escrow_funded"],
                'commission_amount': s["commission_amount"],
                'carrier_payout': s["carrier_payout"],
                'eta': s["eta"],
                'pod_signature_url': s["pod_signature_url"],
                'created_at': s["created_at"],
                'updated_at': s["updated_at"],
            }
        )
        await db_session.execute(
            text("""
                INSERT INTO load_events (id, load_id, event_type, actor_id, payload_json, created_at)
                VALUES (:id, :load_id, 'CREATED', :actor_id, :payload_json, :created_at)
            """),
            {
                'id': generate_uuid(),
                'load_id': s["id"],
                'actor_id': s["shipper_id"],
                'payload_json': '{"migrated": true}',
                'created_at': s["created_at"],
            }
        )

    # Backfill load_id
    await db_session.execute(text("UPDATE bids SET load_id = shipment_id WHERE load_id IS NULL AND shipment_id IS NOT NULL"))
    await db_session.execute(text("UPDATE escrow_locks SET load_id = shipment_id WHERE load_id IS NULL AND shipment_id IS NOT NULL"))
    await db_session.execute(text("UPDATE tracking_data SET load_id = shipment_id WHERE load_id IS NULL AND shipment_id IS NOT NULL"))
    await db_session.commit()

    # 5. Verify Loads table populated without data loss
    load1_q = await db_session.execute(select(Load).where(Load.id == shp1_id))
    migrated_load1 = load1_q.scalar_one_or_none()
    assert migrated_load1 is not None
    assert migrated_load1.cargo_name == "To'qimachilik mahsulotlari"
    assert migrated_load1.status == "ACTIVE"
    assert migrated_load1.price_uzs == 5500000.0

    load2_q = await db_session.execute(select(Load).where(Load.id == shp2_id))
    migrated_load2 = load2_q.scalar_one_or_none()
    assert migrated_load2 is not None
    assert migrated_load2.cargo_name == "Metall buyumlar"
    assert migrated_load2.status == "ASSIGNED"
    assert migrated_load2.is_escrow_funded is True

    # 6. Verify relations now have load_id populated
    bid_q = await db_session.execute(select(Bid).where(Bid.id == bid1.id))
    updated_bid = bid_q.scalar_one()
    assert updated_bid.load_id == shp1_id

    escrow_q = await db_session.execute(select(EscrowLock).where(EscrowLock.id == escrow2.id))
    updated_escrow = escrow_q.scalar_one()
    assert updated_escrow.load_id == shp2_id

    tracking_q = await db_session.execute(select(TrackingData).where(TrackingData.id == tracking2.id))
    updated_tracking = tracking_q.scalar_one()
    assert updated_tracking.load_id == shp2_id

    # 7. Verify load_events exists
    events_q = await db_session.execute(select(LoadEvent).where(LoadEvent.load_id == shp1_id))
    events = events_q.scalars().all()
    assert len(events) == 1
    assert events[0].event_type == "CREATED"
