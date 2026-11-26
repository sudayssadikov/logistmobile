import math
from datetime import datetime, timezone
from typing import Dict, List, Optional, Tuple
from app.models.load import Load
from app.models.driver_vehicle import DriverVehicle, DriverPreferences
from app.services.matching.base import MatchScorer

# Region centers in Uzbekistan
REGION_CENTERS: Dict[str, Tuple[float, float]] = {
    "Toshkent shahri": (41.2995, 69.2401),
    "Toshkent viloyati": (41.2000, 69.3000),
    "Samarqand viloyati": (39.6542, 66.9597),
    "Buxoro viloyati": (39.7681, 64.4556),
    "Andijon viloyati": (40.7821, 72.3442),
    "Farg'ona viloyati": (40.3842, 71.7843),
    "Namangan viloyati": (40.9983, 71.6726),
    "Qashqadaryo viloyati": (38.8606, 65.7891),
    "Surxondaryo viloyati": (37.2242, 67.2783),
    "Jizzax viloyati": (40.1158, 67.8422),
    "Sirdaryo viloyati": (40.8436, 68.6617),
    "Navoiy viloyati": (40.0844, 65.3792),
    "Xorazm viloyati": (41.5562, 60.6310),
    "Qoraqalpog'iston Respublikasi": (42.4602, 59.6166),
}

def haversine_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    R = 6371.0  # Earth radius in kilometers
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = (
        math.sin(dlat / 2) ** 2
        + math.cos(math.radians(lat1))
        * math.cos(math.radians(lat2))
        * math.sin(dlon / 2) ** 2
    )
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return round(R * c, 1)

class RuleBasedScorer(MatchScorer):
    # Weights sum to 100
    WEIGHT_TRUCK_TYPE = 30
    WEIGHT_CAPACITY = 15
    WEIGHT_PICKUP_DIST = 25
    WEIGHT_ROUTE_PREF = 10
    WEIGHT_PRICE = 15
    WEIGHT_DATE = 5

    def calculate_match(
        self,
        load: Load,
        vehicle: Optional[DriverVehicle],
        preferences: Optional[DriverPreferences],
        driver_lat: Optional[float] = None,
        driver_lng: Optional[float] = None,
    ) -> Tuple[int, List[str], Optional[float]]:
        # If no vehicle is registered, we cannot score accurately
        if not vehicle:
            return 0, ["reason_no_vehicle"], None

        # 1. HARD FILTERS
        # Cargo weight must not exceed vehicle capacity
        if load.weight_tons > vehicle.capacity_tons:
            return 0, ["reason_capacity_exceeded"], None

        # Truck type compatibility check:
        # Compatible if exact match or either is 'OTHER' / general
        is_type_compatible = (
            vehicle.truck_type == load.truck_type
            or vehicle.truck_type == "OTHER"
            or load.truck_type == "OTHER"
        )
        if not is_type_compatible:
            return 0, ["reason_truck_type_mismatch"], None

        score = 0.0
        reasons: List[str] = []

        # 2. SCORING COMPONENTS
        # a) Truck type match (30 pts)
        if vehicle.truck_type == load.truck_type:
            score += self.WEIGHT_TRUCK_TYPE
            reasons.append("reason_truck_type_match")
        else:
            score += self.WEIGHT_TRUCK_TYPE * 0.5

        # b) Capacity utilization (15 pts)
        utilization = load.weight_tons / max(vehicle.capacity_tons, 0.1)
        if 0.5 <= utilization <= 1.0:
            score += self.WEIGHT_CAPACITY
            reasons.append("reason_capacity_optimal")
        elif utilization > 0:
            score += self.WEIGHT_CAPACITY * (utilization / 0.5)

        # Determine driver coordinates
        eff_lat = driver_lat
        eff_lng = driver_lng
        if eff_lat is None or eff_lng is None:
            if preferences and preferences.current_lat is not None and preferences.current_lng is not None:
                eff_lat = preferences.current_lat
                eff_lng = preferences.current_lng
            elif preferences and preferences.home_region in REGION_CENTERS:
                eff_lat, eff_lng = REGION_CENTERS[preferences.home_region]
            else:
                eff_lat, eff_lng = REGION_CENTERS["Toshkent shahri"]

        # c) Distance to pickup (25 pts)
        pickup_dist: Optional[float] = None
        if eff_lat is not None and eff_lng is not None:
            pickup_dist = haversine_km(eff_lat, eff_lng, load.from_lat, load.from_lng)
            if pickup_dist <= 25.0:
                score += self.WEIGHT_PICKUP_DIST
                reasons.append("reason_pickup_distance_close")
            elif pickup_dist <= 75.0:
                score += self.WEIGHT_PICKUP_DIST * 0.8
                reasons.append("reason_pickup_distance_close")
            elif pickup_dist <= 150.0:
                score += self.WEIGHT_PICKUP_DIST * 0.5
            elif pickup_dist <= 300.0:
                score += self.WEIGHT_PICKUP_DIST * 0.2
            else:
                score += 0.0

        # d) Route preference (10 pts)
        if preferences:
            has_from_match = (
                load.from_region in preferences.preferred_from_regions
                or load.from_region == preferences.home_region
            )
            has_to_match = load.to_region in preferences.preferred_to_regions
            if has_from_match and has_to_match:
                score += self.WEIGHT_ROUTE_PREF
                reasons.append("reason_route_preferred")
            elif has_from_match or has_to_match:
                score += self.WEIGHT_ROUTE_PREF * 0.7
                reasons.append("reason_route_preferred")

        # e) Price score (15 pts)
        if load.price_negotiable:
            score += self.WEIGHT_PRICE * 0.5  # Negotiable gets neutral 50%
        elif load.price_uzs is not None:
            min_expected = preferences.min_price_uzs if (preferences and preferences.min_price_uzs) else None
            if min_expected and load.price_uzs >= min_expected:
                score += self.WEIGHT_PRICE
                reasons.append("reason_price_attractive")
            elif min_expected and load.price_uzs < min_expected:
                ratio = max(0.0, load.price_uzs / min_expected)
                score += self.WEIGHT_PRICE * ratio
            else:
                # Default baseline score if no min_price set
                score += self.WEIGHT_PRICE * 0.8
                reasons.append("reason_price_attractive")

        # f) Pickup date proximity (5 pts)
        now = datetime.now(timezone.utc)
        pickup_dt = load.pickup_date
        if pickup_dt.tzinfo is None:
            pickup_dt = pickup_dt.replace(tzinfo=timezone.utc)
        hours_diff = (pickup_dt - now).total_seconds() / 3600.0
        if 0 <= hours_diff <= 48:
            score += self.WEIGHT_DATE
            reasons.append("reason_date_soon")
        elif 48 < hours_diff <= 120:
            score += self.WEIGHT_DATE * 0.6
        else:
            score += self.WEIGHT_DATE * 0.3

        match_percent = max(0, min(100, int(round(score))))
        return match_percent, reasons, pickup_dist

