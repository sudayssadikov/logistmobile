"""create load events table and backfill

Revision ID: 20261123_create_load_events
Revises: 20261113_unify_loads_and_driver_vehicles
Create Date: 2026-11-23 15:45:00.000000

"""
from alembic import op
import sqlalchemy as sa
import uuid
import json

revision = '20261123_create_load_events'
down_revision = '20261113_unify_loads_and_driver_vehicles'
branch_labels = None
depends_on = None

def upgrade() -> None:
    # 1. Create load_events table
    op.create_table(
        'load_events',
        sa.Column('id', sa.String(length=64), primary_key=True),
        sa.Column('load_id', sa.String(length=64), sa.ForeignKey('loads.id', ondelete='CASCADE'), nullable=False),
        sa.Column('event_type', sa.String(length=64), nullable=False),
        sa.Column('actor_id', sa.String(length=64), sa.ForeignKey('users.id', ondelete='SET NULL'), nullable=True),
        sa.Column('payload_json', sa.Text(), nullable=False, server_default='{}'),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )
    op.create_index('ix_load_events_load_id', 'load_events', ['load_id'])
    op.create_index('ix_load_events_event_type', 'load_events', ['event_type'])
    op.create_index('ix_load_events_created_at', 'load_events', ['created_at'])

    # 2. Backfill CREATED event for existing loads
    bind = op.get_bind()
    loads_res = bind.execute(sa.text("SELECT id, shipper_id, created_at FROM loads"))
    events_to_insert = []
    for row in loads_res:
        events_to_insert.append({
            "id": str(uuid.uuid4()),
            "load_id": row[0],
            "event_type": "CREATED",
            "actor_id": row[1],
            "payload_json": json.dumps({"note": "Initial creation (backfilled)"}),
            "created_at": row[2],
        })
    if events_to_insert:
        op.bulk_insert(
            sa.table(
                'load_events',
                sa.column('id', sa.String),
                sa.column('load_id', sa.String),
                sa.column('event_type', sa.String),
                sa.column('actor_id', sa.String),
                sa.column('payload_json', sa.Text),
                sa.column('created_at', sa.DateTime),
            ),
            events_to_insert,
        )

def downgrade() -> None:
    op.drop_index('ix_load_events_created_at', table_name='load_events')
    op.drop_index('ix_load_events_event_type', table_name='load_events')
    op.drop_index('ix_load_events_load_id', table_name='load_events')
    op.drop_table('load_events')
