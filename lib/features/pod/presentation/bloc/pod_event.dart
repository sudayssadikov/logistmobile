import 'package:equatable/equatable.dart';
import '../../domain/models/pod_submission_model.dart';

abstract class PodEvent extends Equatable {
  const PodEvent();
  @override
  List<Object?> get props => [];
}

class SubmitPodRequested extends PodEvent {
  final PodSubmissionModel submission;
  const SubmitPodRequested(this.submission);
  @override
  List<Object?> get props => [submission];
}

class FetchPodDetailsRequested extends PodEvent {
  final String shipmentId;
  const FetchPodDetailsRequested(this.shipmentId);
  @override
  List<Object?> get props => [shipmentId];
}
