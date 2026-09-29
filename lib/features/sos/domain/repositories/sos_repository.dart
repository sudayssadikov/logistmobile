import '../../../../core/network/api_result.dart';
import '../models/sos_model.dart';

abstract class ISosRepository {
  Future<ApiResult<List<NearbySosProvider>>> getNearbySosProviders({
    required double latitude,
    required double longitude,
    SosServiceType? filterType,
  });

  Future<ApiResult<bool>> dispatchEmergencyAlert({
    required double latitude,
    required double longitude,
    required SosServiceType type,
    required String driverPhone,
    required String notes,
  });
}
