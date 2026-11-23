import '../../../../core/network/api_result.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/models/driver_vehicle_model.dart';
import '../../domain/models/driver_feed_item_model.dart';
import '../../domain/repositories/driver_repository.dart';

class DriverRepositoryImpl implements IDriverRepository {
  final DioClient? _dioClient;

  DriverRepositoryImpl([this._dioClient]);

  @override
  Future<ApiResult<List<DriverVehicleModel>>> getVehicles() async {
    if (_dioClient == null) {
      return const ApiFailure(message: 'Server bilan aloqa mavjud emas');
    }
    try {
      final response = await _dioClient!.get('/driver/vehicles');
      if (response.statusCode == 200 && response.data != null) {
        final List raw = response.data['data'] ?? [];
        final list = raw.map((e) => DriverVehicleModel.fromJson(e as Map<String, dynamic>)).toList();
        return ApiSuccess(list);
      }
      return ApiFailure(message: response.data?['message'] ?? 'Mashinalarni yuklab bo\'lmadi');
    } catch (e) {
      return ApiFailure(message: 'Serverga ulanishda xatolik: ${e.toString()}');
    }
  }

  @override
  Future<ApiResult<DriverVehicleModel>> addVehicle({
    required String truckType,
    required double capacityTons,
    String? plateNumber,
    bool isPrimary = true,
  }) async {
    if (_dioClient == null) {
      return const ApiFailure(message: 'Server bilan aloqa mavjud emas');
    }
    try {
      final payload = {
        'truck_type': truckType,
        'capacity_tons': capacityTons,
        if (plateNumber != null && plateNumber.isNotEmpty) 'plate_number': plateNumber,
        'is_primary': isPrimary,
      };
      final response = await _dioClient!.post('/driver/vehicles', data: payload);
      if ((response.statusCode == 200 || response.statusCode == 201) && response.data != null) {
        final item = DriverVehicleModel.fromJson(response.data['data']);
        return ApiSuccess(item);
      }
      return ApiFailure(message: response.data?['message'] ?? 'Mashina saqlanmadi');
    } catch (e) {
      return ApiFailure(message: 'Serverga ulanishda xatolik: ${e.toString()}');
    }
  }

  @override
  Future<ApiResult<void>> updateLocation({
    required double lat,
    required double lng,
  }) async {
    if (_dioClient == null) {
      return const ApiFailure(message: 'Server bilan aloqa mavjud emas');
    }
    try {
      final payload = {'lat': lat, 'lng': lng};
      final response = await _dioClient!.put('/driver/location', data: payload);
      if (response.statusCode == 200) {
        return const ApiSuccess(null);
      }
      return ApiFailure(message: response.data?['message'] ?? 'Joylashuv yangilanmadi');
    } catch (e) {
      return ApiFailure(message: 'Serverga ulanishda xatolik: ${e.toString()}');
    }
  }

  @override
  Future<ApiResult<DriverFeedResponseModel>> getFeed({
    required DriverFeedFilter filter,
    String? searchQuery,
    int limit = 50,
    int offset = 0,
  }) async {
    if (_dioClient == null) {
      return const ApiFailure(message: 'Server bilan aloqa mavjud emas');
    }
    try {
      final queryParams = <String, dynamic>{
        'sort': filter.sort,
        'limit': limit,
        'offset': offset,
        'include_negotiable': filter.includeNegotiable,
      };
      if (filter.minPrice != null) queryParams['min_price'] = filter.minPrice;
      if (filter.maxPrice != null) queryParams['max_price'] = filter.maxPrice;
      if (filter.maxTons != null) queryParams['max_tons'] = filter.maxTons;
      if (filter.truckTypes.isNotEmpty) {
        queryParams['truck_types'] = filter.truckTypes;
      }
      if (filter.fromRegion != null && filter.fromRegion!.isNotEmpty) {
        queryParams['from_region'] = filter.fromRegion;
      }
      if (filter.toRegion != null && filter.toRegion!.isNotEmpty) {
        queryParams['to_region'] = filter.toRegion;
      }

      final response = await _dioClient!.get('/driver/feed', queryParameters: queryParams);
      if (response.statusCode == 200 && response.data != null) {
        final resp = DriverFeedResponseModel.fromJson(response.data['data']);
        
        // If there's a search query, filter client-side on cargo name or city/address
        if (searchQuery != null && searchQuery.trim().isNotEmpty) {
          final q = searchQuery.trim().toLowerCase();
          final filteredItems = resp.items.where((i) {
            return i.cargoName.toLowerCase().contains(q) ||
                i.fromCity.toLowerCase().contains(q) ||
                i.toCity.toLowerCase().contains(q) ||
                i.fromRegion.toLowerCase().contains(q) ||
                i.toRegion.toLowerCase().contains(q);
          }).toList();
          return ApiSuccess(
            DriverFeedResponseModel(
              items: filteredItems,
              hasVehicle: resp.hasVehicle,
              total: filteredItems.length,
            ),
          );
        }

        return ApiSuccess(resp);
      }
      return ApiFailure(message: response.data?['message'] ?? 'Yuklar lentasini yuklab bo\'lmadi');
    } catch (e) {
      return ApiFailure(message: 'Serverga ulanishda xatolik: ${e.toString()}');
    }
  }
}

