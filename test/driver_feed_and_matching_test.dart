import 'package:flutter_test/flutter_test.dart';
import 'package:logiflow_mobile/features/driver/domain/models/driver_feed_item_model.dart';
import 'package:logiflow_mobile/features/driver/domain/models/driver_vehicle_model.dart';
import 'package:logiflow_mobile/features/driver/presentation/bloc/driver_bloc.dart';
import 'package:logiflow_mobile/features/driver/presentation/bloc/driver_event.dart';
import 'package:logiflow_mobile/features/driver/presentation/bloc/driver_state.dart';
import 'package:logiflow_mobile/features/driver/domain/repositories/driver_repository.dart';
import 'package:logiflow_mobile/core/network/api_result.dart';

class MockDriverRepository implements IDriverRepository {
  List<DriverVehicleModel> mockVehicles = [];
  List<DriverFeedItemModel> mockFeed = [];

  @override
  Future<ApiResult<List<DriverVehicleModel>>> getVehicles() async {
    return ApiSuccess(mockVehicles);
  }

  @override
  Future<ApiResult<DriverVehicleModel>> addVehicle({
    required String truckType,
    required double capacityTons,
    String? plateNumber,
    bool isPrimary = true,
  }) async {
    final v = DriverVehicleModel(
      id: 'veh-1',
      driverId: 'driver-1',
      truckType: truckType,
      capacityTons: capacityTons,
      plateNumber: plateNumber,
      isPrimary: isPrimary,
    );
    mockVehicles.add(v);
    return ApiSuccess(v);
  }

  @override
  Future<ApiResult<void>> updateLocation({
    required double lat,
    required double lng,
  }) async {
    return const ApiSuccess(null);
  }

  @override
  Future<ApiResult<DriverFeedResponseModel>> getFeed({
    required DriverFeedFilter filter,
    String? searchQuery,
    int limit = 50,
    int offset = 0,
  }) async {
    return ApiSuccess(
      DriverFeedResponseModel(
        items: mockFeed,
        hasVehicle: mockVehicles.isNotEmpty,
        total: mockFeed.length,
      ),
    );
  }
}

void main() {
  group('Part 4: Driver Models & Scorer Tests', () {
    test('DriverVehicleModel serialization and deserialization', () {
      final json = {
        'id': 'veh-100',
        'driver_id': 'drv-100',
        'truck_type': 'REFRIGERATOR',
        'capacity_tons': 22.5,
        'plate_number': '01A123BC',
        'is_primary': true,
        'created_at': '2026-11-13T12:00:00Z',
      };

      final model = DriverVehicleModel.fromJson(json);
      expect(model.id, 'veh-100');
      expect(model.truckType, 'REFRIGERATOR');
      expect(model.capacityTons, 22.5);
      expect(model.plateNumber, '01A123BC');
      expect(model.isPrimary, true);

      final outJson = model.toJson();
      expect(outJson['truck_type'], 'REFRIGERATOR');
      expect(outJson['capacity_tons'], 22.5);
      expect(outJson['is_primary'], true);
    });

    test('DriverFeedFilter activeFilterCount calculation', () {
      var filter = const DriverFeedFilter();
      expect(filter.activeFilterCount, 0);

      filter = filter.copyWith(truckTypes: ['TENT', 'ISOTHERMAL']);
      expect(filter.activeFilterCount, 2);

      filter = filter.copyWith(minPrice: 1000000);
      expect(filter.activeFilterCount, 3);

      filter = filter.copyWith(fromRegion: 'Toshkent shahri');
      expect(filter.activeFilterCount, 4);

      filter = filter.copyWith(includeNegotiable: false);
      expect(filter.activeFilterCount, 5);
    });

    test('DriverFeedItemModel parsing from JSON with match reasons', () {
      final itemJson = {
        'id': 'load-99',
        'cargo_name': 'Poliz mahsulotlari',
        'cargo_type': 'oziq_ovqat',
        'weight_tons': 14.0,
        'volume_m3': 45.0,
        'truck_type': 'REFRIGERATOR',
        'from_address': 'Samarqand markazi',
        'from_region': 'Samarqand viloyati',
        'from_city': 'Samarqand',
        'from_lat': 39.6542,
        'from_lng': 66.9597,
        'to_address': 'Chilonzor, Toshkent',
        'to_region': 'Toshkent shahri',
        'to_city': 'Toshkent',
        'to_lat': 41.2995,
        'to_lng': 69.2401,
        'distance_km': 310.0,
        'pickup_date': '2026-11-15T09:00:00Z',
        'price_uzs': 5500000.0,
        'price_negotiable': false,
        'description': 'Tarvuz va qovunlar',
        'photos': ['https://example.com/photo1.jpg'],
        'match_percent': 88,
        'match_reasons': ['reason_truck_type_match', 'reason_pickup_distance_close'],
        'pickup_distance_km': 15.4,
        'already_offered': true,
        'created_at': '2026-11-13T10:00:00Z',
      };

      final feedItem = DriverFeedItemModel.fromJson(itemJson);
      expect(feedItem.id, 'load-99');
      expect(feedItem.cargoName, 'Poliz mahsulotlari');
      expect(feedItem.matchPercent, 88);
      expect(feedItem.matchReasons.length, 2);
      expect(feedItem.alreadyOffered, true);
      expect(feedItem.pickupDistanceKm, 15.4);
    });

    test('DriverBloc initial and feed request state lifecycle', () async {
      final mockRepo = MockDriverRepository();
      mockRepo.mockFeed = [
        DriverFeedItemModel(
          id: 'ld-1',
          cargoName: 'Meva-cheva',
          cargoType: 'oziq_ovqat',
          weightTons: 10.0,
          truckType: 'TENT',
          fromAddress: 'Andijon',
          fromRegion: 'Andijon viloyati',
          fromCity: 'Andijon',
          fromLat: 40.78,
          fromLng: 72.34,
          toAddress: 'Toshkent',
          toRegion: 'Toshkent shahri',
          toCity: 'Toshkent',
          toLat: 41.29,
          toLng: 69.24,
          distanceKm: 350.0,
          pickupDate: DateTime.now(),
          priceNegotiable: true,
          matchPercent: 75,
          createdAt: DateTime.now(),
        ),
      ];

      final bloc = DriverBloc(mockRepo);
      expect(bloc.state.status, DriverStatus.initial);

      bloc.add(const DriverFeedRequested());
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.status, DriverStatus.success);
      expect(bloc.state.feedItems.length, 1);
      expect(bloc.state.feedItems.first.cargoName, 'Meva-cheva');

      // Test vehicle add
      bloc.add(const DriverVehicleAddRequested(
        truckType: 'TENT',
        capacityTons: 20.0,
        plateNumber: '01A777AA',
      ));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(mockRepo.mockVehicles.length, 1);
      expect(mockRepo.mockVehicles.first.capacityTons, 20.0);

      await bloc.close();
    });
  });
}
