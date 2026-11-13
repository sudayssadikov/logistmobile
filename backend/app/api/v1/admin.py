from typing import Any, Dict, List, Optional
from fastapi import APIRouter, Depends, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.config.settings import settings
from app.core.enums import UserRole
from app.core.exceptions import EscrowLedgerError, NotFoundError
from app.dependencies.auth import get_current_user
from app.dependencies.db import get_db
from app.models.document import Document
from app.models.shipment import Shipment
from app.models.user import User
from app.models.wallet import EscrowLock, LedgerTransaction, Wallet
from app.permissions.rbac import require_role
from app.schemas.common import ApiResponse
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

    # Get Platform Revenue Wallet
    stmt = select(Wallet).where(Wallet.user_id == "USR-PLATFORM-REVENUE")
    res = await db.execute(stmt)
    platform_wallet = res.scalars().first()
    platform_revenue_balance = platform_wallet.available_balance if platform_wallet else 0.0
    total_commission_collected = platform_wallet.total_lifetime_earnings if platform_wallet else 0.0

    # Users counts
    users_stmt = select(User)
    users_res = await db.execute(users_stmt)
    all_users = users_res.scalars().all()
    shippers_count = sum(1 for u in all_users if u.role == "shipper")
    carriers_count = sum(1 for u in all_users if u.role == "carrier")
    drivers_count = sum(1 for u in all_users if u.role == "driver")

    # Escrow totals
    escrow_stmt = select(EscrowLock).where(EscrowLock.status == "locked")
    escrow_res = await db.execute(escrow_stmt)
    active_locks = escrow_res.scalars().all()
    total_escrow_held = sum(lock.amount for lock in active_locks)

    # Active and completed deliveries
    active_loads = sum(1 for s in shipments if s.status not in ["completedPayoutReleased", "cancelled", "draft"])
    completed_deliveries = sum(1 for s in shipments if s.status == "completedPayoutReleased")

    stats = {
        # Fields for Flutter AdminKpiModel
        "totalGmv": sum(s.price for s in shipments),
        "totalRevenueCommission": total_commission_collected,
        "activeLoadsInTransit": active_loads,
        "pendingBidsCount": 0,
        "completedDeliveriesCount": completed_deliveries,
        "totalShippersCount": shippers_count,
        "totalCarriersCount": carriers_count,
        "activeDriversOnDuty": drivers_count,
        "totalEscrowHeld": total_escrow_held,
        "totalPayoutsReleased": sum(s.carrier_payout for s in shipments if s.status == "completedPayoutReleased"),
        "systemUptimePercent": 99.99,
        "openDisputesCount": 0,
        "pendingKycCount": 0,
        # Legacy/UI fields
        "total_shipments": len(shipments),
        "active_shipments": active_loads,
        "total_platform_volume_uzs": sum(s.price for s in shipments),
        "platform_revenue_balance_uzs": platform_revenue_balance,
        "total_commission_collected_uzs": total_commission_collected,
        "commission_tiers": {
            "tier_1": {"limit_uzs": settings.COMMISSION_TIER_1_LIMIT, "fee_uzs": settings.COMMISSION_TIER_1_FEE},
            "tier_2": {"limit_uzs": settings.COMMISSION_TIER_2_LIMIT, "fee_uzs": settings.COMMISSION_TIER_2_FEE},
            "tier_3": {"limit_uzs": "> 5 000 000 UZS", "fee_uzs": settings.COMMISSION_TIER_3_FEE},
        },
        "active_users_count": len(all_users),
        "verified_carriers": carriers_count,
        "disputes_under_review": 0,
    }
    return ApiResponse(data=stats, message="Platform revenue & commission statistics retrieved")

