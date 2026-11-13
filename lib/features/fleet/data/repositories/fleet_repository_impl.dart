import 'dart:async';
import '../../../../core/network/dio_client.dart';
import '../../domain/models/truck_model.dart';
import '../../domain/models/driver_model.dart';
import '../../domain/repositories/fleet_repository.dart';

class FleetRepositoryImpl implements IFleetRepository {
  final DioClient? _dioClient;

  FleetRepositoryImpl([this._dioClient]);

  @override
  Future<List<TruckModel>> getTrucks() async {
    if (_dioClient == null) return [];
    try {
      final response = await _dioClient!.get('/fleet/trucks');
      if (response.statusCode == 200 && response.data != null) {
        final List raw = response.data['data'] ?? [];
        return raw.map((e) => TruckModel.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

  @override
  Future<List<DriverModel>> getDrivers() async {
    if (_dioClient == null) return [];
    try {
      final response = await _dioClient!.get('/fleet/drivers');
      if (response.statusCode == 200 && response.data != null) {
        final List raw = response.data['data'] ?? [];
        return raw.map((e) => DriverModel.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

  @override
  Future<TruckModel> addTruck(TruckModel truck) async {
    if (_dioClient == null) {
      throw Exception('Server bilan aloqa mavjud emas');
    }
    final response = await _dioClient!.post(
      '/fleet/trucks',
      data: {
        'plate_number': truck.plateNumber,
        'model': truck.model,
        'body_type': truck.bodyType.name,
        'max_weight_tons': truck.maxWeightTons,
        'max_volume_m3': truck.maxVolumeM3,
        'is_available': truck.isAvailable,
      },
    );
    if (response.statusCode == 200 && response.data != null) {
      return TruckModel.fromJson(response.data['data']);
    }
    throw Exception(response.data?['message'] ?? 'Yuk mashinasini qo\'shib bo\'lmadi');
  }

  @override
  Future<TruckModel> updateTruck(TruckModel truck) async {
    if (_dioClient == null) return truck;
    try {
      final response = await _dioClient!.put('/fleet/trucks/${truck.id}', data: truck.toJson());
      if (response.statusCode == 200 && response.data != null) {
        return TruckModel.fromJson(response.data['data']);
      }
    } catch (_) {}
    return truck;
  }

  @override
  Future<void> assignDriver({required String truckId, required String driverId}) async {
    if (_dioClient == null) {
      throw Exception('Server bilan aloqa mavjud emas');
    }
    final response = await _dioClient!.post(
      '/fleet/assign',
      data: {'truck_id': truckId, 'driver_id': driverId},
    );
    if (response.statusCode != 200) {
      throw Exception(response.data?['message'] ?? 'Haydovchini biriktirib bo\'lmadi');
    }
  }

  @override
  Future<void> unassignDriver(String truckId) async {
    if (_dioClient == null) {
      throw Exception('Server bilan aloqa mavjud emas');
    }
    final response = await _dioClient!.post(
      '/fleet/unassign',
      data: {'truck_id': truckId},
    );
    if (response.statusCode != 200) {
      throw Exception(response.data?['message'] ?? 'Haydovchini ajratib bo\'lmadi');
    }
  }
}
