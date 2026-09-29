import 'package:equatable/equatable.dart';
import '../../domain/models/load_status.dart';
import '../../domain/models/shipment_model.dart';

enum ShipmentStateStatus { initial, loading, success, actionSuccess, error }

class ShipmentState extends Equatable {
  final ShipmentStateStatus status;
  final List<ShipmentModel> shipments;
  final ShipmentModel? selectedShipment;
  final LoadStatus? activeFilter;
  final String? searchQuery;
  final String? errorMessage;
  final String? successMessage;

  const ShipmentState({
    this.status = ShipmentStateStatus.initial,
    this.shipments = const [],
    this.selectedShipment,
    this.activeFilter,
    this.searchQuery,
    this.errorMessage,
    this.successMessage,
  });

  ShipmentState copyWith({
    ShipmentStateStatus? status,
    List<ShipmentModel>? shipments,
    ShipmentModel? selectedShipment,
    LoadStatus? activeFilter,
    String? searchQuery,
    String? errorMessage,
    String? successMessage,
  }) {
    return ShipmentState(
      status: status ?? this.status,
      shipments: shipments ?? this.shipments,
      selectedShipment: selectedShipment ?? this.selectedShipment,
      activeFilter: activeFilter ?? this.activeFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        shipments,
        selectedShipment,
        activeFilter,
        searchQuery,
        errorMessage,
        successMessage,
      ];
}
