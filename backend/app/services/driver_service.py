from datetime import datetime, timezone
from typing import List, Optional, Tuple
from sqlalchemy import select, and_, or_, desc, asc
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.driver_vehicle import DriverVehicle, DriverPreferences
from app.models.load import Load
from app.models.bid import Bid
from app.core.enums import LoadStatus
from app.schemas.driver_vehicle import (
    DriverVehicleCreate,
    DriverPreferencesUpdate,
    DriverLocationUpdate,
    DriverFeedItem,
    DriverFeedResponse,
)
from app.services.matching import RuleBasedScorer

class DriverService:
    def __init__(self, db: AsyncSession, scorer: Optional[RuleBasedScorer] = None):
        self.db = db
        self.scorer = scorer or RuleBasedScorer()

    async def get_or_create_preferences(self, driver_id: str) -> DriverPreferences:
        stmt = select(DriverPreferences).where(DriverPreferences.driver_id == driver_id)
        result = await self.db.execute(stmt)
        prefs = result.scalars().first()
        if not prefs:
            prefs = DriverPreferences(
                driver_id=driver_id,
                home_region="Toshkent shahri",
                preferred_from_regions_json="[]",
                preferred_to_regions_json="[]",
            )
            self.db.add(prefs)
            await self.db.commit()
            await self.db.refresh(prefs)
        return prefs

    async def update_preferences(self, driver_id: str, data: DriverPreferencesUpdate) -> DriverPreferences:
        prefs = await self.get_or_create_preferences(driver_id)
        if data.home_region is not None:
            prefs.home_region = data.home_region
        if data.preferred_from_regions is not None:
            prefs.preferred_from_regions = data.preferred_from_regions
        if data.preferred_to_regions is not None:
            prefs.preferred_to_regions = data.preferred_to_regions
        if data.min_price_uzs is not None:
            prefs.min_price_uzs = data.min_price_uzs
        await self.db.commit()
        await self.db.refresh(prefs)
        return prefs

    async def update_location(self, driver_id: str, data: DriverLocationUpdate) -> DriverPreferences:
        prefs = await self.get_or_create_preferences(driver_id)
        prefs.current_lat = data.lat
        prefs.current_lng = data.lng
        prefs.location_updated_at = data.updated_at or datetime.now(timezone.utc)
        await self.db.commit()
        await self.db.refresh(prefs)
        return prefs

    async def get_driver_vehicles(self, driver_id: str) -> List[DriverVehicle]:
        stmt = select(DriverVehicle).where(DriverVehicle.driver_id == driver_id).order_by(desc(DriverVehicle.is_primary), desc(DriverVehicle.created_at))
        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def add_driver_vehicle(self, driver_id: str, data: DriverVehicleCreate) -> DriverVehicle:
        # If this new vehicle is marked primary, unset other primaries
        if data.is_primary:
            existing_stmt = select(DriverVehicle).where(DriverVehicle.driver_id == driver_id)
            existing_result = await self.db.execute(existing_stmt)
            for v in existing_result.scalars().all():
                v.is_primary = False

        vehicle = DriverVehicle(
            driver_id=driver_id,
            truck_type=data.truck_type.value if hasattr(data.truck_type, "value") else str(data.truck_type),
            capacity_tons=data.capacity_tons,
            plate_number=data.plate_number,
            is_primary=data.is_primary,
        )
        self.db.add(vehicle)
        await self.db.commit()
        await self.db.refresh(vehicle)
        return vehicle

    async def get_driver_feed(
        self,
        driver_id: str,
        sort: str = "newest",  # match, newest, price, distance
        min_price: Optional[float] = None,
        max_price: Optional[float] = None,
        include_negotiable: bool = True,
        max_tons: Optional[float] = None,
        truck_types: Optional[List[str]] = None,
        from_region: Optional[str] = None,
        to_region: Optional[str] = None,
        pickup_from: Optional[datetime] = None,
        pickup_to: Optional[datetime] = None,
        limit: int = 50,
        offset: int = 0,
    ) -> DriverFeedResponse:
        # 1. Fetch driver profile data (vehicle & preferences)
        vehicles = await self.get_driver_vehicles(driver_id)
        primary_vehicle = next((v for v in vehicles if v.is_primary), vehicles[0] if vehicles else None)
        prefs = await self.get_or_create_preferences(driver_id)

        # 2. Base query: only ACTIVE loads
        query = select(Load).where(Load.status == LoadStatus.ACTIVE.value)

        # 3. Apply filters
        # Price filtering
        price_conditions = []
        if min_price is not None:
            price_conditions.append(Load.price_uzs >= min_price)
        if max_price is not None:
            price_conditions.append(Load.price_uzs <= max_price)
        if price_conditions:
            if include_negotiable:
                query = query.where(or_(and_(*price_conditions), Load.price_negotiable.is_(True)))
            else:
                query = query.where(and_(*price_conditions))
        elif not include_negotiable:
            query = query.where(Load.price_negotiable.is_(False))

        # Weight filtering
        if max_tons is not None:
            query = query.where(Load.weight_tons <= max_tons)

        # Truck types
        if truck_types:
            query = query.where(Load.truck_type.in_(truck_types))

        # Regions
        if from_region:
            query = query.where(Load.from_region == from_region)
        if to_region:
            query = query.where(Load.to_region == to_region)

        # Pickup dates
        if pickup_from:
            query = query.where(Load.pickup_date >= pickup_from)
        if pickup_to:
            query = query.where(Load.pickup_date <= pickup_to)

        # Execute query
        result = await self.db.execute(query)
        loads = list(result.scalars().all())

        # 4. Check which loads this driver already submitted a bid for
        bid_stmt = select(Bid.load_id).where(Bid.carrier_id == driver_id)
        bid_res = await self.db.execute(bid_stmt)
        offered_load_ids = set(bid_res.scalars().all())

        # 5. Score and map loads
        feed_items: List[DriverFeedItem] = []
        for l in loads:
            match_pct, reasons, pickup_dist = self.scorer.calculate_match(
                load=l,
                vehicle=primary_vehicle,
                preferences=prefs,
                driver_lat=prefs.current_lat,
                driver_lng=prefs.current_lng,
            )

            feed_items.append(
                DriverFeedItem(
                    id=l.id,
                    cargo_name=l.cargo_name,
                    cargo_type=l.cargo_type,
                    weight_tons=l.weight_tons,
                    volume_m3=l.volume_m3,
                    truck_type=l.truck_type,
                    from_address=l.from_address,
                    from_region=l.from_region,
                    from_city=l.from_city,
                    from_lat=l.from_lat,
                    from_lng=l.from_lng,
                    to_address=l.to_address,
                    to_region=l.to_region,
                    to_city=l.to_city,
                    to_lat=l.to_lat,
                    to_lng=l.to_lng,
                    distance_km=l.distance_km,
                    pickup_date=l.pickup_date,
                    price_uzs=l.price_uzs,
                    price_negotiable=l.price_negotiable,
                    description=l.description,
                    photos=l.photos,
                    match_percent=match_pct,
                    match_reasons=reasons,
                    pickup_distance_km=pickup_dist,
                    already_offered=(l.id in offered_load_ids),
                    created_at=l.created_at,
                )
            )

        # 6. Sorting
        if sort == "match":
            # If driver has vehicle, sort by match_percent desc
            if primary_vehicle:
                feed_items.sort(key=lambda x: (x.match_percent, x.created_at), reverse=True)
            else:
                feed_items.sort(key=lambda x: x.created_at, reverse=True)
        elif sort == "price":
            # Highest price first, negotiable treated with zero/neutral
            feed_items.sort(key=lambda x: (x.price_uzs or 0.0), reverse=True)
        elif sort == "distance":
            # Closest pickup distance first
            feed_items.sort(key=lambda x: (x.pickup_distance_km if x.pickup_distance_km is not None else 999999.0))
        else:  # newest
            feed_items.sort(key=lambda x: x.created_at, reverse=True)

        # Pagination
        total = len(feed_items)
        paginated_items = feed_items[offset : offset + limit]

        return DriverFeedResponse(
            items=paginated_items,
            has_vehicle=(primary_vehicle is not None),
            total=total,
        )

