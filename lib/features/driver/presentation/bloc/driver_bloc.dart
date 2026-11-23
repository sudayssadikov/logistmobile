import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_result.dart';
import '../../domain/repositories/driver_repository.dart';
import 'driver_event.dart';
import 'driver_state.dart';

class DriverBloc extends Bloc<DriverEvent, DriverState> {
  final IDriverRepository _repository;

  DriverBloc(this._repository) : super(const DriverState()) {
    on<DriverFeedRequested>(_onFeedRequested);
    on<DriverFilterChanged>(_onFilterChanged);
    on<DriverSearchChanged>(_onSearchChanged);
    on<DriverSortChanged>(_onSortChanged);
    on<DriverVehiclesLoadRequested>(_onVehiclesLoadRequested);
    on<DriverVehicleAddRequested>(_onVehicleAddRequested);
  }

  Future<void> _onFeedRequested(
    DriverFeedRequested event,
    Emitter<DriverState> emit,
  ) async {
    emit(state.copyWith(status: DriverStatus.loading));
    final result = await _repository.getFeed(
      filter: state.filter,
      searchQuery: state.searchQuery,
    );
    if (result is ApiSuccess) {
      final data = (result as ApiSuccess).data;
      emit(
        state.copyWith(
          status: DriverStatus.success,
          feedItems: data.items,
          hasVehicle: data.hasVehicle,
          errorMessage: null,
        ),
      );
    } else {
      emit(
        state.copyWith(
          status: DriverStatus.failure,
          errorMessage: (result as ApiFailure).message,
        ),
      );
    }
  }

  Future<void> _onFilterChanged(
    DriverFilterChanged event,
    Emitter<DriverState> emit,
  ) async {
    emit(state.copyWith(filter: event.filter));
    add(const DriverFeedRequested());
  }

  Future<void> _onSearchChanged(
    DriverSearchChanged event,
    Emitter<DriverState> emit,
  ) async {
    emit(state.copyWith(searchQuery: event.query));
    add(const DriverFeedRequested());
  }

  Future<void> _onSortChanged(
    DriverSortChanged event,
    Emitter<DriverState> emit,
  ) async {
    final updatedFilter = state.filter.copyWith(sort: event.sort);
    emit(state.copyWith(filter: updatedFilter));
    add(const DriverFeedRequested());
  }

  Future<void> _onVehiclesLoadRequested(
    DriverVehiclesLoadRequested event,
    Emitter<DriverState> emit,
  ) async {
    final result = await _repository.getVehicles();
    if (result is ApiSuccess) {
      final list = (result as ApiSuccess).data;
      emit(state.copyWith(vehicles: list, hasVehicle: list.isNotEmpty));
    }
  }

  Future<void> _onVehicleAddRequested(
    DriverVehicleAddRequested event,
    Emitter<DriverState> emit,
  ) async {
    emit(state.copyWith(status: DriverStatus.loading));
    final result = await _repository.addVehicle(
      truckType: event.truckType,
      capacityTons: event.capacityTons,
      plateNumber: event.plateNumber,
      isPrimary: event.isPrimary,
    );
    if (result is ApiSuccess) {
      // Reload vehicles and feed
      add(const DriverVehiclesLoadRequested());
      add(const DriverFeedRequested());
    } else {
      emit(
        state.copyWith(
          status: DriverStatus.failure,
          errorMessage: (result as ApiFailure).message,
        ),
      );
    }
  }
}

