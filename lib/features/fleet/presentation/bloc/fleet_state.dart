import 'package:equatable/equatable.dart';
import '../../domain/models/truck_model.dart';
import '../../domain/models/driver_model.dart';

enum FleetStateStatus { initial, loading, success, failure }

class FleetState extends Equatable {
  final FleetStateStatus status;
  final List<TruckModel> trucks;
  final List<DriverModel> drivers;
  final String? successMessage;
  final String? errorMessage;

  const FleetState({
    this.status = FleetStateStatus.initial,
    this.trucks = const [],
    this.drivers = const [],
    this.successMessage,
    this.errorMessage,
  });

  FleetState copyWith({
    FleetStateStatus? status,
    List<TruckModel>? trucks,
    List<DriverModel>? drivers,
    String? successMessage,
    String? errorMessage,
  }) {
    return FleetState(
      status: status ?? this.status,
      trucks: trucks ?? this.trucks,
      drivers: drivers ?? this.drivers,
      successMessage: successMessage,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, trucks, drivers, successMessage, errorMessage];
}
