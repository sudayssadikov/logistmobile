"""create loads table

Revision ID: 20261113_create_loads_table
Revises: 20261110_role_consolidation
Create Date: 2026-11-13 16:38:00.000000

"""
from alembic import op
import sqlalchemy as sa

revision = '20261113_create_loads_table'
down_revision = '20261110_role_consolidation'
branch_labels = None
depends_on = None

def upgrade() -> None:
    op.create_table(
        'loads',
        sa.Column('id', sa.String(length=64), primary_key=True),
        sa.Column('shipper_id', sa.String(length=64), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('status', sa.String(length=32), nullable=False, server_default='ACTIVE'),
        sa.Column('cargo_name', sa.String(length=255), nullable=False),
        sa.Column('cargo_type', sa.String(length=64), nullable=False),
        sa.Column('weight_tons', sa.Float(), nullable=False),
        sa.Column('volume_m3', sa.Float(), nullable=True),
        sa.Column('truck_type', sa.String(length=64), nullable=False),
        sa.Column('from_lat', sa.Float(), nullable=False),
        sa.Column('from_lng', sa.Float(), nullable=False),
        sa.Column('from_address', sa.String(length=512), nullable=False),
        sa.Column('from_region', sa.String(length=128), nullable=False),
        sa.Column('from_city', sa.String(length=128), nullable=False),
        sa.Column('to_lat', sa.Float(), nullable=False),
        sa.Column('to_lng', sa.Float(), nullable=False),
        sa.Column('to_address', sa.String(length=512), nullable=False),
        sa.Column('to_region', sa.String(length=128), nullable=False),
        sa.Column('to_city', sa.String(length=128), nullable=False),
        sa.Column('distance_km', sa.Float(), nullable=False),
        sa.Column('pickup_date', sa.DateTime(timezone=True), nullable=False),
        sa.Column('price_uzs', sa.Float(), nullable=True),
        sa.Column('price_negotiable', sa.Boolean(), nullable=False, server_default='0'),
        sa.Column('description', sa.String(length=500), nullable=True),
        sa.Column('photos_json', sa.Text(), nullable=True, server_default='[]'),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )
    op.create_index('ix_loads_status', 'loads', ['status'])
    op.create_index('ix_loads_shipper_id', 'loads', ['shipper_id'])
    op.create_index('ix_loads_from_region', 'loads', ['from_region'])
    op.create_index('ix_loads_to_region', 'loads', ['to_region'])
    op.create_index('ix_loads_truck_type', 'loads', ['truck_type'])
    op.create_index('ix_loads_pickup_date', 'loads', ['pickup_date'])

def downgrade() -> None:
    op.drop_table('loads')

