import 'package:equatable/equatable.dart';
import '../../domain/models/tracking_data_model.dart';

abstract class TrackingEvent extends Equatable {
  const TrackingEvent();
  @override
  List<Object?> get props => [];
}

class StartTrackingSessionRequested extends TrackingEvent {
  final String shipmentId;
  const StartTrackingSessionRequested(this.shipmentId);
  @override
  List<Object?> get props => [shipmentId];
}

class TelemetryUpdated extends TrackingEvent {
  final TelemetryUpdate update;
  const TelemetryUpdated(this.update);
  @override
  List<Object?> get props => [update];
}

class StopTrackingSessionRequested extends TrackingEvent {}
