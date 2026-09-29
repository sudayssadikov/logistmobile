import 'package:equatable/equatable.dart';
import '../../domain/models/dispute_model.dart';

abstract class DisputeEvent extends Equatable {
  const DisputeEvent();
  @override
  List<Object?> get props => [];
}

class LoadDisputesRequested extends DisputeEvent {}

class LoadDisputeDetailRequested extends DisputeEvent {
  final String disputeId;
  const LoadDisputeDetailRequested(this.disputeId);
  @override
  List<Object?> get props => [disputeId];
}

class CreateDisputeSubmitted extends DisputeEvent {
  final String shipmentId;
  final String trackingCode;
  final String claimantName;
  final DisputeReason reason;
  final String description;
  final double claimAmount;
  final List<String> evidencePhotos;

  const CreateDisputeSubmitted({
    required this.shipmentId,
    required this.trackingCode,
    required this.claimantName,
    required this.reason,
    required this.description,
    required this.claimAmount,
    this.evidencePhotos = const [],
  });

  @override
  List<Object?> get props => [
        shipmentId,
        trackingCode,
        claimantName,
        reason,
        description,
        claimAmount,
        evidencePhotos,
      ];
}
