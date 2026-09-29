import 'package:equatable/equatable.dart';
import '../../domain/models/dispute_model.dart';

enum DisputeStateStatus { initial, loading, success, failure }

class DisputeState extends Equatable {
  final DisputeStateStatus status;
  final List<DisputeModel> disputes;
  final DisputeModel? selectedDispute;
  final String? successMessage;
  final String? errorMessage;

  const DisputeState({
    this.status = DisputeStateStatus.initial,
    this.disputes = const [],
    this.selectedDispute,
    this.successMessage,
    this.errorMessage,
  });

  DisputeState copyWith({
    DisputeStateStatus? status,
    List<DisputeModel>? disputes,
    DisputeModel? selectedDispute,
    String? successMessage,
    String? errorMessage,
  }) {
    return DisputeState(
      status: status ?? this.status,
      disputes: disputes ?? this.disputes,
      selectedDispute: selectedDispute ?? this.selectedDispute,
      successMessage: successMessage,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, disputes, selectedDispute, successMessage, errorMessage];
}
