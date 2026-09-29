import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/escrow_ledger_item_model.dart';
import '../../domain/repositories/admin_repository.dart';

abstract class AdminFinanceEvent extends Equatable {
  const AdminFinanceEvent();
  @override
  List<Object?> get props => [];
}

class FetchEscrowLedgerEvent extends AdminFinanceEvent {}

class ExecuteEscrowInterventionEvent extends AdminFinanceEvent {
  final String escrowId;
  final EscrowInterventionAction action;

  const ExecuteEscrowInterventionEvent({
    required this.escrowId,
    required this.action,
  });

  @override
  List<Object?> get props => [escrowId, action];
}

class AdminFinanceState extends Equatable {
  final bool isLoading;
  final List<EscrowLedgerItemModel> ledgerItems;
  final double commissionRate;
  final String? successMessage;
  final String? errorMessage;

  const AdminFinanceState({
    this.isLoading = false,
    this.ledgerItems = const [],
    this.commissionRate = 1.5,
    this.successMessage,
    this.errorMessage,
  });

  AdminFinanceState copyWith({
    bool? isLoading,
    List<EscrowLedgerItemModel>? ledgerItems,
    double? commissionRate,
    String? successMessage,
    String? errorMessage,
  }) {
    return AdminFinanceState(
      isLoading: isLoading ?? this.isLoading,
      ledgerItems: ledgerItems ?? this.ledgerItems,
      commissionRate: commissionRate ?? this.commissionRate,
      successMessage: successMessage,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        ledgerItems,
        commissionRate,
        successMessage,
        errorMessage,
      ];
}

class AdminFinanceBloc extends Bloc<AdminFinanceEvent, AdminFinanceState> {
  final IAdminRepository _repository;

  AdminFinanceBloc({required IAdminRepository repository})
      : _repository = repository,
        super(const AdminFinanceState()) {
    on<FetchEscrowLedgerEvent>(_onFetchLedger);
    on<ExecuteEscrowInterventionEvent>(_onExecuteIntervention);
  }

  Future<void> _onFetchLedger(
    FetchEscrowLedgerEvent event,
    Emitter<AdminFinanceState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    final res = await _repository.getEscrowLedger();
    emit(state.copyWith(
      isLoading: false,
      ledgerItems: res.dataOrNull ?? [],
    ));
  }

  Future<void> _onExecuteIntervention(
    ExecuteEscrowInterventionEvent event,
    Emitter<AdminFinanceState> emit,
  ) async {
    final res = await _repository.executeEscrowIntervention(event.escrowId, event.action);
    if (res.isSuccess) {
      add(FetchEscrowLedgerEvent());
      emit(state.copyWith(successMessage: 'Eskrou aralashuvi muvaffaqiyatli bajarildi: ${event.action.label}'));
    }
  }
}
