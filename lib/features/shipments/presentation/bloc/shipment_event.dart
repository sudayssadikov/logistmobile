import 'package:equatable/equatable.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../domain/models/load_status.dart';
import '../../domain/models/shipment_model.dart';

abstract class ShipmentEvent extends Equatable {
  const ShipmentEvent();

  @override
  List<Object?> get props => [];
}

class LoadShipmentsRequested extends ShipmentEvent {
  final UserRole? role;
  final String? searchQuery;
  final LoadStatus? filterStatus;

  const LoadShipmentsRequested({this.role, this.searchQuery, this.filterStatus});

  @override
  List<Object?> get props => [role, searchQuery, filterStatus];
}

class ShipmentDetailRequested extends ShipmentEvent {
  final String id;

  const ShipmentDetailRequested(this.id);

  @override
  List<Object?> get props => [id];
}

class CreateShipmentSubmitted extends ShipmentEvent {
  final ShipmentModel shipment;

  const CreateShipmentSubmitted(this.shipment);

  @override
  List<Object?> get props => [shipment];
}

class AdvanceShipmentStatusSubmitted extends ShipmentEvent {
  final String shipmentId;
  final LoadStatus nextStatus;
  final UserRole currentRole;

  const AdvanceShipmentStatusSubmitted({
    required this.shipmentId,
    required this.nextStatus,
    required this.currentRole,
  });

  @override
  List<Object?> get props => [shipmentId, nextStatus, currentRole];
}

class SubmitBidSubmitted extends ShipmentEvent {
  final String shipmentId;
  final BidModel bid;

  const SubmitBidSubmitted({
    required this.shipmentId,
    required this.bid,
  });

  @override
  List<Object?> get props => [shipmentId, bid];
}

class AcceptBidSubmitted extends ShipmentEvent {
  final String shipmentId;
  final String bidId;

  const AcceptBidSubmitted({
    required this.shipmentId,
    required this.bidId,
  });

  @override
  List<Object?> get props => [shipmentId, bidId];
}

class FundEscrowSubmitted extends ShipmentEvent {
  final String shipmentId;

  const FundEscrowSubmitted(this.shipmentId);

  @override
  List<Object?> get props => [shipmentId];
}
