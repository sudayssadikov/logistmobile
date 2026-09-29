import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/admin_kpi_model.dart';
import '../../domain/models/audit_log_entry_model.dart';
import '../../domain/repositories/admin_repository.dart';

abstract class AdminDashboardEvent extends Equatable {
  const AdminDashboardEvent();
  @override
  List<Object?> get props => [];
}

class AdminFetchDashboardDataEvent extends AdminDashboardEvent {}

class AdminRefreshKpiEvent extends AdminDashboardEvent {}

class AdminDashboardState extends Equatable {
  final bool isLoading;
  final AdminKpiModel? kpis;
  final List<AuditLogEntryModel> recentAuditLogs;
  final String? errorMessage;

  const AdminDashboardState({
    this.isLoading = false,
    this.kpis,
    this.recentAuditLogs = const [],
    this.errorMessage,
  });

  AdminDashboardState copyWith({
    bool? isLoading,
    AdminKpiModel? kpis,
    List<AuditLogEntryModel>? recentAuditLogs,
    String? errorMessage,
  }) {
    return AdminDashboardState(
      isLoading: isLoading ?? this.isLoading,
      kpis: kpis ?? this.kpis,
      recentAuditLogs: recentAuditLogs ?? this.recentAuditLogs,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [isLoading, kpis, recentAuditLogs, errorMessage];
}

class AdminDashboardBloc extends Bloc<AdminDashboardEvent, AdminDashboardState> {
  final IAdminRepository _repository;

  AdminDashboardBloc({required IAdminRepository repository})
      : _repository = repository,
        super(const AdminDashboardState()) {
    on<AdminFetchDashboardDataEvent>(_onFetchData);
    on<AdminRefreshKpiEvent>(_onRefreshKpis);
  }

  Future<void> _onFetchData(
    AdminFetchDashboardDataEvent event,
    Emitter<AdminDashboardState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    final kpiResult = await _repository.getKpis();
    final logResult = await _repository.getAuditLogs();

    if (kpiResult.isSuccess) {
      emit(state.copyWith(
        isLoading: false,
        kpis: kpiResult.dataOrNull,
        recentAuditLogs: logResult.dataOrNull ?? [],
      ));
    } else {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: kpiResult.errorOrNull ?? 'Failed to load KPI metrics',
      ));
    }
  }

  Future<void> _onRefreshKpis(
    AdminRefreshKpiEvent event,
    Emitter<AdminDashboardState> emit,
  ) async {
    final kpiResult = await _repository.getKpis();
    final logResult = await _repository.getAuditLogs();

    if (kpiResult.isSuccess) {
      emit(state.copyWith(
        kpis: kpiResult.dataOrNull,
        recentAuditLogs: logResult.dataOrNull ?? state.recentAuditLogs,
      ));
    }
  }
}
