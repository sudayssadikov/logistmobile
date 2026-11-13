import '../../../../core/network/api_result.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/models/sos_model.dart';
import '../../domain/repositories/sos_repository.dart';

class SosRepositoryImpl implements ISosRepository {
  final DioClient? _dioClient;

  SosRepositoryImpl([this._dioClient]);

  @override
  Future<ApiResult<List<NearbySosProvider>>> getNearbySosProviders({
    required double latitude,
    required double longitude,
    SosServiceType? filterType,
  }) async {
    if (_dioClient == null) {
      return const ApiFailure(message: 'Tarmoq mijozi mavjud emas');
    }
    try {
      final response = await _dioClient!.get(
        '/sos/providers',
        queryParameters: {'lat': latitude, 'lng': longitude},
      );
      if (response.statusCode == 200 && response.data != null) {
        final List raw = response.data['data'] ?? [];
        final items = raw.map((e) => NearbySosProvider.fromJson(e as Map<String, dynamic>)).toList();
        if (filterType != null) {
          return ApiSuccess(items.where((p) => p.type == filterType).toList());
        }
        return ApiSuccess(items);
      }
      return ApiFailure(message: response.data?['message'] ?? 'SOS provayderlarini yuklab bo\'lmadi');
    } catch (e) {
      return ApiFailure(message: 'Serverga ulanishda xatolik: ${e.toString()}');
    }
  }

  @override
  Future<ApiResult<bool>> dispatchEmergencyAlert({
    required double latitude,
    required double longitude,
    required SosServiceType type,
    required String driverPhone,
    required String notes,
  }) async {
    if (_dioClient == null) {
      return const ApiFailure(message: 'Tarmoq mijozi mavjud emas');
    }
    try {
      final response = await _dioClient!.post(
        '/sos/trigger',
        data: {
          'latitude': latitude,
          'longitude': longitude,
          'service_type': type.key,
          'description': notes,
        },
      );
      if (response.statusCode == 200) {
        return const ApiSuccess(true);
      }
      return ApiFailure(message: response.data?['message'] ?? 'SOS xabarini yuborib bo\'lmadi');
    } catch (e) {
      return ApiFailure(message: 'SOS signalini yuborishda xatolik: ${e.toString()}');
    }
  }
}
