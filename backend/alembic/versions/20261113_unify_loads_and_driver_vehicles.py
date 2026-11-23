"""unify loads and driver vehicles

Revision ID: 20261113_unify_loads_and_driver_vehicles
Revises: 20261113_create_loads_table
Create Date: 2026-11-13 22:25:00.000000

"""
from alembic import op
import sqlalchemy as sa

revision = '20261113_unify_loads_and_driver_vehicles'
down_revision = '20261113_create_loads_table'
branch_labels = None
depends_on = None

def upgrade() -> None:
    # 1. Create driver_vehicles table
    op.create_table(
        'driver_vehicles',
        sa.Column('id', sa.String(length=64), primary_key=True),
        sa.Column('driver_id', sa.String(length=64), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('truck_type', sa.String(length=64), nullable=False),
        sa.Column('capacity_tons', sa.Float(), nullable=False),
        sa.Column('plate_number', sa.String(length=64), nullable=True),
        sa.Column('is_primary', sa.Boolean(), nullable=False, server_default='1'),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )
    op.create_index('ix_driver_vehicles_driver_id', 'driver_vehicles', ['driver_id'])
    op.create_index('ix_driver_vehicles_truck_type', 'driver_vehicles', ['truck_type'])

    # 2. Create driver_preferences table
    op.create_table(
        'driver_preferences',
        sa.Column('id', sa.String(length=64), primary_key=True),
        sa.Column('driver_id', sa.String(length=64), sa.ForeignKey('users.id', ondelete='CASCADE'), unique=True, nullable=False),
        sa.Column('home_region', sa.String(length=128), nullable=False, server_default='Toshkent shahri'),
        sa.Column('preferred_from_regions_json', sa.Text(), nullable=False, server_default='[]'),
        sa.Column('preferred_to_regions_json', sa.Text(), nullable=False, server_default='[]'),
        sa.Column('min_price_uzs', sa.Float(), nullable=True),
        sa.Column('current_lat', sa.Float(), nullable=True),
        sa.Column('current_lng', sa.Float(), nullable=True),
        sa.Column('location_updated_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )
    op.create_index('ix_driver_preferences_driver_id', 'driver_preferences', ['driver_id'])

    # 3. Enhance loads table with full lifecycle fields
    with op.batch_alter_table('loads', schema=None) as batch_op:
        batch_op.add_column(sa.Column('tracking_code', sa.String(length=64), nullable=True))
        batch_op.add_column(sa.Column('carrier_id', sa.String(length=64), nullable=True))
        batch_op.add_column(sa.Column('driver_id', sa.String(length=64), nullable=True))
        batch_op.add_column(sa.Column('driver_name', sa.String(length=255), nullable=True))
        batch_op.add_column(sa.Column('driver_phone', sa.String(length=64), nullable=True))
        batch_op.add_column(sa.Column('vehicle_plate', sa.String(length=64), nullable=True))
        batch_op.add_column(sa.Column('is_escrow_funded', sa.Boolean(), nullable=False, server_default='0'))
        batch_op.add_column(sa.Column('commission_amount', sa.Float(), nullable=False, server_default='0.0'))
        batch_op.add_column(sa.Column('carrier_payout', sa.Float(), nullable=False, server_default='0.0'))
        batch_op.add_column(sa.Column('eta', sa.String(length=128), nullable=True, server_default='In Calculation'))
        batch_op.add_column(sa.Column('pod_signature_url', sa.String(length=512), nullable=True))
        batch_op.create_foreign_key('fk_loads_carrier_id', 'users', ['carrier_id'], ['id'])
        batch_op.create_foreign_key('fk_loads_driver_id', 'users', ['driver_id'], ['id'])
        batch_op.create_index('ix_loads_tracking_code', ['tracking_code'])
        batch_op.create_index('ix_loads_carrier_id', ['carrier_id'])

    # 4. Add load_id to relation tables (keeping shipment_id for backward compatibility)
    with op.batch_alter_table('bids', schema=None) as batch_op:
        batch_op.add_column(sa.Column('load_id', sa.String(length=64), nullable=True))
        batch_op.create_foreign_key('fk_bids_load_id', 'loads', ['load_id'], ['id'], ondelete='CASCADE')
        batch_op.create_index('ix_bids_load_id', ['load_id'])

    with op.batch_alter_table('escrow_locks', schema=None) as batch_op:
        batch_op.add_column(sa.Column('load_id', sa.String(length=64), nullable=True))
        batch_op.create_foreign_key('fk_escrow_locks_load_id', 'loads', ['load_id'], ['id'], ondelete='CASCADE')
        batch_op.create_index('ix_escrow_locks_load_id', ['load_id'])

    with op.batch_alter_table('tracking_data', schema=None) as batch_op:
        batch_op.add_column(sa.Column('load_id', sa.String(length=64), nullable=True))
        batch_op.create_foreign_key('fk_tracking_data_load_id', 'loads', ['load_id'], ['id'], ondelete='CASCADE')
        batch_op.create_index('ix_tracking_data_load_id', ['load_id'])

    with op.batch_alter_table('chat_channels', schema=None) as batch_op:
        batch_op.add_column(sa.Column('load_id', sa.String(length=64), nullable=True))
        batch_op.create_foreign_key('fk_chat_channels_load_id', 'loads', ['load_id'], ['id'], ondelete='CASCADE')
        batch_op.create_index('ix_chat_channels_load_id', ['load_id'])

    with op.batch_alter_table('call_sessions', schema=None) as batch_op:
        batch_op.add_column(sa.Column('load_id', sa.String(length=64), nullable=True))
        batch_op.create_foreign_key('fk_call_sessions_load_id', 'loads', ['load_id'], ['id'], ondelete='CASCADE')
        batch_op.create_index('ix_call_sessions_load_id', ['load_id'])

    with op.batch_alter_table('disputes', schema=None) as batch_op:
        batch_op.add_column(sa.Column('load_id', sa.String(length=64), nullable=True))
        batch_op.create_foreign_key('fk_disputes_load_id', 'loads', ['load_id'], ['id'], ondelete='CASCADE')
        batch_op.create_index('ix_disputes_load_id', ['load_id'])

def downgrade() -> None:
    with op.batch_alter_table('disputes', schema=None) as batch_op:
        batch_op.drop_constraint('fk_disputes_load_id', type_='foreignkey')
        batch_op.drop_index('ix_disputes_load_id')
        batch_op.drop_column('load_id')
    with op.batch_alter_table('call_sessions', schema=None) as batch_op:
        batch_op.drop_constraint('fk_call_sessions_load_id', type_='foreignkey')
        batch_op.drop_index('ix_call_sessions_load_id')
        batch_op.drop_column('load_id')
    with op.batch_alter_table('chat_channels', schema=None) as batch_op:
        batch_op.drop_constraint('fk_chat_channels_load_id', type_='foreignkey')
        batch_op.drop_index('ix_chat_channels_load_id')
        batch_op.drop_column('load_id')
    with op.batch_alter_table('tracking_data', schema=None) as batch_op:
        batch_op.drop_constraint('fk_tracking_data_load_id', type_='foreignkey')
        batch_op.drop_index('ix_tracking_data_load_id')
        batch_op.drop_column('load_id')
    with op.batch_alter_table('escrow_locks', schema=None) as batch_op:
        batch_op.drop_constraint('fk_escrow_locks_load_id', type_='foreignkey')
        batch_op.drop_index('ix_escrow_locks_load_id')
        batch_op.drop_column('load_id')
    with op.batch_alter_table('bids', schema=None) as batch_op:
        batch_op.drop_constraint('fk_bids_load_id', type_='foreignkey')
        batch_op.drop_index('ix_bids_load_id')
        batch_op.drop_column('load_id')
    with op.batch_alter_table('loads', schema=None) as batch_op:
        batch_op.drop_constraint('fk_loads_driver_id', type_='foreignkey')
        batch_op.drop_constraint('fk_loads_carrier_id', type_='foreignkey')
        batch_op.drop_index('ix_loads_carrier_id')
        batch_op.drop_index('ix_loads_tracking_code')
        batch_op.drop_column('pod_signature_url')
        batch_op.drop_column('eta')
        batch_op.drop_column('carrier_payout')
        batch_op.drop_column('commission_amount')
        batch_op.drop_column('is_escrow_funded')
        batch_op.drop_column('vehicle_plate')
        batch_op.drop_column('driver_phone')
        batch_op.drop_column('driver_name')
        batch_op.drop_column('driver_id')
        batch_op.drop_column('carrier_id')
        batch_op.drop_column('tracking_code')
    op.drop_table('driver_preferences')
    op.drop_table('driver_vehicles')
