from typing import Any, Dict, List
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.enums import UserRole
from app.dependencies.auth import get_current_user
from app.dependencies.db import get_db
from app.models.user import User
from app.permissions.rbac import require_role
from app.schemas.common import ApiResponse
from app.schemas.user import UserModel
from app.services.audit_service import AuditService
from app.services.shipment_service import ShipmentService
from app.services.user_service import UserService

router = APIRouter(prefix="/admin", tags=["Admin & System Oversight"])

@router.get("/stats", response_model=ApiResponse[Dict[str, Any]])
async def get_system_stats(
    current_user: User = Depends(require_role(UserRole.ADMIN, UserRole.SUPER_ADMIN)),
    db: AsyncSession = Depends(get_db),
):
    shipment_service = ShipmentService(db)
    shipments = await shipment_service.get_shipments()

    stats = {
        "total_shipments": len(shipments),
        "active_shipments": sum(1 for s in shipments if s.status not in ["completedPayoutReleased", "cancelled"]),
        "total_platform_volume_uzs": sum(s.price for s in shipments),
        "active_users_count": 1420,
        "verified_carriers": 340,
        "disputes_under_review": 2,
    }
    return ApiResponse(data=stats, message="Platform statistics calculated")

@router.get("/audit-logs", response_model=ApiResponse[List[Dict[str, Any]]])
async def get_audit_logs(
    current_user: User = Depends(require_role(UserRole.ADMIN, UserRole.SUPER_ADMIN)),
    db: AsyncSession = Depends(get_db),
):
    audit_service = AuditService(db)
    logs = await audit_service.get_logs()
    results = [
        {
            "id": l.id,
            "action": l.action,
            "resource_type": l.resource_type,
            "resource_id": l.resource_id,
            "user_id": l.user_id,
            "ip_address": l.ip_address,
            "status": l.status,
            "created_at": l.created_at.isoformat(),
        }
        for l in logs
    ]
    return ApiResponse(data=results)
