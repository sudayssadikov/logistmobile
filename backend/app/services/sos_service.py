import math
from typing import List
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.enums import SosServiceType
from app.models.sos import SosProvider, SosRequest
from app.repositories.dispute_repo import SosRepository
from app.schemas.sos import NearbySosProvider, SosRequestResponse, TriggerSosRequest

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

class SosService:
    def __init__(self, session: AsyncSession):
        self.session = session
        self.sos_repo = SosRepository(session)

    async def get_nearby_providers(self, lat: float = 41.2995, lng: float = 69.2401) -> List[NearbySosProvider]:
        providers = await self.sos_repo.get_active_providers()
        if not providers:
            # Standard seed providers across Tashkent corridor
            fallback_data = [
                (
                    "SOS-01",
                    "TIR Evakuator 24/7 Toshkent",
                    SosServiceType.HEAVY_TOW_TRUCK,
                    "+998 90 123 45 67",
                    41.2215,
                    69.2155,
                    4.95,
                    "M39 trassa, 14-km, Sergeli",
                ),
                (
                    "SOS-02",
                    "TIR Mobil Vulkanizatsiya & Balansirovka",
                    SosServiceType.TYRE_REPAIR,
                    "+998 93 987 65 43",
                    41.2580,
                    69.3400,
                    4.88,
                    "Katta halqa yo'li, Bektemir",
                ),
                (
                    "SOS-03",
                    "Fura Dizel Servis & Kompyuter Diagnostika",
                    SosServiceType.DIESEL_REPAIR,
                    "+998 97 555 11 22",
                    41.1950,
                    69.1800,
                    4.91,
                    "Erkin bojxona posti yaqinida",
                ),
                (
                    "SOS-04",
                    "Mobil Yoqilg'i & Euro-5 Dizel Yetkazish",
                    SosServiceType.FUEL_DELIVERY,
                    "+998 99 888 77 66",
                    41.1500,
                    69.1200,
                    4.79,
                    "Yangiyo'l trassasi",
                ),
            ]

            results = []
            for pid, name, stype, phone, plat, plng, rating, addr in fallback_data:
                dist = haversine_distance_km(lat, lng, plat, plng)
                eta_min = max(10, int(dist * 2.5))
                results.append(
                    NearbySosProvider(
                        id=pid,
                        name=name,
                        type=stype,
                        phone=phone,
                        distanceKm=dist,
                        rating=rating,
                        address=addr,
                        is24_7=True,
                        estimatedArrivalMinutes=f"{eta_min}-{eta_min + 5} min",
                    )
                )
            results.sort(key=lambda p: p.distanceKm)
            return results

        # Process real DB providers
        results = []
        for p in providers:
            dist = haversine_distance_km(lat, lng, p.latitude, p.longitude)
            eta_min = max(8, int(dist * 2.5))
            results.append(
                NearbySosProvider(
                    id=p.id,
                    name=p.name,
                    type=SosServiceType(p.type) if p.type in [s.value for s in SosServiceType] else SosServiceType.HEAVY_TOW_TRUCK,
                    phone=p.phone,
                    distanceKm=dist,
                    rating=p.rating,
                    address=p.address,
                    is24_7=p.is_24_7,
                    estimatedArrivalMinutes=f"{eta_min} min",
                )
            )

        results.sort(key=lambda p: p.distanceKm)
        return results

    async def trigger_sos(self, driver_id: str, req: TriggerSosRequest) -> SosRequestResponse:
        sos = SosRequest(
            driver_id=driver_id,
            shipment_id=req.shipment_id,
            service_type=req.service_type.value,
            latitude=req.latitude,
            longitude=req.longitude,
            description=req.description or "Emergency roadside assistance requested",
        )
        self.session.add(sos)
        await self.session.flush()

        return SosRequestResponse(
            id=sos.id,
            driver_id=sos.driver_id,
            service_type=sos.service_type,
            latitude=sos.latitude,
            longitude=sos.longitude,
            description=sos.description,
            is_resolved=sos.is_resolved,
            created_at=sos.created_at,
        )
