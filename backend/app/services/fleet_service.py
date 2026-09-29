from typing import List, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.enums import DriverStatus, TruckBodyType, UserRole
from app.core.exceptions import NotFoundError
from app.models.user import User
from app.models.vehicle import Vehicle
from app.models.driver import DriverProfile
from app.repositories.dispute_repo import DriverProfileRepository, VehicleRepository
from app.repositories.user_repo import UserRepository
from app.schemas.driver import DriverModel, DriverPreferences, UpdateDriverStatusRequest
from app.schemas.vehicle import CreateTruckRequest, TruckModel, UpdateTruckRequest

class FleetService:
    def __init__(self, session: AsyncSession):
        self.session = session
        self.vehicle_repo = VehicleRepository(session)
        self.driver_repo = DriverProfileRepository(session)
        self.user_repo = UserRepository(session)

    def _to_truck_model(self, v: Vehicle) -> TruckModel:
        return TruckModel(
            id=v.id,
            plateNumber=v.plate_number,
            model=v.model,
            bodyType=v.body_type,
            maxWeightTons=v.max_weight_tons,
            maxVolumeM3=v.max_volume_m3,
            assignedDriverId=v.assigned_driver_id,
            assignedDriverName=v.assigned_driver_name,
            isAvailable=v.is_available,
        )

    def _to_driver_model(self, u: User, dp: Optional[DriverProfile] = None) -> DriverModel:
        status = dp.status if dp else DriverStatus.IDLE.value
        assigned_plate = dp.assigned_vehicle_plate if dp else u.vehicle_plate
        assigned_truck_id = dp.assigned_truck_id if dp else None

        return DriverModel(
            id=u.id,
            fullName=u.full_name,
            phone=u.phone,
            email=u.email,
            rating=u.rating,
            completedTrips=u.completed_trips,
            status=status,
            assignedVehiclePlate=assigned_plate,
            assignedTruckId=assigned_truck_id,
        )

    async def get_trucks(self) -> List[TruckModel]:
        vehicles = await self.vehicle_repo.get_all()
        if not vehicles:
            # Seed initial fleet trucks if empty
            v1 = Vehicle(
                plate_number="01 842 TAA",
                model="MAN TGX 18.500 (2022)",
                body_type=TruckBodyType.REFRIGERATED.value,
                max_weight_tons=22.0,
                max_volume_m3=86.0,
                assigned_driver_name="Rustam Karimov",
                is_available=True,
            )
            v2 = Vehicle(
                plate_number="01 555 XYZ",
                model="Scania R450 Streamline",
                body_type=TruckBodyType.TENT.value,
                max_weight_tons=24.0,
                max_volume_m3=92.0,
                assigned_driver_name="Nodirbek Qodirov",
                is_available=True,
            )
            self.session.add_all([v1, v2])
            await self.session.flush()
            vehicles = [v1, v2]

        return [self._to_truck_model(v) for v in vehicles]

    async def create_truck(self, req: CreateTruckRequest) -> TruckModel:
        v = Vehicle(
            plate_number=req.plate_number,
            model=req.model,
            body_type=req.body_type,
            max_weight_tons=req.max_weight_tons,
            max_volume_m3=req.max_volume_m3,
            assigned_driver_id=req.assigned_driver_id,
            assigned_driver_name=req.assigned_driver_name,
            is_available=req.is_available,
        )
        await self.vehicle_repo.create(v)
        return self._to_truck_model(v)

    async def get_drivers(self) -> List[DriverModel]:
        drivers = await self.user_repo.get_all()
        driver_users = [u for u in drivers if u.role in [UserRole.DRIVER.value, UserRole.CARRIER.value]]
        if not driver_users:
            return [
                DriverModel(
                    id="DRV-1",
                    fullName="Rustam Karimov",
                    phone="+998 97 765 43 21",
                    email="rustam.driver@logiflow.uz",
                    rating=4.92,
                    completedTrips=156,
                    status=DriverStatus.IN_TRANSIT.value,
                    assignedVehiclePlate="01 842 TAA (MAN TGX)",
                ),
                DriverModel(
                    id="DRV-2",
                    fullName="Nodirbek Qodirov",
                    phone="+998 90 333 44 55",
                    email="nodir.driver@logiflow.uz",
                    rating=4.88,
                    completedTrips=94,
                    status=DriverStatus.IDLE.value,
                    assignedVehiclePlate="01 555 XYZ (Scania)",
                ),
            ]

        results = []
        for u in driver_users:
            dp = await self.driver_repo.get_by_user_id(u.id)
            results.append(self._to_driver_model(u, dp))
        return results

    async def update_driver_status(self, driver_user_id: str, req: UpdateDriverStatusRequest) -> DriverModel:
        user = await self.user_repo.get_by_id(driver_user_id)
        if not user:
            raise NotFoundError("Driver not found.")

        dp = await self.driver_repo.get_by_user_id(driver_user_id)
        if not dp:
            dp = DriverProfile(user_id=user.id)
            self.session.add(dp)

        dp.status = req.status.value
        if req.assigned_vehicle_plate:
            dp.assigned_vehicle_plate = req.assigned_vehicle_plate
        if req.assigned_truck_id:
            dp.assigned_truck_id = req.assigned_truck_id

        await self.session.flush()
        return self._to_driver_model(user, dp)
