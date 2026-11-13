"""Consolidate user roles into SHIPPER and DRIVER

Revision ID: 20261110_role_consolidation
Revises: 
Create Date: 2026-11-10 15:00:00.000000

"""
from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = '20261110_role_consolidation'
down_revision = None
branch_labels = None
depends_on = None

def upgrade() -> None:
    # 1. Update any carrier/dispatcher/company roles to 'shipper'
    op.execute(
        """
        UPDATE users
        SET role = 'shipper'
        WHERE LOWER(role) IN ('carrier', 'dispatcher', 'company_manager', 'company_owner')
        """
    )
    # 2. Standardize driver roles to 'driver'
    op.execute(
        """
        UPDATE users
        SET role = 'driver'
        WHERE LOWER(role) IN ('driver', 'truck_driver')
        """
    )
    # Admin va super_admin rollariga tegmaymiz (backendda tizim boshqaruvi uchun saqlanadi)

def downgrade() -> None:
    pass
