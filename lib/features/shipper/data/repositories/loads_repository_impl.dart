import 'package:dio/dio.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/services/load_draft_service.dart';
import '../../domain/models/load_model.dart';
import '../../domain/repositories/loads_repository.dart';

class LoadsRepositoryImpl implements ILoadsRepository {
  final DioClient _dioClient;

  LoadsRepositoryImpl(this._dioClient);

  @override
  Future<ApiResult<CreatedLoadModel>> createLoad({
    required CreateLoadDraft draft,
  }) async {
    final from = draft.fromLocation;
    final to = draft.toLocation;
    if (from == null || to == null) {
      return const ApiFailure(message: 'Manzillar to\'liq tanlanmagan.');
    }

    final double weight = double.tryParse(draft.weightTons.replaceAll(',', '.')) ?? 0.0;
    final double? volume = double.tryParse(draft.volumeM3.replaceAll(',', '.'));
    final double? price = draft.priceNegotiable
        ? null
        : double.tryParse(draft.priceUzs.replaceAll(' ', '').replaceAll(',', ''));

    final payload = {
      'cargoName': draft.cargoName.trim(),
      'cargoType': draft.cargoType,
      'weightTons': weight,
      'volumeM3': volume,
      'truckType': draft.truckType,
      'fromLat': from.lat,
      'fromLng': from.lng,
      'fromAddress': from.address,
      'fromRegion': from.region,
      'fromCity': from.city,
      'toLat': to.lat,
      'toLng': to.lng,
      'toAddress': to.address,
      'toRegion': to.region,
      'toCity': to.city,
      'pickupDate': (draft.pickupDate ?? DateTime.now().add(const Duration(days: 1))).toIso8601String(),
      'priceUzs': price,
      'priceNegotiable': draft.priceNegotiable,
      'description': draft.description.trim().isNotEmpty ? draft.description.trim() : null,
      'photos': draft.photos,
    };

    try {
      final response = await _dioClient.post('/loads', data: payload);
      if (response.statusCode == 201 && response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>;
        return ApiSuccess(CreatedLoadModel.fromJson(data));
      }
      return const ApiFailure(message: 'Yukni saqlashda xatolik yuz berdi.');
    } on DioException catch (e) {
      String? msg;
      if (e.response?.data is Map) {
        final resMap = e.response!.data as Map;
        msg = resMap['message'] as String? ?? resMap['detail'] as String?;
      }
      return ApiFailure(message: msg ?? e.message ?? 'Server xatosi');
    } catch (e) {
      return ApiFailure(message: 'Kutilmagan xatolik: ${e.toString()}');
    }
  }

  @override
  Future<ApiResult<CreatedLoadModel>> getLoadById(String id) async {
    try {
      final response = await _dioClient.get('/loads/$id');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>;
        return ApiSuccess(CreatedLoadModel.fromJson(data));
      }
      return const ApiFailure(message: 'Yuk topilmadi.');
    } on DioException catch (e) {
      String? msg;
      if (e.response?.data is Map) {
        final resMap = e.response!.data as Map;
        msg = resMap['message'] as String? ?? resMap['detail'] as String?;
      }
      return ApiFailure(message: msg ?? e.message ?? 'Server xatosi');
    } catch (e) {
      return ApiFailure(message: 'Kutilmagan xatolik: ${e.toString()}');
    }
  }
}

