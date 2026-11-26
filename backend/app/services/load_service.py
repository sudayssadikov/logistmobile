import json
import math
from datetime import datetime, timezone, timedelta
from typing import Any, Dict, List, Optional
from sqlalchemy import select, func, desc, or_
from sqlalchemy.ext.asyncio import AsyncSession
from fastapi import HTTPException, status
from app.core.enums import LoadStatus
from app.models.load import Load
from app.models.load_event import LoadEvent
from app.schemas.load import (
    CreateLoadRequest,
    UpdateLoadRequest,
    LoadResponse,
    LoadSummaryResponse,
    PaginatedLoadSummaryResponse,
    LoadEventResponse,
    haversine_distance,
)
from app.services.escrow_service import EscrowService

class LoadService:
    def __init__(self, session: AsyncSession):
        self.session = session

    def _to_response(self, load: Load) -> LoadResponse:
        return LoadResponse(
            id=load.id,
            shipper_id=load.shipper_id,
            status=load.status,
            cargo_name=load.cargo_name,
            cargo_type=load.cargo_type,
            weight_tons=load.weight_tons,
            volume_m3=load.volume_m3,
            truck_type=load.truck_type,
            from_lat=load.from_lat,
            from_lng=load.from_lng,
            from_address=load.from_address,
            from_region=load.from_region,
            from_city=load.from_city,
            to_lat=load.to_lat,
            to_lng=load.to_lng,
            to_address=load.to_address,
            to_region=load.to_region,
            to_city=load.to_city,
            distance_km=load.distance_km,
            pickup_date=load.pickup_date,
            price_uzs=load.price_uzs,
            price_negotiable=load.price_negotiable,
            description=load.description,
            photos=load.photos,
            created_at=load.created_at,
            updated_at=load.updated_at,
        )

    def _to_summary_response(self, load: Load) -> LoadSummaryResponse:
        return LoadSummaryResponse(
            id=load.id,
            cargo_name=load.cargo_name,
            cargo_type=load.cargo_type,
            weight_tons=load.weight_tons,
            truck_type=load.truck_type,
            from_city=load.from_city,
            from_region=load.from_region,
            to_city=load.to_city,
            to_region=load.to_region,
            price_uzs=load.price_uzs,
            price_negotiable=load.price_negotiable,
            status=load.status,
            pickup_date=load.pickup_date,
            created_at=load.created_at,
            updated_at=load.updated_at,
        )

    async def create_load(self, shipper_id: str, req: CreateLoadRequest) -> LoadResponse:
        dist = haversine_distance(req.from_lat, req.from_lng, req.to_lat, req.to_lng)

        load = Load(
            shipper_id=shipper_id,
            status=LoadStatus.ACTIVE.value,
            cargo_name=req.cargo_name,
            cargo_type=req.cargo_type.value,
            weight_tons=req.weight_tons,
            volume_m3=req.volume_m3,
            truck_type=req.truck_type.value,
            from_lat=req.from_lat,
            from_lng=req.from_lng,
            from_address=req.from_address,
            from_region=req.from_region,
            from_city=req.from_city,
            to_lat=req.to_lat,
            to_lng=req.to_lng,
            to_address=req.to_address,
            to_region=req.to_region,
            to_city=req.to_city,
            distance_km=dist,
            pickup_date=req.pickup_date,
            price_uzs=req.price_uzs if not req.price_negotiable else None,
            price_negotiable=req.price_negotiable,
            description=req.description,
            photos_json=json.dumps(req.photos or []),
        )

        self.session.add(load)
        await self.session.flush()

        # Record CREATED event
        event = LoadEvent(
            load_id=load.id,
            event_type="CREATED",
            actor_id=shipper_id,
            payload_json=json.dumps({"action": "load_created", "status": load.status}),
        )
        self.session.add(event)
        await self.session.flush()

        return self._to_response(load)

    async def get_load_by_id(self, load_id: str, current_user_id: str) -> LoadResponse:
        stmt = select(Load).where(Load.id == load_id)
        result = await self.session.execute(stmt)
        load = result.scalar_one_or_none()

        if not load:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Yuk topilmadi.",
            )

        # Faqat yuk egasi (shipper) ko'ra oladi
        if load.shipper_id != current_user_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Bu yuk ma'lumotlarini faqat uning egasi ko'rishi mumkin.",
            )

        return self._to_response(load)

    async def get_my_loads(
        self,
        shipper_id: str,
        status_group: str = "active",
        page: int = 1,
        limit: int = 20,
    ) -> PaginatedLoadSummaryResponse:
        # Status group mapping:
        # active = ACTIVE
        # in_progress = ASSIGNED, IN_TRANSIT
        # history = DELIVERED, CANCELLED
        if status_group == "active":
            statuses = [LoadStatus.ACTIVE.value]
        elif status_group == "in_progress":
            statuses = [LoadStatus.ASSIGNED.value, LoadStatus.IN_TRANSIT.value, "inTransit"]
        elif status_group == "history":
            statuses = [LoadStatus.DELIVERED.value, LoadStatus.CANCELLED.value, "delivered"]
        else:
            statuses = [LoadStatus.ACTIVE.value]

        base_filter = [Load.shipper_id == shipper_id, Load.status.in_(statuses)]

        # Total count
        count_stmt = select(func.count(Load.id)).where(*base_filter)
        total_res = await self.session.execute(count_stmt)
        total = total_res.scalar() or 0

        # Paginated items
        offset = (page - 1) * limit
        query_stmt = (
            select(Load)
            .where(*base_filter)
            .order_by(desc(Load.created_at))
            .offset(offset)
            .limit(limit)
        )
        items_res = await self.session.execute(query_stmt)
        loads = items_res.scalars().all()

        pages = math.ceil(total / limit) if total > 0 else 1
        summary_items = [self._to_summary_response(l) for l in loads]

        return PaginatedLoadSummaryResponse(
            items=summary_items,
            total=total,
            page=page,
            limit=limit,
            pages=pages,
        )

    async def update_load(
        self,
        load_id: str,
        shipper_id: str,
        req: UpdateLoadRequest,
    ) -> LoadResponse:
        stmt = select(Load).where(Load.id == load_id)
        result = await self.session.execute(stmt)
        load = result.scalar_one_or_none()

        if not load:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Yuk topilmadi.",
            )

        if load.shipper_id != shipper_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Bu yukni tahrirlash huquqi faqat uning egasiga tegishli.",
            )

        # 1. Parallel editing check (concurrency protection)
        def _to_utc_ts(dt: Optional[datetime]) -> float:
            if not dt:
                return 0.0
            if dt.tzinfo is None:
                dt = dt.replace(tzinfo=timezone.utc)
            return dt.timestamp()

        req_ts = _to_utc_ts(req.updated_at)
        db_ts = _to_utc_ts(load.updated_at)
        if abs(req_ts - db_ts) > 2.0:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Yuk boshqa joyda o'zgartirilgan, iltimos yangilang.",
            )

        # 2. Status rules check
        # IN_TRANSIT, DELIVERED, CANCELLED cannot be edited
        forbidden_edit_statuses = [
            LoadStatus.IN_TRANSIT.value,
            "inTransit",
            LoadStatus.DELIVERED.value,
            "delivered",
            LoadStatus.CANCELLED.value,
        ]
        if load.status in forbidden_edit_statuses:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"Ushbu holatdagi ({load.status}) yukni tahrirlab bo'lmaydi.",
            )

        changed_fields: List[str] = []

        # ASSIGNED status check: restricted edit only
        if load.status == LoadStatus.ASSIGNED.value:
            # Check restricted fields
            is_restricted_field_attempted = (
                (req.cargo_name is not None and req.cargo_name != load.cargo_name)
                or (req.cargo_type is not None and req.cargo_type.value != load.cargo_type)
                or (req.weight_tons is not None and req.weight_tons != load.weight_tons)
                or (req.truck_type is not None and req.truck_type.value != load.truck_type)
                or (req.from_lat is not None and req.from_lat != load.from_lat)
                or (req.to_lat is not None and req.to_lat != load.to_lat)
                or (req.price_uzs is not None and req.price_uzs != load.price_uzs)
                or (req.price_negotiable is not None and req.price_negotiable != load.price_negotiable)
            )
            if is_restricted_field_attempted:
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail="Haydovchi tayinlangan. Marshrut, og'irlik, mashina turi va narxni o'zgartirib bo'lmaydi.",
                )

            # Check pickup_date: only hour/minute can be changed, not date (day/month/year)
            if req.pickup_date is not None:
                cur_dt = load.pickup_date
                new_dt = req.pickup_date
                if (cur_dt.year, cur_dt.month, cur_dt.day) != (new_dt.year, new_dt.month, new_dt.day):
                    raise HTTPException(
                        status_code=status.HTTP_409_CONFLICT,
                        detail="Haydovchi tayinlangan. Olib ketish sanasini o'zgartirib bo'lmaydi, faqat soatini o'zgartirish mumkin.",
                    )
                load.pickup_date = req.pickup_date
                changed_fields.append("pickup_date")

            if req.description is not None:
                load.description = req.description
                changed_fields.append("description")
            if req.photos is not None:
                load.photos = req.photos
                changed_fields.append("photos")

        else:
            # ACTIVE status: all fields can be edited
            if req.cargo_name is not None:
                load.cargo_name = req.cargo_name
                changed_fields.append("cargo_name")
            if req.cargo_type is not None:
                load.cargo_type = req.cargo_type.value
                changed_fields.append("cargo_type")
            if req.weight_tons is not None:
                load.weight_tons = req.weight_tons
                changed_fields.append("weight_tons")
            if req.volume_m3 is not None:
                load.volume_m3 = req.volume_m3
                changed_fields.append("volume_m3")
            if req.truck_type is not None:
                load.truck_type = req.truck_type.value
                changed_fields.append("truck_type")

            # Route coordinates
            coords_changed = False
            if req.from_lat is not None and req.from_lng is not None:
                load.from_lat = req.from_lat
                load.from_lng = req.from_lng
                coords_changed = True
                changed_fields.append("from_coords")
            if req.from_address is not None:
                load.from_address = req.from_address
            if req.from_region is not None:
                load.from_region = req.from_region
            if req.from_city is not None:
                load.from_city = req.from_city

            if req.to_lat is not None and req.to_lng is not None:
                load.to_lat = req.to_lat
                load.to_lng = req.to_lng
                coords_changed = True
                changed_fields.append("to_coords")
            if req.to_address is not None:
                load.to_address = req.to_address
            if req.to_region is not None:
                load.to_region = req.to_region
            if req.to_city is not None:
                load.to_city = req.to_city

            if coords_changed:
                dist = haversine_distance(load.from_lat, load.from_lng, load.to_lat, load.to_lng)
                if dist < 1.0:
                    raise HTTPException(
                        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                        detail="Yuk ortish va yetkazish joylari orasidagi masofa kamida 1 km bo'lishi kerak.",
                    )
                load.distance_km = dist
                changed_fields.append("distance_km")

            if req.pickup_date is not None:
                now = datetime.now(timezone.utc)
                target = req.pickup_date if req.pickup_date.tzinfo else req.pickup_date.replace(tzinfo=timezone.utc)
                if target < now - timedelta(minutes=15):
                    raise HTTPException(
                        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                        detail="Olib ketish sanasi o'tmishda bo'lishi mumkin emas.",
                    )
                load.pickup_date = req.pickup_date
                changed_fields.append("pickup_date")

            if req.price_negotiable is not None:
                load.price_negotiable = req.price_negotiable
                changed_fields.append("price_negotiable")
            if req.price_uzs is not None:
                load.price_uzs = req.price_uzs
                changed_fields.append("price_uzs")

            if not load.price_negotiable and (load.price_uzs is None or load.price_uzs <= 0):
                raise HTTPException(
                    status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                    detail="Narx kiritilishi yoki 'Narx kelishiladi' belgisi yoqilgan bo'lishi shart.",
                )

            if req.description is not None:
                load.description = req.description
                changed_fields.append("description")
            if req.photos is not None:
                load.photos = req.photos
                changed_fields.append("photos")

        # Record EDITED event
        event = LoadEvent(
            load_id=load.id,
            event_type="EDITED",
            actor_id=shipper_id,
            payload_json=json.dumps({"changed_fields": changed_fields}),
        )
        self.session.add(event)
        await self.session.flush()

        return self._to_response(load)

    async def cancel_load(
        self,
        load_id: str,
        shipper_id: str,
        reason: Optional[str] = None,
    ) -> LoadResponse:
        stmt = select(Load).where(Load.id == load_id)
        result = await self.session.execute(stmt)
        load = result.scalar_one_or_none()

        if not load:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Yuk topilmadi.",
            )

        if load.shipper_id != shipper_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Bu yukni bekor qilish huquqi faqat uning egasiga tegishli.",
            )

        if load.status in [LoadStatus.IN_TRANSIT.value, "inTransit"]:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Yo'ldagi yukni bekor qilish uchun qo'llab-quvvatlashga murojaat qiling.",
            )

        if load.status in [LoadStatus.DELIVERED.value, "delivered", LoadStatus.CANCELLED.value]:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Ushbu yukni bekor qilib bo'lmaydi.",
            )

        # If escrow is funded, trigger refund logic
        if load.is_escrow_funded:
            escrow_service = EscrowService(self.session)
            await escrow_service.refund_escrow(
                shipment_id=load.id,
                user_id=shipper_id,
                reason=reason or "Shipper cancellation",
            )
            load.is_escrow_funded = False

        load.status = LoadStatus.CANCELLED.value

        event = LoadEvent(
            load_id=load.id,
            event_type="CANCELLED",
            actor_id=shipper_id,
            payload_json=json.dumps({"reason": reason or "Yuk beruvchi tomonidan bekor qilindi"}),
        )
        self.session.add(event)
        await self.session.flush()

        return self._to_response(load)

    async def duplicate_load(
        self,
        load_id: str,
        shipper_id: str,
    ) -> LoadResponse:
        stmt = select(Load).where(Load.id == load_id)
        result = await self.session.execute(stmt)
        original = result.scalar_one_or_none()

        if not original:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Nusxa olinadigan yuk topilmadi.",
            )

        if original.shipper_id != shipper_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Faqat o'zingizning yukingizdan nusxa ko'chirishingiz mumkin.",
            )

        # Fresh active pickup date: 2 days in the future
        future_pickup = datetime.now(timezone.utc) + timedelta(days=2)

        duplicate = Load(
            shipper_id=shipper_id,
            status=LoadStatus.ACTIVE.value,
            cargo_name=f"{original.cargo_name} (Nusxa)",
            cargo_type=original.cargo_type,
            weight_tons=original.weight_tons,
            volume_m3=original.volume_m3,
            truck_type=original.truck_type,
            from_lat=original.from_lat,
            from_lng=original.from_lng,
            from_address=original.from_address,
            from_region=original.from_region,
            from_city=original.from_city,
            to_lat=original.to_lat,
            to_lng=original.to_lng,
            to_address=original.to_address,
            to_region=original.to_region,
            to_city=original.to_city,
            distance_km=original.distance_km,
            pickup_date=future_pickup,
            price_uzs=original.price_uzs,
            price_negotiable=original.price_negotiable,
            description=original.description,
            photos_json=original.photos_json,
            # Reset assignments
            carrier_id=None,
            driver_id=None,
            driver_name=None,
            driver_phone=None,
            vehicle_plate=None,
            is_escrow_funded=False,
            commission_amount=0.0,
            carrier_payout=0.0,
        )

        self.session.add(duplicate)
        await self.session.flush()

        event = LoadEvent(
            load_id=duplicate.id,
            event_type="CREATED",
            actor_id=shipper_id,
            payload_json=json.dumps({"action": "duplicated", "original_load_id": original.id}),
        )
        self.session.add(event)
        await self.session.flush()

        return self._to_response(duplicate)

    async def get_load_events(
        self,
        load_id: str,
        shipper_id: str,
    ) -> List[LoadEventResponse]:
        # Ownership check
        stmt = select(Load).where(Load.id == load_id)
        result = await self.session.execute(stmt)
        load = result.scalar_one_or_none()

        if not load:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Yuk topilmadi.",
            )

        if load.shipper_id != shipper_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Hodisalar tarixini faqat yuk egasi ko'rishi mumkin.",
            )

        events_stmt = (
            select(LoadEvent)
            .where(LoadEvent.load_id == load_id)
            .order_by(desc(LoadEvent.created_at))
        )
        events_res = await self.session.execute(events_stmt)
        events = events_res.scalars().all()

        return [
            LoadEventResponse(
                id=e.id,
                load_id=e.load_id,
                event_type=e.event_type,
                actor_id=e.actor_id,
                payload=e.payload,
                created_at=e.created_at,
            )
            for e in events
        ]

    async def dev_set_load_status(
        self,
        load_id: str,
        new_status: str,
    ) -> LoadResponse:
        """Dev-only helper to override load status for testing lifecycle flows."""
        stmt = select(Load).where(Load.id == load_id)
        result = await self.session.execute(stmt)
        load = result.scalar_one_or_none()
        if not load:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Yuk topilmadi.")

        load.status = new_status
        event = LoadEvent(
            load_id=load.id,
            event_type="STATUS_CHANGED",
            payload_json=json.dumps({"action": "dev_status_override", "status": new_status}),
        )
        self.session.add(event)
        await self.session.flush()
        return self._to_response(load)
