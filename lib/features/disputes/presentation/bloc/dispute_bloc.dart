import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/dispute_repository.dart';
import 'dispute_event.dart';
import 'dispute_state.dart';

class DisputeBloc extends Bloc<DisputeEvent, DisputeState> {
  final IDisputeRepository _repository;

  DisputeBloc({required IDisputeRepository repository})
      : _repository = repository,
        super(const DisputeState()) {
    on<LoadDisputesRequested>(_onLoadDisputes);
    on<LoadDisputeDetailRequested>(_onLoadDisputeDetail);
    on<CreateDisputeSubmitted>(_onCreateDispute);
  }

  Future<void> _onLoadDisputes(
    LoadDisputesRequested event,
    Emitter<DisputeState> emit,
  ) async {
    emit(state.copyWith(status: DisputeStateStatus.loading));
    try {
      final list = await _repository.getDisputes();
      emit(state.copyWith(
        status: DisputeStateStatus.success,
        disputes: list,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: DisputeStateStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onLoadDisputeDetail(
    LoadDisputeDetailRequested event,
    Emitter<DisputeState> emit,
  ) async {
    emit(state.copyWith(status: DisputeStateStatus.loading));
    try {
      final dispute = await _repository.getDisputeById(event.disputeId);
      emit(state.copyWith(
        status: DisputeStateStatus.success,
        selectedDispute: dispute,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: DisputeStateStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onCreateDispute(
    CreateDisputeSubmitted event,
    Emitter<DisputeState> emit,
  ) async {
    emit(state.copyWith(status: DisputeStateStatus.loading));
    try {
      final created = await _repository.createDispute(
        shipmentId: event.shipmentId,
        trackingCode: event.trackingCode,
        claimantName: event.claimantName,
        reason: event.reason,
        description: event.description,
        claimAmount: event.claimAmount,
        evidencePhotos: event.evidencePhotos,
      );
      final updated = List.of(state.disputes)..insert(0, created);
      emit(state.copyWith(
        status: DisputeStateStatus.success,
        disputes: updated,
        selectedDispute: created,
        successMessage: 'Claim submitted for mediation',
      ));
    } catch (e) {
      emit(state.copyWith(
        status: DisputeStateStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }
}