@router.get("/users", response_model=ApiResponse[List[Dict[str, Any]]])
async def get_admin_users(
    search: Optional[str] = Query(None),
    role: Optional[str] = Query(None),
    current_user: User = Depends(require_role(UserRole.ADMIN, UserRole.SUPER_ADMIN)),
    db: AsyncSession = Depends(get_db),
):
    stmt = select(User)
    res = await db.execute(stmt)
    users = res.scalars().all()

    results = []
    for u in users:
        if role and u.role != role:
            continue
        if search:
            q = search.lower()
            if q not in u.full_name.lower() and q not in u.phone and q not in (u.email or "").lower():
                continue

        # Get wallet balance for user
        w_stmt = select(Wallet).where(Wallet.user_id == u.id)
        w_res = await db.execute(w_stmt)
        w = w_res.scalars().first()
        bal = w.available_balance if w else 0.0

        results.append({
            "id": u.id,
            "fullName": u.full_name,
            "emailOrPhone": u.phone or u.email,
            "role": u.role,
            "companyName": u.company_name,
            "isVerified": u.is_verified,
            "isSuspended": not u.is_active,
            "rating": u.rating or 5.0,
            "completedTrips": u.completed_trips or 0,
            "walletBalance": bal,
            "registeredAt": u.created_at.isoformat() if u.created_at else "",
            "lastActiveDevice": "Android / Web Terminal",
        })
    return ApiResponse(data=results)

@router.patch("/users/{user_id}/status", response_model=ApiResponse[bool])
async def toggle_user_status(
    user_id: str,
    req: Dict[str, Any],
    current_user: User = Depends(require_role(UserRole.ADMIN, UserRole.SUPER_ADMIN)),
    db: AsyncSession = Depends(get_db),
):
    stmt = select(User).where(User.id == user_id)
    res = await db.execute(stmt)
    target_user = res.scalars().first()
    if not target_user:
        raise NotFoundError("Foydalanuvchi topilmadi.")

    is_suspended = req.get("is_suspended", req.get("isSuspended", False))
    target_user.is_active = not is_suspended
    await db.flush()

    audit = AuditService(db)
    await audit.log(
        action="USER_SUSPEND" if is_suspended else "USER_UNSUSPEND",
        resource_type="USER",
        resource_id=user_id,
        user_id=current_user.id,
        status="SUCCESS",
        metadata={"reason": req.get("reason", "")},
    )
    return ApiResponse(data=True, message=f"Foydalanuvchi holati yangilandi: faol={target_user.is_active}")

@router.get("/verifications", response_model=ApiResponse[List[Dict[str, Any]]])
async def get_pending_verifications(
    status: Optional[str] = Query(None),
    current_user: User = Depends(require_role(UserRole.ADMIN, UserRole.SUPER_ADMIN)),
    db: AsyncSession = Depends(get_db),
):
    stmt = select(Document)
    res = await db.execute(stmt)
    docs = res.scalars().all()

    results = []
    for d in docs:
        if status and d.verification_status != status:
            continue
        u_stmt = select(User).where(User.id == d.user_id)
        u_res = await db.execute(u_stmt)
        u = u_res.scalars().first()

        results.append({
            "id": d.id,
            "userId": d.user_id,
            "userFullName": u.full_name if u else "Noma'lum",
            "userRoleKey": d.user_role or "carrier",
            "companyName": u.company_name if u else "",
            "docType": d.doc_type or "companyRegistration",
            "documentNumber": d.doc_number or "",
            "documentFileUrl": d.file_url or "",
            "status": d.verification_status,
            "submittedAt": d.created_at.isoformat() if d.created_at else "",
            "rejectionReason": d.rejection_reason,
        })
    return ApiResponse(data=results)

@router.patch("/verifications/{doc_id}", response_model=ApiResponse[bool])
async def moderate_verification(
    doc_id: str,
    req: Dict[str, Any],
    current_user: User = Depends(require_role(UserRole.ADMIN, UserRole.SUPER_ADMIN)),
    db: AsyncSession = Depends(get_db),
):
    stmt = select(Document).where(Document.id == doc_id)
    res = await db.execute(stmt)
    doc = res.scalars().first()
    if not doc:
        raise NotFoundError("Hujjat topilmadi.")

    new_status = req.get("status", "approved")
    doc.verification_status = new_status
    if "reason" in req:
        doc.rejection_reason = req["reason"]
    await db.flush()
    return ApiResponse(data=True, message=f"Hujjat holati: {new_status}")

