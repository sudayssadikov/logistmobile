import 'package:equatable/equatable.dart';
import '../../domain/models/truck_model.dart';

abstract class FleetEvent extends Equatable {
  const FleetEvent();
  @override
  List<Object?> get props => [];
}

class LoadFleetRequested extends FleetEvent {}

class AddTruckSubmitted extends FleetEvent {
  final TruckModel truck;
  const AddTruckSubmitted(this.truck);
  @override
  List<Object?> get props => [truck];
}

class AssignDriverSubmitted extends FleetEvent {
  final String truckId;
  final String driverId;
  const AssignDriverSubmitted({required this.truckId, required this.driverId});
  @override
  List<Object?> get props => [truckId, driverId];
}

class UnassignDriverSubmitted extends FleetEvent {
  final String truckId;
  const UnassignDriverSubmitted(this.truckId);
  @override
  List<Object?> get props => [truckId];
}
