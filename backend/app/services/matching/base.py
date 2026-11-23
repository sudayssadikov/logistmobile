from abc import ABC, abstractmethod
from typing import List, Optional, Tuple
from app.models.load import Load
from app.models.driver_vehicle import DriverVehicle, DriverPreferences

class MatchScorer(ABC):
    @abstractmethod
    def calculate_match(
        self,
        load: Load,
        vehicle: Optional[DriverVehicle],
        preferences: Optional[DriverPreferences],
        driver_lat: Optional[float] = None,
        driver_lng: Optional[float] = None,
    ) -> Tuple[int, List[str], Optional[float]]:
        """
        Calculates matching score between a load and a driver.
        Returns:
            - match_percent: int (0 to 100)
            - match_reasons: List[str] (i18n keys)
            - pickup_distance_km: Optional[float] (distance to pickup location)
        """
        pass

