import '../../../../core/network/api_result.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../domain/models/load_status.dart';
import '../../domain/models/shipment_model.dart';
import '../../domain/repositories/shipment_repository.dart';

class ShipmentRepositoryImpl implements IShipmentRepository {
  final DioClient? _dioClient;
  final List<ShipmentModel> _shipments = [];

  ShipmentRepositoryImpl([this._dioClient]);

  @override
  Future<ApiResult<List<ShipmentModel>>> getShipments({
    UserRole? role,
    String? searchQuery,
    LoadStatus? filterStatus,
  }) async {
    if (_dioClient == null) {
      return const ApiFailure(message: 'Server bilan aloqa mavjud emas');
    }
    try {
      final queryParams = <String, dynamic>{};
      if (filterStatus != null) queryParams['status'] = filterStatus.name;
      if (searchQuery != null && searchQuery.isNotEmpty) queryParams['search'] = searchQuery;

      final response = await _dioClient!.get('/shipments', queryParameters: queryParams);
      if (response.statusCode == 200 && response.data != null) {
        final List rawList = response.data['data'] ?? [];
        final items = rawList.map((e) => ShipmentModel.fromJson(e as Map<String, dynamic>)).toList();
        _shipments.clear();
        _shipments.addAll(items);
        return ApiSuccess(items);
      }
      return ApiFailure(message: response.data?['message'] ?? 'Yuklar ro\'yxatini yuklab bo\'lmadi');
    } catch (e) {
      return ApiFailure(message: 'Serverga ulanishda xatolik: ${e.toString()}');
    }
  }

  @override
  Future<ApiResult<ShipmentModel>> getShipmentById(String id) async {
    if (_dioClient == null) {
      return const ApiFailure(message: 'Server bilan aloqa mavjud emas');
    }
    try {
      final response = await _dioClient!.get('/shipments/$id');
      if (response.statusCode == 200 && response.data != null) {
        final item = ShipmentModel.fromJson(response.data['data']);
        return ApiSuccess(item);
      }
      return ApiFailure(message: response.data?['message'] ?? 'Yuk ma\'lumotlarini yuklab bo\'lmadi');
    } catch (e) {
      return ApiFailure(message: 'Serverga ulanishda xatolik: ${e.toString()}');
    }
  }

  @override
  Future<ApiResult<ShipmentModel>> createShipment(ShipmentModel shipment) async {
    if (_dioClient == null) {
      return const ApiFailure(message: 'Server bilan aloqa mavjud emas');
    }
    try {
      final response = await _dioClient!.post('/shipments', data: shipment.toJson());
      if ((response.statusCode == 200 || response.statusCode == 201) && response.data != null) {
        final created = ShipmentModel.fromJson(response.data['data']);
        _shipments.insert(0, created);
        return ApiSuccess(created);
      }
      return ApiFailure(message: response.data?['message'] ?? 'Yukni e\'lon qilib bo\'lmadi');
    } catch (e) {
      return ApiFailure(message: 'Yuk yaratishda xatolik: ${e.toString()}');
    }
  }

  @override
  Future<ApiResult<ShipmentModel>> advanceStatus({
    required String shipmentId,
    required LoadStatus nextStatus,
    required UserRole currentRole,
  }) async {
    if (_dioClient == null) {
      return const ApiFailure(message: 'Server bilan aloqa mavjud emas');
    }
    try {
      final response = await _dioClient!.patch(
        '/shipments/$shipmentId/status',
        data: {'status': nextStatus.name},
      );
      if (response.statusCode == 200 && response.data != null) {
        final updated = ShipmentModel.fromJson(response.data['data']);
        final index = _shipments.indexWhere((e) => e.id == shipmentId);
        if (index != -1) _shipments[index] = updated;
        return ApiSuccess(updated);
      }
      return ApiFailure(message: response.data?['message'] ?? 'Holatni yangilab bo\'lmadi');
    } catch (e) {
      return ApiFailure(message: 'Xatolik: ${e.toString()}');
    }
  }

  @override
  Future<ApiResult<ShipmentModel>> submitBid({
    required String shipmentId,
    required BidModel bid,
  }) async {
    if (_dioClient == null) {
      return const ApiFailure(message: 'Server bilan aloqa mavjud emas');
    }
    try {
      final response = await _dioClient!.post(
        '/shipments/$shipmentId/bids',
        data: bid.toJson(),
      );
      if (response.statusCode == 200 && response.data != null) {
        final updated = ShipmentModel.fromJson(response.data['data']);
        return ApiSuccess(updated);
      }
      return ApiFailure(message: response.data?['message'] ?? 'Taklifni yuborib bo\'lmadi');
    } catch (e) {
      return ApiFailure(message: 'Taklif yuborishda xatolik: ${e.toString()}');
    }
  }

  @override
  Future<ApiResult<ShipmentModel>> acceptBid({
    required String shipmentId,
    required String bidId,
  }) async {
    if (_dioClient == null) {
      return const ApiFailure(message: 'Server bilan aloqa mavjud emas');
    }
    try {
      final response = await _dioClient!.post('/shipments/$shipmentId/bids/$bidId/accept');
      if (response.statusCode == 200 && response.data != null) {
        final updated = ShipmentModel.fromJson(response.data['data']);
        final index = _shipments.indexWhere((e) => e.id == shipmentId);
        if (index != -1) _shipments[index] = updated;
        return ApiSuccess(updated);
      }
      return ApiFailure(message: response.data?['message'] ?? 'Taklifni qabul qilib bo\'lmadi');
    } catch (e) {
      return ApiFailure(message: 'Taklifni qabul qilishda xatolik: ${e.toString()}');
    }
  }

  @override
  Future<ApiResult<ShipmentModel>> fundEscrow(String shipmentId) async {
    if (_dioClient == null) {
      return const ApiFailure(message: 'Server bilan aloqa mavjud emas');
    }
    try {
      final response = await _dioClient!.post(
        '/escrow/fund',
        data: {
          'shipmentId': shipmentId,
          'idempotencyKey': 'escrow_${DateTime.now().millisecondsSinceEpoch}',
        },
      );
      if (response.statusCode == 200) {
        return await advanceStatus(
          shipmentId: shipmentId,
          nextStatus: LoadStatus.escrowFunded,
          currentRole: UserRole.shipper,
        );
      }
      return ApiFailure(message: response.data?['message'] ?? 'Eskrou mablag\'ini muzlatib bo\'lmadi');
    } catch (e) {
      return ApiFailure(message: 'Eskrou to\'lovida xatolik: ${e.toString()}');
    }
  }
}
