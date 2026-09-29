import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/shipment_repository.dart';
import 'shipment_event.dart';
import 'shipment_state.dart';

class ShipmentBloc extends Bloc<ShipmentEvent, ShipmentState> {
  final IShipmentRepository _shipmentRepository;

  ShipmentBloc(this._shipmentRepository) : super(const ShipmentState()) {
    on<LoadShipmentsRequested>(_onLoadShipmentsRequested);
    on<ShipmentDetailRequested>(_onShipmentDetailRequested);
    on<CreateShipmentSubmitted>(_onCreateShipmentSubmitted);
    on<AdvanceShipmentStatusSubmitted>(_onAdvanceShipmentStatusSubmitted);
    on<SubmitBidSubmitted>(_onSubmitBidSubmitted);
    on<AcceptBidSubmitted>(_onAcceptBidSubmitted);
    on<FundEscrowSubmitted>(_onFundEscrowSubmitted);
  }

  Future<void> _onLoadShipmentsRequested(
    LoadShipmentsRequested event,
    Emitter<ShipmentState> emit,
  ) async {
    emit(state.copyWith(
      status: ShipmentStateStatus.loading,
      activeFilter: event.filterStatus,
      searchQuery: event.searchQuery,
    ));

    final result = await _shipmentRepository.getShipments(
      role: event.role,
      searchQuery: event.searchQuery,
      filterStatus: event.filterStatus,
    );

    result.when(
      success: (data) {
        emit(state.copyWith(
          status: ShipmentStateStatus.success,
          shipments: data,
        ));
      },
      failure: (message, code, data) {
        emit(state.copyWith(
          status: ShipmentStateStatus.error,
          errorMessage: message,
        ));
      },
    );
  }

  Future<void> _onShipmentDetailRequested(
    ShipmentDetailRequested event,
    Emitter<ShipmentState> emit,
  ) async {
    emit(state.copyWith(status: ShipmentStateStatus.loading));
    final result = await _shipmentRepository.getShipmentById(event.id);
    result.when(
      success: (data) {
        emit(state.copyWith(
          status: ShipmentStateStatus.success,
          selectedShipment: data,
        ));
      },
      failure: (message, code, data) {
        emit(state.copyWith(
          status: ShipmentStateStatus.error,
          errorMessage: message,
        ));
      },
    );
  }

  Future<void> _onCreateShipmentSubmitted(
    CreateShipmentSubmitted event,
    Emitter<ShipmentState> emit,
  ) async {
    emit(state.copyWith(status: ShipmentStateStatus.loading));
    final result = await _shipmentRepository.createShipment(event.shipment);
    result.when(
      success: (created) {
        final list = List.of(state.shipments)..insert(0, created);
        emit(state.copyWith(
          status: ShipmentStateStatus.actionSuccess,
          shipments: list,
          selectedShipment: created,
          successMessage: 'Freight shipment created successfully!',
        ));
      },
      failure: (message, code, data) {
        emit(state.copyWith(
          status: ShipmentStateStatus.error,
          errorMessage: message,
        ));
      },
    );
  }

  Future<void> _onAdvanceShipmentStatusSubmitted(
    AdvanceShipmentStatusSubmitted event,
    Emitter<ShipmentState> emit,
  ) async {
    emit(state.copyWith(status: ShipmentStateStatus.loading));
    final result = await _shipmentRepository.advanceStatus(
      shipmentId: event.shipmentId,
      nextStatus: event.nextStatus,
      currentRole: event.currentRole,
    );
    result.when(
      success: (updated) {
        final list = state.shipments.map((e) => e.id == updated.id ? updated : e).toList();
        emit(state.copyWith(
          status: ShipmentStateStatus.actionSuccess,
          shipments: list,
          selectedShipment: updated,
          successMessage: 'Status progressed to ${updated.status.label}',
        ));
      },
      failure: (message, code, data) {
        emit(state.copyWith(
          status: ShipmentStateStatus.error,
          errorMessage: message,
        ));
      },
    );
  }

  Future<void> _onSubmitBidSubmitted(
    SubmitBidSubmitted event,
    Emitter<ShipmentState> emit,
  ) async {
    emit(state.copyWith(status: ShipmentStateStatus.loading));
    final result = await _shipmentRepository.submitBid(
      shipmentId: event.shipmentId,
      bid: event.bid,
    );
    result.when(
      success: (updated) {
        final list = state.shipments.map((e) => e.id == updated.id ? updated : e).toList();
        emit(state.copyWith(
          status: ShipmentStateStatus.actionSuccess,
          shipments: list,
          selectedShipment: updated,
          successMessage: 'Your bid was submitted successfully!',
        ));
      },
      failure: (message, code, data) {
        emit(state.copyWith(
          status: ShipmentStateStatus.error,
          errorMessage: message,
        ));
      },
    );
  }

  Future<void> _onAcceptBidSubmitted(
    AcceptBidSubmitted event,
    Emitter<ShipmentState> emit,
  ) async {
    emit(state.copyWith(status: ShipmentStateStatus.loading));
    final result = await _shipmentRepository.acceptBid(
      shipmentId: event.shipmentId,
      bidId: event.bidId,
    );
    result.when(
      success: (updated) {
        final list = state.shipments.map((e) => e.id == updated.id ? updated : e).toList();
        emit(state.copyWith(
          status: ShipmentStateStatus.actionSuccess,
          shipments: list,
          selectedShipment: updated,
          successMessage: 'Carrier assigned! Please fund escrow to dispatch driver.',
        ));
      },
      failure: (message, code, data) {
        emit(state.copyWith(
          status: ShipmentStateStatus.error,
          errorMessage: message,
        ));
      },
    );
  }

  Future<void> _onFundEscrowSubmitted(
    FundEscrowSubmitted event,
    Emitter<ShipmentState> emit,
  ) async {
    emit(state.copyWith(status: ShipmentStateStatus.loading));
    final result = await _shipmentRepository.fundEscrow(event.shipmentId);
    result.when(
      success: (updated) {
        final list = state.shipments.map((e) => e.id == updated.id ? updated : e).toList();
        emit(state.copyWith(
          status: ShipmentStateStatus.actionSuccess,
          shipments: list,
          selectedShipment: updated,
          successMessage: 'Escrow payment locked! Driver is dispatched.',
        ));
      },
      failure: (message, code, data) {
        emit(state.copyWith(
          status: ShipmentStateStatus.error,
          errorMessage: message,
        ));
      },
    );
  }
}
