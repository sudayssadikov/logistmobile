import 'package:equatable/equatable.dart';
import '../../../shipments/domain/models/shipment_model.dart';

abstract class NavigationEvent extends Equatable {
  const NavigationEvent();
  @override
  List<Object?> get props => [];
}

class StartNavigation extends NavigationEvent {
  final ShipmentModel shipment;

  const StartNavigation(this.shipment);

  @override
  List<Object?> get props => [shipment];
}

class ToggleVoiceGuidance extends NavigationEvent {
  final bool enabled;

  const ToggleVoiceGuidance(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

class AdvanceRouteStep extends NavigationEvent {}

class EndNavigation extends NavigationEvent {}
