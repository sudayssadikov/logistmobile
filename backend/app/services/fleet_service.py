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

    async def delete_truck(self, truck_id: str) -> bool:
        v = await self.vehicle_repo.get_by_id(truck_id)
        if not v:
            raise NotFoundError("Yuk mashinasi topilmadi.")
        await self.session.delete(v)
        await self.session.flush()
        return True

    async def assign_driver_to_truck(self, truck_id: str, driver_id: str) -> TruckModel:
        truck = await self.vehicle_repo.get_by_id(truck_id)
        if not truck:
            raise NotFoundError("Yuk mashinasi topilmadi.")
        driver = await self.user_repo.get_by_id(driver_id)
        if not driver:
            raise NotFoundError("Haydovchi topilmadi.")

        truck.assigned_driver_id = driver.id
        truck.assigned_driver_name = driver.full_name
        truck.is_available = False

        dp = await self.driver_repo.get_by_user_id(driver.id)
        if not dp:
            dp = DriverProfile(user_id=driver.id)
            self.session.add(dp)
        dp.assigned_truck_id = truck.id
        dp.assigned_vehicle_plate = truck.plate_number
        dp.status = DriverStatus.IN_TRANSIT.value

        await self.session.flush()
        return self._to_truck_model(truck)

    async def unassign_driver_from_truck(self, truck_id: str) -> TruckModel:
        truck = await self.vehicle_repo.get_by_id(truck_id)
        if not truck:
            raise NotFoundError("Yuk mashinasi topilmadi.")

        if truck.assigned_driver_id:
            dp = await self.driver_repo.get_by_user_id(truck.assigned_driver_id)
            if dp:
                dp.assigned_truck_id = None
                dp.assigned_vehicle_plate = None
                dp.status = DriverStatus.IDLE.value

        truck.assigned_driver_id = None
        truck.assigned_driver_name = None
        truck.is_available = True

        await self.session.flush()
        return self._to_truck_model(truck)

    async def get_drivers(self) -> List[DriverModel]:
        drivers = await self.user_repo.get_all()
        driver_users = [u for u in drivers if u.role == UserRole.DRIVER.value]
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
