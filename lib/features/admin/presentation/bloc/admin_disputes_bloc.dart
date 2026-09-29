import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/admin_dispute_model.dart';
import '../../domain/repositories/admin_repository.dart';

abstract class AdminDisputesEvent extends Equatable {
  const AdminDisputesEvent();
  @override
  List<Object?> get props => [];
}

class FetchDisputesEvent extends AdminDisputesEvent {}

class SettleDisputeEvent extends AdminDisputesEvent {
  final String disputeId;
  final DisputeVerdict verdict;
  final String? notes;

  const SettleDisputeEvent({
    required this.disputeId,
    required this.verdict,
    this.notes,
  });

  @override
  List<Object?> get props => [disputeId, verdict, notes];
}

class AdminDisputesState extends Equatable {
  final bool isLoading;
  final List<AdminDisputeCaseModel> disputes;
  final String? successMessage;
  final String? errorMessage;

  const AdminDisputesState({
    this.isLoading = false,
    this.disputes = const [],
    this.successMessage,
    this.errorMessage,
  });

  AdminDisputesState copyWith({
    bool? isLoading,
    List<AdminDisputeCaseModel>? disputes,
    String? successMessage,
    String? errorMessage,
  }) {
    return AdminDisputesState(
      isLoading: isLoading ?? this.isLoading,
      disputes: disputes ?? this.disputes,
      successMessage: successMessage,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [isLoading, disputes, successMessage, errorMessage];
}

class AdminDisputesBloc extends Bloc<AdminDisputesEvent, AdminDisputesState> {
  final IAdminRepository _repository;

  AdminDisputesBloc({required IAdminRepository repository})
      : _repository = repository,
        super(const AdminDisputesState()) {
    on<FetchDisputesEvent>(_onFetchDisputes);
    on<SettleDisputeEvent>(_onSettleDispute);
  }

  Future<void> _onFetchDisputes(
    FetchDisputesEvent event,
    Emitter<AdminDisputesState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    final res = await _repository.getDisputes();
    emit(state.copyWith(
      isLoading: false,
      disputes: res.dataOrNull ?? [],
    ));
  }

  Future<void> _onSettleDispute(
    SettleDisputeEvent event,
    Emitter<AdminDisputesState> emit,
  ) async {
    final res = await _repository.resolveDispute(
      event.disputeId,
      event.verdict,
      reason: event.notes,
    );

    if (res.isSuccess) {
      add(FetchDisputesEvent());
      emit(state.copyWith(successMessage: 'Nizo bo\'yicha yakuniy arbitraj qarori ijro etildi!'));
    }
  }
}
