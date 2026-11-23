import '../../../../core/network/api_result.dart';
import '../models/driver_vehicle_model.dart';
import '../models/driver_feed_item_model.dart';

abstract class IDriverRepository {
  Future<ApiResult<List<DriverVehicleModel>>> getVehicles();
  Future<ApiResult<DriverVehicleModel>> addVehicle({
    required String truckType,
    required double capacityTons,
    String? plateNumber,
    bool isPrimary = true,
  });
  Future<ApiResult<void>> updateLocation({
    required double lat,
    required double lng,
  });
  Future<ApiResult<DriverFeedResponseModel>> getFeed({
    required DriverFeedFilter filter,
    String? searchQuery,
    int limit = 50,
    int offset = 0,
  });
}

