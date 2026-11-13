import json
from datetime import datetime, timezone
from typing import Optional
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from fastapi import HTTPException, status
from app.core.enums import LoadStatus
from app.models.load import Load
from app.schemas.load import CreateLoadRequest, LoadResponse, haversine_distance

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

