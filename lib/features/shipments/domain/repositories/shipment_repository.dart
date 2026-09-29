import '../../../../core/network/api_result.dart';
import '../../../auth/domain/models/user_model.dart';
import '../models/load_status.dart';
import '../models/shipment_model.dart';

abstract class IShipmentRepository {
  Future<ApiResult<List<ShipmentModel>>> getShipments({
    UserRole? role,
    String? searchQuery,
    LoadStatus? filterStatus,
  });

  Future<ApiResult<ShipmentModel>> getShipmentById(String id);

  Future<ApiResult<ShipmentModel>> createShipment(ShipmentModel shipment);

  Future<ApiResult<ShipmentModel>> advanceStatus({
    required String shipmentId,
    required LoadStatus nextStatus,
    required UserRole currentRole,
  });

  Future<ApiResult<ShipmentModel>> submitBid({
    required String shipmentId,
    required BidModel bid,
  });

  Future<ApiResult<ShipmentModel>> acceptBid({
    required String shipmentId,
    required String bidId,
  });

  Future<ApiResult<ShipmentModel>> fundEscrow(String shipmentId);
}
