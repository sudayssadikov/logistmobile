import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/tracking_repository.dart';
import 'tracking_event.dart';
import 'tracking_state.dart';

class TrackingBloc extends Bloc<TrackingEvent, TrackingState> {
  final ITrackingRepository _trackingRepository;
  StreamSubscription? _telemetrySub;

  TrackingBloc(this._trackingRepository) : super(const TrackingState()) {
    on<StartTrackingSessionRequested>(_onStartTrackingSessionRequested);
    on<TelemetryUpdated>(_onTelemetryUpdated);
    on<StopTrackingSessionRequested>(_onStopTrackingSessionRequested);
  }

  Future<void> _onStartTrackingSessionRequested(
    StartTrackingSessionRequested event,
    Emitter<TrackingState> emit,
  ) async {
    emit(state.copyWith(status: TrackingStatus.loading));
    final result = await _trackingRepository.getTrackingSession(event.shipmentId);
    result.when(
      success: (data) {
        emit(state.copyWith(
          status: TrackingStatus.active,
          trackingData: data,
        ));

        _telemetrySub?.cancel();
        _telemetrySub = _trackingRepository
            .startTelemetrySimulation(event.shipmentId)
            .listen((update) {
          add(TelemetryUpdated(update));
        });
      },
      failure: (message, code, data) {
        emit(state.copyWith(
          status: TrackingStatus.error,
          errorMessage: message,
        ));
      },
    );
  }

  void _onTelemetryUpdated(
    TelemetryUpdated event,
    Emitter<TrackingState> emit,
  ) {
    if (state.trackingData != null) {
      final updated = state.trackingData!.copyWith(currentTelemetry: event.update);
      emit(state.copyWith(trackingData: updated));
    }
  }

  void _onStopTrackingSessionRequested(
    StopTrackingSessionRequested event,
    Emitter<TrackingState> emit,
  ) {
    _telemetrySub?.cancel();
    _telemetrySub = null;
    _trackingRepository.stopTelemetrySimulation();
    emit(state.copyWith(status: TrackingStatus.stopped));
  }

  @override
  Future<void> close() {
    _telemetrySub?.cancel();
    _trackingRepository.stopTelemetrySimulation();
    return super.close();
  }
}