@router.get("/escrow-ledger", response_model=ApiResponse[List[Dict[str, Any]]])
async def get_escrow_ledger(
    current_user: User = Depends(require_role(UserRole.ADMIN, UserRole.SUPER_ADMIN)),
    db: AsyncSession = Depends(get_db),
):
    stmt = select(EscrowLock)
    res = await db.execute(stmt)
    locks = res.scalars().all()

    results = []
    for l in locks:
        s_stmt = select(Shipment).where(Shipment.id == l.shipment_id)
        s_res = await db.execute(s_stmt)
        s = s_res.scalars().first()

        results.append({
            "id": l.id,
            "shipmentId": l.shipment_id,
            "trackingCode": s.tracking_code if s else "LF-UZ-000",
            "shipperName": s.shipper_name if s else "Yuk egasi",
            "carrierName": s.carrier_name or "Tashuvchi",
            "amount": l.amount,
            "platformFee": l.commission_amount or 0.0,
            "status": "HOLD" if l.status == "locked" else ("RELEASED" if l.status == "released" else "REFUNDED"),
            "fundedAt": l.created_at.isoformat() if l.created_at else "",
            "releasedAt": l.released_at.isoformat() if l.released_at else None,
            "isFlaggedSuspicious": False,
        })
    return ApiResponse(data=results)

@router.post("/escrow-ledger/{lock_id}/intervene", response_model=ApiResponse[bool])
async def execute_escrow_intervention(
    lock_id: str,
    req: Dict[str, Any],
    current_user: User = Depends(require_role(UserRole.ADMIN, UserRole.SUPER_ADMIN)),
    db: AsyncSession = Depends(get_db),
):
    stmt = select(EscrowLock).where(EscrowLock.id == lock_id)
    res = await db.execute(stmt)
    lock = res.scalars().first()
    if not lock:
        raise NotFoundError("Eskrou qulfi topilmadi.")

    action = req.get("action", "freezeHold")
    if action == "freezeHold":
        lock.status = "frozen"
    elif action == "forceRelease":
        from app.services.escrow_service import EscrowService
        service = EscrowService(db)
        await service.release_escrow(lock.shipment_id, current_user.id)
    elif action == "refundShipper":
        from app.services.escrow_service import EscrowService
        service = EscrowService(db)
        await service.refund_escrow(lock.shipment_id, current_user.id)

    await db.flush()
    return ApiResponse(data=True, message=f"Eskrou interventsiyasi bajarildi: {action}")

@router.post("/platform-revenue/withdraw", response_model=ApiResponse[Dict[str, Any]])
async def withdraw_platform_revenue(
    amount: float,
    destination_card_or_account: str,
    notes: str = "Platform revenue dividend withdrawal",
    current_user: User = Depends(require_role(UserRole.ADMIN, UserRole.SUPER_ADMIN)),
    db: AsyncSession = Depends(get_db),
):
    stmt = select(Wallet).where(Wallet.user_id == "USR-PLATFORM-REVENUE").with_for_update()
    res = await db.execute(stmt)
    platform_wallet = res.scalars().first()
    if not platform_wallet or platform_wallet.available_balance < amount:
        available = platform_wallet.available_balance if platform_wallet else 0.0
        raise EscrowLedgerError(f"Mablag' yetarli emas: Mavjud {available} UZS, so'ralgan {amount} UZS.")

    platform_wallet.available_balance -= amount

    txn = LedgerTransaction(
        wallet_id=platform_wallet.id,
        type="payout",
        title=f"Platform Revenue Withdrawal to {destination_card_or_account}",
        amount=amount,
        metadata_json=f'{{"destination": "{destination_card_or_account}", "notes": "{notes}", "admin": "{current_user.id}"}}',
    )
    db.add(txn)
    await db.flush()

    return ApiResponse(
        data={
            "withdrawn_amount": amount,
            "remaining_balance": platform_wallet.available_balance,
            "destination": destination_card_or_account,
        },
        message="Mablag' platforma hisobidan muvaffaqiyatli yechildi",
    )

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
