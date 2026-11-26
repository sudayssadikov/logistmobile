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

  @override
  Future<ApiResult<PaginatedLoadSummary>> getMyLoads({
    required String statusGroup,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _dioClient.get(
        '/loads/mine',
        queryParameters: {
          'status_group': statusGroup,
          'page': page,
          'limit': limit,
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>;
        return ApiSuccess(PaginatedLoadSummary.fromJson(data));
      }
      return const ApiFailure(message: 'Yuklar ro\'yxatini olishda xatolik yuz berdi.');
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
  Future<ApiResult<CreatedLoadModel>> updateLoad(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dioClient.patch('/loads/$id', data: data);
      if (response.statusCode == 200 && response.data != null) {
        final resData = response.data['data'] as Map<String, dynamic>;
        return ApiSuccess(CreatedLoadModel.fromJson(resData));
      }
      return const ApiFailure(message: 'Yukni yangilashda xatolik yuz berdi.');
    } on DioException catch (e) {
      String? msg;
      if (e.response?.data is Map) {
        final resMap = e.response!.data as Map;
        msg = resMap['message'] as String? ?? resMap['detail'] as String?;
      }
      final statusCode = e.response?.statusCode;
      return ApiFailure(
        message: msg ?? e.message ?? 'Server xatosi',
        statusCode: statusCode,
      );
    } catch (e) {
      return ApiFailure(message: 'Kutilmagan xatolik: ${e.toString()}');
    }
  }

  @override
  Future<ApiResult<void>> cancelLoad(
    String id, {
    String? reason,
  }) async {
    try {
      final response = await _dioClient.post(
        '/loads/$id/cancel',
        data: reason != null ? {'reason': reason} : null,
      );
      if (response.statusCode == 200) {
        return const ApiSuccess(null);
      }
      return const ApiFailure(message: 'Yukni bekor qilishda xatolik yuz berdi.');
    } on DioException catch (e) {
      String? msg;
      if (e.response?.data is Map) {
        final resMap = e.response!.data as Map;
        msg = resMap['message'] as String? ?? resMap['detail'] as String?;
      }
      return ApiFailure(
        message: msg ?? e.message ?? 'Server xatosi',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return ApiFailure(message: 'Kutilmagan xatolik: ${e.toString()}');
    }
  }

  @override
  Future<ApiResult<CreatedLoadModel>> duplicateLoad(String id) async {
    try {
      final response = await _dioClient.post('/loads/$id/duplicate');
      if (response.statusCode == 201 && response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>;
        return ApiSuccess(CreatedLoadModel.fromJson(data));
      }
      return const ApiFailure(message: 'Yukdan nusxa ko\'chirishda xatolik yuz berdi.');
    } on DioException catch (e) {
      String? msg;
      if (e.response?.data is Map) {
        final resMap = e.response!.data as Map;
        msg = resMap['message'] as String? ?? resMap['detail'] as String?;
      }
      return ApiFailure(
        message: msg ?? e.message ?? 'Server xatosi',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return ApiFailure(message: 'Kutilmagan xatolik: ${e.toString()}');
    }
  }

  @override
  Future<ApiResult<List<LoadEventModel>>> getLoadEvents(String id) async {
    try {
      final response = await _dioClient.get('/loads/$id/events');
      if (response.statusCode == 200 && response.data != null) {
        final list = (response.data['data'] as List<dynamic>?)
                ?.map((e) => LoadEventModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [];
        return ApiSuccess(list);
      }
      return const ApiFailure(message: 'Yuk hodisalarini olishda xatolik yuz berdi.');
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
