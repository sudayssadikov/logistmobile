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
    if (_dioClient != null) {
      try {
        final queryParams = <String, dynamic>{};
        if (filterStatus != null) queryParams['status'] = filterStatus.name;
        if (searchQuery != null && searchQuery.isNotEmpty) queryParams['search'] = searchQuery;

        final response = await _dioClient!.get('/shipments', queryParameters: queryParams);
        if (response.statusCode == 200 && response.data != null) {
          final List rawList = response.data['data'] ?? [];
          final items = rawList.map((e) => ShipmentModel.fromJson(e)).toList();
          if (items.isNotEmpty) {
            _shipments.clear();
            _shipments.addAll(items);
            return ApiSuccess(items);
          }
        }
      } catch (_) {
        // Fallback to local memory
      }
    }

    await Future.delayed(const Duration(milliseconds: 150));
    var list = List<ShipmentModel>.from(_shipments);

    if (filterStatus != null) {
      list = list.where((e) => e.status == filterStatus).toList();
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      list = list.where((e) {
        return e.trackingCode.toLowerCase().contains(q) ||
            e.cargoTitle.toLowerCase().contains(q) ||
            e.origin.city.toLowerCase().contains(q) ||
            e.destination.city.toLowerCase().contains(q);
      }).toList();
    }

    return ApiSuccess(list);
  }

  @override
  Future<ApiResult<ShipmentModel>> getShipmentById(String id) async {
    if (_dioClient != null) {
      try {
        final response = await _dioClient!.get('/shipments/$id');
        if (response.statusCode == 200 && response.data != null) {
          final item = ShipmentModel.fromJson(response.data['data']);
          return ApiSuccess(item);
        }
      } catch (_) {
        // Fallback
      }
    }

    await Future.delayed(const Duration(milliseconds: 100));
    try {
      final item = _shipments.firstWhere((e) => e.id == id);
      return ApiSuccess(item);
    } catch (_) {
      return const ApiFailure(message: 'Shipment not found.');
    }
  }

  @override
  Future<ApiResult<ShipmentModel>> createShipment(ShipmentModel shipment) async {
    if (_dioClient != null) {
      try {
        final response = await _dioClient!.post('/shipments', data: shipment.toJson());
        if (response.statusCode == 200 && response.data != null) {
          final created = ShipmentModel.fromJson(response.data['data']);
          _shipments.insert(0, created);
          return ApiSuccess(created);
        }
      } catch (_) {
        // Fallback
      }
    }

    await Future.delayed(const Duration(milliseconds: 200));
    _shipments.insert(0, shipment);
    return ApiSuccess(shipment);
  }

  @override
  Future<ApiResult<ShipmentModel>> advanceStatus({
    required String shipmentId,
    required LoadStatus nextStatus,
    required UserRole currentRole,
  }) async {
    if (_dioClient != null) {
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
      } catch (_) {
        // Fallback
      }
    }

    await Future.delayed(const Duration(milliseconds: 200));
    final index = _shipments.indexWhere((e) => e.id == shipmentId);
    if (index == -1) {
      return const ApiFailure(message: 'Shipment not found.');
    }

    final current = _shipments[index];
    final updated = current.copyWith(
      status: nextStatus,
      isEscrowFunded: nextStatus.index >= LoadStatus.escrowFunded.index ? true : current.isEscrowFunded,
    );
    _shipments[index] = updated;
    return ApiSuccess(updated);
  }

  @override
  Future<ApiResult<ShipmentModel>> submitBid({
    required String shipmentId,
    required BidModel bid,
  }) async {
    if (_dioClient != null) {
      try {
        final response = await _dioClient!.post(
          '/shipments/$shipmentId/bids',
          data: bid.toJson(),
        );
        if (response.statusCode == 200 && response.data != null) {
          final updated = ShipmentModel.fromJson(response.data['data']);
          return ApiSuccess(updated);
        }
      } catch (_) {
        // Fallback
      }
    }

    await Future.delayed(const Duration(milliseconds: 200));
    final index = _shipments.indexWhere((e) => e.id == shipmentId);
    if (index == -1) {
      return const ApiFailure(message: 'Shipment not found.');
    }

    final current = _shipments[index];
    final updatedBids = List<BidModel>.from(current.bids)..add(bid);
    final updated = current.copyWith(bids: updatedBids);
    _shipments[index] = updated;
    return ApiSuccess(updated);
  }

  @override
  Future<ApiResult<ShipmentModel>> acceptBid({
    required String shipmentId,
    required String bidId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _shipments.indexWhere((e) => e.id == shipmentId);
    if (index == -1) {
      return const ApiFailure(message: 'Shipment not found.');
    }

    final current = _shipments[index];
    final bid = current.bids.firstWhere((b) => b.id == bidId, orElse: () => current.bids.first);

    final updated = current.copyWith(
      carrierId: bid.carrierId,
      carrierName: bid.carrierName,
      driverName: bid.driverName,
      vehiclePlate: '${bid.plateNumber} (${bid.vehicleModel})',
      price: bid.bidAmount,
      status: LoadStatus.carrierAssigned,
    );
    _shipments[index] = updated;
    return ApiSuccess(updated);
  }

  @override
  Future<ApiResult<ShipmentModel>> fundEscrow(String shipmentId) async {
    return advanceStatus(
      shipmentId: shipmentId,
      nextStatus: LoadStatus.escrowFunded,
      currentRole: UserRole.shipper,
    );
  }
}
