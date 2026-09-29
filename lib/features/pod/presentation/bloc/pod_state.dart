import 'package:equatable/equatable.dart';
import '../../domain/models/pod_submission_model.dart';

enum PodStatus { initial, loading, success, error }

class PodState extends Equatable {
  final PodStatus status;
  final PodSubmissionModel? podData;
  final String? errorMessage;

  const PodState({
    this.status = PodStatus.initial,
    this.podData,
    this.errorMessage,
  });

  PodState copyWith({
    PodStatus? status,
    PodSubmissionModel? podData,
    String? errorMessage,
  }) {
    return PodState(
      status: status ?? this.status,
      podData: podData ?? this.podData,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, podData, errorMessage];
}
