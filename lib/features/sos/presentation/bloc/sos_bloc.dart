import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_result.dart';
import '../../domain/models/sos_model.dart';
import '../../domain/repositories/sos_repository.dart';
import 'sos_event.dart';
import 'sos_state.dart';

class SosBloc extends Bloc<SosEvent, SosState> {
  final ISosRepository _repository;

  SosBloc({required ISosRepository repository})
      : _repository = repository,
        super(const SosState()) {
    on<FetchNearbySosProvidersRequested>(_onFetchNearbySosProvidersRequested);
    on<ChangeSosFilterType>(_onChangeSosFilterType);
    on<DispatchEmergencyAlertRequested>(_onDispatchEmergencyAlertRequested);
  }

  Future<void> _onFetchNearbySosProvidersRequested(
    FetchNearbySosProvidersRequested event,
    Emitter<SosState> emit,
  ) async {
    emit(state.copyWith(
      status: SosStatus.loading,
      currentLatitude: event.latitude,
      currentLongitude: event.longitude,
      activeFilter: event.filterType,
    ));

    final result = await _repository.getNearbySosProviders(
      latitude: event.latitude,
      longitude: event.longitude,
      filterType: event.filterType,
    );

    if (result is ApiSuccess<List<NearbySosProvider>>) {
      emit(state.copyWith(
        status: SosStatus.success,
        providers: result.data,
      ));
    } else if (result is ApiFailure<List<NearbySosProvider>>) {
      emit(state.copyWith(
        status: SosStatus.error,
        errorMessage: result.message,
      ));
    }
  }

  Future<void> _onChangeSosFilterType(
    ChangeSosFilterType event,
    Emitter<SosState> emit,
  ) async {
    emit(state.copyWith(
      activeFilter: event.filterType,
      clearFilter: event.filterType == null,
    ));
    add(FetchNearbySosProvidersRequested(
      latitude: state.currentLatitude,
      longitude: state.currentLongitude,
      filterType: event.filterType,
    ));
  }

  Future<void> _onDispatchEmergencyAlertRequested(
    DispatchEmergencyAlertRequested event,
    Emitter<SosState> emit,
  ) async {
    emit(state.copyWith(status: SosStatus.loading));
    final result = await _repository.dispatchEmergencyAlert(
      latitude: event.latitude,
      longitude: event.longitude,
      type: event.type,
      driverPhone: event.driverPhone,
      notes: event.notes,
    );

    if (result is ApiSuccess<bool>) {
      emit(state.copyWith(status: SosStatus.dispatched));
    } else if (result is ApiFailure<bool>) {
      emit(state.copyWith(
        status: SosStatus.error,
        errorMessage: result.message,
      ));
    }
  }
}
