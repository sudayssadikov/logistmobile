"""migrate shipments to loads single source of truth

Revision ID: 20261123_migrate_shipments_to_loads
Revises: 20261123_create_load_events
Create Date: 2026-11-23 17:30:00.000000

"""
from alembic import op
import sqlalchemy as sa
import json
import uuid

revision = '20261123_migrate_shipments_to_loads'
down_revision = '20261123_create_load_events'
branch_labels = None
depends_on = None

STATUS_MAPPING = {
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

def upgrade() -> None:
    conn = op.get_bind()

    # 1. Fetch existing shipments not yet in loads
    inspector = sa.inspect(conn)
    shipment_cols = {c['name'] for c in inspector.get_columns('shipments')}
    comm_expr = "commission_amount" if "commission_amount" in shipment_cols else "0.0 AS commission_amount"
    payout_expr = "carrier_payout" if "carrier_payout" in shipment_cols else "0.0 AS carrier_payout"

    shipments = conn.execute(
        sa.text(f"""
            SELECT id, tracking_code, shipper_id, carrier_id, driver_id, driver_name,
                   driver_phone, vehicle_plate, status, origin_city, origin_address,
                   origin_latitude, origin_longitude, origin_scheduled_time,
                   dest_city, dest_address, dest_latitude, dest_longitude,
                   cargo_title, cargo_type, weight_tons, volume_m3, price,
                   {comm_expr}, {payout_expr}, is_escrow_funded, distance_km,
                   eta, pod_signature_url, cargo_photos_json, created_at, updated_at
            FROM shipments
            WHERE id NOT IN (SELECT id FROM loads)
        """)
    ).fetchall()

    loads_insert = sa.text("""
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
    """)

    event_insert = sa.text("""
        INSERT INTO load_events (id, load_id, event_type, actor_id, payload_json, created_at)
        VALUES (:id, :load_id, 'CREATED', :actor_id, :payload_json, :created_at)
    """)

    for s in shipments:
        target_status = STATUS_MAPPING.get(s.status, 'ACTIVE')
        conn.execute(
            loads_insert,
            {
                'id': s.id,
                'shipper_id': s.shipper_id,
                'status': target_status,
                'cargo_name': s.cargo_title,
                'cargo_type': s.cargo_type or 'boshqa',
                'weight_tons': s.weight_tons,
                'volume_m3': s.volume_m3,
                'truck_type': 'TENT',
                'from_lat': s.origin_latitude,
                'from_lng': s.origin_longitude,
                'from_address': s.origin_address,
                'from_region': s.origin_city,
                'from_city': s.origin_city,
                'to_lat': s.dest_latitude,
                'to_lng': s.dest_longitude,
                'to_address': s.dest_address,
                'to_region': s.dest_city,
                'to_city': s.dest_city,
                'distance_km': s.distance_km,
                'pickup_date': s.origin_scheduled_time,
                'price_uzs': s.price,
                'price_negotiable': False,
                'description': None,
                'photos_json': s.cargo_photos_json or '[]',
                'tracking_code': s.tracking_code,
                'carrier_id': s.carrier_id,
                'driver_id': s.driver_id,
                'driver_name': s.driver_name,
                'driver_phone': s.driver_phone,
                'vehicle_plate': s.vehicle_plate,
                'is_escrow_funded': s.is_escrow_funded,
                'commission_amount': s.commission_amount,
                'carrier_payout': s.carrier_payout,
                'eta': s.eta,
                'pod_signature_url': s.pod_signature_url,
                'created_at': s.created_at,
                'updated_at': s.updated_at,
            }
        )
        conn.execute(
            event_insert,
            {
                'id': str(uuid.uuid4()),
                'load_id': s.id,
                'actor_id': s.shipper_id,
                'payload_json': json.dumps({'note': 'Migrated from legacy shipment', 'legacy_status': s.status}),
                'created_at': s.created_at,
            }
        )

    # 2. Backfill load_id in related tables
    conn.execute(sa.text("UPDATE bids SET load_id = shipment_id WHERE load_id IS NULL AND shipment_id IS NOT NULL"))
    conn.execute(sa.text("UPDATE escrow_locks SET load_id = shipment_id WHERE load_id IS NULL AND shipment_id IS NOT NULL"))
    conn.execute(sa.text("UPDATE tracking_data SET load_id = shipment_id WHERE load_id IS NULL AND shipment_id IS NOT NULL"))
    conn.execute(sa.text("UPDATE chat_channels SET load_id = shipment_id WHERE load_id IS NULL AND shipment_id IS NOT NULL"))
    conn.execute(sa.text("UPDATE call_sessions SET load_id = shipment_id WHERE load_id IS NULL AND shipment_id IS NOT NULL"))
    conn.execute(sa.text("UPDATE disputes SET load_id = shipment_id WHERE load_id IS NULL AND shipment_id IS NOT NULL"))

def downgrade() -> None:
    pass
