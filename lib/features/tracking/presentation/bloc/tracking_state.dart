import 'package:equatable/equatable.dart';
import '../../domain/models/tracking_data_model.dart';

enum TrackingStatus { initial, loading, active, stopped, error }

class TrackingState extends Equatable {
  final TrackingStatus status;
  final TrackingDataModel? trackingData;
  final String? errorMessage;

  const TrackingState({
    this.status = TrackingStatus.initial,
    this.trackingData,
    this.errorMessage,
  });

  TrackingState copyWith({
    TrackingStatus? status,
    TrackingDataModel? trackingData,
    String? errorMessage,
  }) {
    return TrackingState(
      status: status ?? this.status,
      trackingData: trackingData ?? this.trackingData,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, trackingData, errorMessage];
}
