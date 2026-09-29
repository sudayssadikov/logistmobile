import '../models/truck_model.dart';
import '../models/driver_model.dart';

abstract class IFleetRepository {
  Future<List<TruckModel>> getTrucks();
  Future<List<DriverModel>> getDrivers();
  Future<TruckModel> addTruck(TruckModel truck);
  Future<TruckModel> updateTruck(TruckModel truck);
  Future<void> assignDriver({required String truckId, required String driverId});
  Future<void> unassignDriver(String truckId);
}
