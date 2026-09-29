import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/fleet_repository.dart';
import 'fleet_event.dart';
import 'fleet_state.dart';

class FleetBloc extends Bloc<FleetEvent, FleetState> {
  final IFleetRepository _repository;

  FleetBloc({required IFleetRepository repository})
      : _repository = repository,
        super(const FleetState()) {
    on<LoadFleetRequested>(_onLoadFleet);
    on<AddTruckSubmitted>(_onAddTruck);
    on<AssignDriverSubmitted>(_onAssignDriver);
    on<UnassignDriverSubmitted>(_onUnassignDriver);
  }

  Future<void> _onLoadFleet(
    LoadFleetRequested event,
    Emitter<FleetState> emit,
  ) async {
    emit(state.copyWith(status: FleetStateStatus.loading));
    try {
      final trucks = await _repository.getTrucks();
      final drivers = await _repository.getDrivers();
      emit(state.copyWith(
        status: FleetStateStatus.success,
        trucks: trucks,
        drivers: drivers,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: FleetStateStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onAddTruck(
    AddTruckSubmitted event,
    Emitter<FleetState> emit,
  ) async {
    emit(state.copyWith(status: FleetStateStatus.loading));
    try {
      final added = await _repository.addTruck(event.truck);
      final updated = List.of(state.trucks)..insert(0, added);
      emit(state.copyWith(
        status: FleetStateStatus.success,
        trucks: updated,
        successMessage: 'Truck added successfully to inventory',
      ));
    } catch (e) {
      emit(state.copyWith(
        status: FleetStateStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onAssignDriver(
    AssignDriverSubmitted event,
    Emitter<FleetState> emit,
  ) async {
    emit(state.copyWith(status: FleetStateStatus.loading));
    try {
      await _repository.assignDriver(truckId: event.truckId, driverId: event.driverId);
      final trucks = await _repository.getTrucks();
      final drivers = await _repository.getDrivers();
      emit(state.copyWith(
        status: FleetStateStatus.success,
        trucks: trucks,
        drivers: drivers,
        successMessage: 'Driver assigned successfully',
      ));
    } catch (e) {
      emit(state.copyWith(
        status: FleetStateStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onUnassignDriver(
    UnassignDriverSubmitted event,
    Emitter<FleetState> emit,
  ) async {
    emit(state.copyWith(status: FleetStateStatus.loading));
    try {
      await _repository.unassignDriver(event.truckId);
      final trucks = await _repository.getTrucks();
      final drivers = await _repository.getDrivers();
      emit(state.copyWith(
        status: FleetStateStatus.success,
        trucks: trucks,
        drivers: drivers,
        successMessage: 'Driver unassigned',
      ));
    } catch (e) {
      emit(state.copyWith(
        status: FleetStateStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }
}
