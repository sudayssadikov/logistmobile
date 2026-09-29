import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/pod_repository.dart';
import 'pod_event.dart';
import 'pod_state.dart';

class PodBloc extends Bloc<PodEvent, PodState> {
  final IPodRepository _podRepository;

  PodBloc(this._podRepository) : super(const PodState()) {
    on<SubmitPodRequested>(_onSubmitPodRequested);
    on<FetchPodDetailsRequested>(_onFetchPodDetailsRequested);
  }

  Future<void> _onSubmitPodRequested(
    SubmitPodRequested event,
    Emitter<PodState> emit,
  ) async {
    emit(state.copyWith(status: PodStatus.loading));
    final result = await _podRepository.submitPod(event.submission);
    result.when(
      success: (data) {
        emit(state.copyWith(
          status: PodStatus.success,
          podData: data,
        ));
      },
      failure: (message, code, data) {
        emit(state.copyWith(
          status: PodStatus.error,
          errorMessage: message,
        ));
      },
    );
  }

  Future<void> _onFetchPodDetailsRequested(
    FetchPodDetailsRequested event,
    Emitter<PodState> emit,
  ) async {
    emit(state.copyWith(status: PodStatus.loading));
    final result = await _podRepository.getPodDetails(event.shipmentId);
    result.when(
      success: (data) {
        emit(state.copyWith(
          status: PodStatus.success,
          podData: data,
        ));
      },
      failure: (message, code, data) {
        emit(state.copyWith(
          status: PodStatus.error,
          errorMessage: message,
        ));
      },
    );
  }
}
