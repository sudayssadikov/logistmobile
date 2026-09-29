import 'dart:async';
import 'package:uuid/uuid.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/models/truck_model.dart';
import '../../domain/models/driver_model.dart';
import '../../domain/repositories/fleet_repository.dart';

class FleetRepositoryImpl implements IFleetRepository {
  final DioClient? _dioClient;

  final List<TruckModel> _trucks = [
    const TruckModel(
      id: 'TRK-01',
      plateNumber: '01 842 TAA',
      model: 'Volvo FH16 Globetrotter (2023)',
      bodyType: TruckBodyType.refrigerated,
      maxWeightTons: 22.0,
      maxVolumeM3: 86.0,
      assignedDriverId: 'DRV-01',
      assignedDriverName: 'Sardor Qosimov',
      isAvailable: false,
    ),
    const TruckModel(
      id: 'TRK-02',
      plateNumber: '10 719 BBA',
      model: 'MAN TGX 18.480 EfficientLine',
      bodyType: TruckBodyType.tent,
      maxWeightTons: 20.0,
      maxVolumeM3: 92.0,
      assignedDriverId: 'DRV-02',
      assignedDriverName: 'Rustam Aliyev',
      isAvailable: true,
    ),
    const TruckModel(
      id: 'TRK-03',
      plateNumber: '01 405 VAA',
      model: 'Scania R500 V8 Streamline',
      bodyType: TruckBodyType.fura,
      maxWeightTons: 24.0,
      maxVolumeM3: 90.0,
      assignedDriverId: null,
      assignedDriverName: null,
      isAvailable: true,
    ),
  ];

  final List<DriverModel> _drivers = [
    const DriverModel(
      id: 'DRV-01',
      fullName: 'Sardor Qosimov',
      phone: '+998 90 123 45 67',
      email: 'sardor@logiflow.uz',
      rating: 4.9,
      completedTrips: 142,
      status: DriverStatus.inTransit,
      assignedVehiclePlate: '01 842 TAA',
      assignedTruckId: 'TRK-01',
    ),
    const DriverModel(
      id: 'DRV-02',
      fullName: 'Rustam Aliyev',
      phone: '+998 93 987 65 43',
      email: 'rustam@logiflow.uz',
      rating: 4.8,
      completedTrips: 98,
      status: DriverStatus.idle,
      assignedVehiclePlate: '10 719 BBA',
      assignedTruckId: 'TRK-02',
    ),
    const DriverModel(
      id: 'DRV-03',
      fullName: 'Bobur Shokirov',
      phone: '+998 97 555 12 34',
      email: 'bobur@logiflow.uz',
      rating: 4.7,
      completedTrips: 64,
      status: DriverStatus.offDuty,
      assignedVehiclePlate: null,
      assignedTruckId: null,
    ),
  ];

  FleetRepositoryImpl([this._dioClient]);

  @override
  Future<List<TruckModel>> getTrucks() async {
    if (_dioClient != null) {
      try {
        final response = await _dioClient!.get('/fleet/trucks');
        if (response.statusCode == 200 && response.data != null) {
          final List raw = response.data['data'] ?? [];
          if (raw.isNotEmpty) {
            return raw.map((e) => TruckModel.fromJson(e)).toList();
          }
        }
      } catch (_) {
        // Fallback
      }
    }
    await Future.delayed(const Duration(milliseconds: 150));
    return List.from(_trucks);
  }

  @override
  Future<List<DriverModel>> getDrivers() async {
    if (_dioClient != null) {
      try {
        final response = await _dioClient!.get('/fleet/drivers');
        if (response.statusCode == 200 && response.data != null) {
          final List raw = response.data['data'] ?? [];
          if (raw.isNotEmpty) {
            return raw.map((e) => DriverModel.fromJson(e)).toList();
          }
        }
      } catch (_) {
        // Fallback
      }
    }
    await Future.delayed(const Duration(milliseconds: 150));
    return List.from(_drivers);
  }

  @override
  Future<TruckModel> addTruck(TruckModel truck) async {
    if (_dioClient != null) {
      try {
        final response = await _dioClient!.post('/fleet/trucks', data: truck.toJson());
        if (response.statusCode == 200 && response.data != null) {
          return TruckModel.fromJson(response.data['data']);
        }
      } catch (_) {
        // Fallback
      }
    }
    await Future.delayed(const Duration(milliseconds: 200));
    final newTruck = truck.copyWith(
      id: 'TRK-${const Uuid().v4().substring(0, 6).toUpperCase()}',
    );
    _trucks.insert(0, newTruck);
    return newTruck;
  }

  @override
  Future<TruckModel> updateTruck(TruckModel truck) async {
    if (_dioClient != null) {
      try {
        final response = await _dioClient!.put('/fleet/trucks/${truck.id}', data: truck.toJson());
        if (response.statusCode == 200 && response.data != null) {
          return TruckModel.fromJson(response.data['data']);
        }
      } catch (_) {
        // Fallback
      }
    }
    await Future.delayed(const Duration(milliseconds: 150));
    final index = _trucks.indexWhere((t) => t.id == truck.id);
    if (index != -1) {
      _trucks[index] = truck;
    }
    return truck;
  }

  @override
  Future<void> assignDriver({required String truckId, required String driverId}) async {
    if (_dioClient != null) {
      try {
        await _dioClient!.post('/fleet/assign', data: {'truck_id': truckId, 'driver_id': driverId});
      } catch (_) {
        // Fallback
      }
    }
    await Future.delayed(const Duration(milliseconds: 150));
    final driver = _drivers.firstWhere((d) => d.id == driverId);
    final truckIndex = _trucks.indexWhere((t) => t.id == truckId);
    if (truckIndex != -1) {
      _trucks[truckIndex] = _trucks[truckIndex].copyWith(
        assignedDriverId: driver.id,
        assignedDriverName: driver.fullName,
      );
    }
    final driverIndex = _drivers.indexWhere((d) => d.id == driverId);
    if (driverIndex != -1 && truckIndex != -1) {
      _drivers[driverIndex] = _drivers[driverIndex].copyWith(
        assignedVehiclePlate: _trucks[truckIndex].plateNumber,
        assignedTruckId: truckId,
      );
    }
  }

  @override
  Future<void> unassignDriver(String truckId) async {
    if (_dioClient != null) {
      try {
        await _dioClient!.post('/fleet/unassign', data: {'truck_id': truckId});
      } catch (_) {
        // Fallback
      }
    }
    await Future.delayed(const Duration(milliseconds: 150));
    final truckIndex = _trucks.indexWhere((t) => t.id == truckId);
    if (truckIndex != -1) {
      final oldDriverId = _trucks[truckIndex].assignedDriverId;
      _trucks[truckIndex] = _trucks[truckIndex].copyWith(
        assignedDriverId: null,
        assignedDriverName: null,
      );
      if (oldDriverId != null) {
        final driverIndex = _drivers.indexWhere((d) => d.id == oldDriverId);
        if (driverIndex != -1) {
          _drivers[driverIndex] = _drivers[driverIndex].copyWith(
            assignedVehiclePlate: null,
            assignedTruckId: null,
          );
        }
      }
    }
  }
}
