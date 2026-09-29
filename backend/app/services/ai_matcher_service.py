import math
from typing import Dict, List, Tuple
from sqlalchemy.ext.asyncio import AsyncSession
from app.repositories.shipment_repo import ShipmentRepository
from app.repositories.user_repo import UserRepository
from app.schemas.driver import DriverPreferences
from app.schemas.shipment import MatchedShipmentResponse
from app.services.shipment_service import ShipmentService

CITY_COORDINATES: Dict[str, Tuple[float, float]] = {
    "tashkent": (41.2995, 69.2401),
    "toshkent": (41.2995, 69.2401),
    "samarkand": (39.6542, 66.9597),
    "samarqand": (39.6542, 66.9597),
    "bukhara": (39.7681, 64.4556),
    "buxoro": (39.7681, 64.4556),
    "andijan": (40.7821, 72.3442),
    "andijon": (40.7821, 72.3442),
    "namangan": (40.9983, 71.6726),
    "fergana": (40.3842, 71.7843),
    "farg'ona": (40.3842, 71.7843),
    "nukus": (42.4619, 59.6166),
    "qarshi": (38.8606, 65.7891),
    "urgench": (41.5504, 60.6317),
    "urganch": (41.5504, 60.6317),
    "termez": (37.2242, 67.2783),
    "termiz": (37.2242, 67.2783),
    "jizzakh": (40.1158, 67.8422),
    "jizzax": (40.1158, 67.8422),
    "gulistan": (40.4897, 68.7842),
    "guliston": (40.4897, 68.7842),
    "navoiy": (40.0844, 65.3792),
    "almaty": (43.2220, 76.8512),
    "shymkent": (42.3417, 69.5901),
}

def haversine_distance_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """Calculates great-circle distance between two GPS coordinates in kilometers."""
    radius_earth_km = 6371.0
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = (
        math.sin(dlat / 2) ** 2
        + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlon / 2) ** 2
    )
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return round(radius_earth_km * c, 1)

class AIMatcherService:
    def __init__(self, session: AsyncSession):
        self.session = session
        self.shipment_repo = ShipmentRepository(session)
        self.user_repo = UserRepository(session)
        self.shipment_service = ShipmentService(session)

    async def get_matched_shipments_for_driver(
        self,
        driver_user_id: str,
        prefs: DriverPreferences,
    ) -> List[MatchedShipmentResponse]:
        # Get open shipments available for bids
        open_shipments = await self.shipment_repo.search_shipments(filter_status="pendingBid")
        if not open_shipments:
            open_shipments = await self.shipment_repo.search_shipments()

        driver_city_clean = (prefs.currentCity or "Tashkent").lower().strip()
        driver_lat, driver_lng = CITY_COORDINATES.get(driver_city_clean, (41.2995, 69.2401))

        results: List[MatchedShipmentResponse] = []
        for s in open_shipments:
            score = 75
            is_return = False

            # Determine origin and destination coords
            orig_lat = s.origin_lat or CITY_COORDINATES.get(s.origin_city.lower().strip(), (41.2995, 69.2401))[0]
            orig_lng = s.origin_lng or CITY_COORDINATES.get(s.origin_city.lower().strip(), (41.2995, 69.2401))[1]
            
            # Compute actual Haversine distance from driver's location to pickup
            distance_from_driver = haversine_distance_km(driver_lat, driver_lng, orig_lat, orig_lng)

            # City match bonus
            orig_clean = s.origin_city.lower().strip()
            dest_clean = s.dest_city.lower().strip()

            if orig_clean in driver_city_clean or driver_city_clean in orig_clean:
                score += 15
                ai_reason = f"High priority: Direct pickup in {prefs.currentCity} ({distance_from_driver} km away)."
            elif dest_clean in driver_city_clean or driver_city_clean in dest_clean:
                score += 18
                is_return = True
                ai_reason = f"Backhaul return load to {prefs.currentCity}. Maximizes empty miles efficiency."
            else:
                ai_reason = f"Regional highway transit route ({distance_from_driver} km to pickup)."

            # Weight and volume compatibility
            if s.weight_tons <= prefs.maxWeightTons:
                score += 5
            else:
                score -= 10

            # Distance penalty if too far
            if distance_from_driver > prefs.maxRadiusKm:
                score -= min(15, int((distance_from_driver - prefs.maxRadiusKm) / 20))

            # Calculate match percentage (cap between 40% and 99%)
            match_pct = max(40, min(score, 99))
            shipment_model = self.shipment_service._to_shipment_model(s)

            results.append(
                MatchedShipmentResponse(
                    shipment=shipment_model,
                    match_percentage=match_pct,
                    distance_from_driver_km=distance_from_driver,
                    ai_reason=ai_reason,
                    is_return_trip=is_return,
                )
            )

        results.sort(key=lambda x: x.match_percentage, reverse=True)
        return results
