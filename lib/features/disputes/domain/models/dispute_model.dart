import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';

enum DisputeReason {
  damagedCargo(labelKey: 'disputes.damagedCargo', icon: Icons.broken_image_outlined),
  lateDelivery(labelKey: 'disputes.lateDelivery', icon: Icons.timer_off_outlined),
  paymentIssue(labelKey: 'disputes.paymentIssue', icon: Icons.payment_outlined),
  missingPaperwork(labelKey: 'disputes.missingPaperwork', icon: Icons.description_outlined);

  final String labelKey;
  final IconData icon;

  const DisputeReason({
    required this.labelKey,
    required this.icon,
  });
}

enum DisputeStatus {
  underReview(
    labelKey: 'disputes.underReview',
    stepIndex: 1,
    color: AppColors.amber,
  ),
  evidenceRequested(
    labelKey: 'disputes.evidenceRequested',
    stepIndex: 2,
    color: AppColors.indigo,
  ),
  resolved(
    labelKey: 'disputes.resolved',
    stepIndex: 3,
    color: AppColors.primary,
  ),
  refundProcessed(
    labelKey: 'disputes.refundProcessed',
    stepIndex: 4,
    color: AppColors.emerald,
  );

  final String labelKey;
  final int stepIndex;
  final Color color;

  const DisputeStatus({
    required this.labelKey,
    required this.stepIndex,
    required this.color,
  });
}

class DisputeTimelineItem extends Equatable {
  final DisputeStatus status;
  final String message;
  final DateTime timestamp;

  const DisputeTimelineItem({
    required this.status,
    required this.message,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'status': status.name,
        'message': message,
        'timestamp': timestamp.toIso8601String(),
      };

  factory DisputeTimelineItem.fromJson(Map<String, dynamic> json) => DisputeTimelineItem(
        status: DisputeStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => DisputeStatus.underReview,
        ),
        message: json['message'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );

  @override
  List<Object?> get props => [status, message, timestamp];
}

class DisputeModel extends Equatable {
  final String id;
  final String shipmentId;
  final String trackingCode;
  final String claimantName;
  final DisputeReason reason;
  final String description;
  final double claimAmount;
  final List<String> evidencePhotos;
  final DisputeStatus status;
  final List<DisputeTimelineItem> timeline;
  final DateTime createdAt;

  const DisputeModel({
    required this.id,
    required this.shipmentId,
    required this.trackingCode,
    required this.claimantName,
    required this.reason,
    required this.description,
    required this.claimAmount,
    this.evidencePhotos = const [],
    required this.status,
    required this.timeline,
    required this.createdAt,
  });

  DisputeModel copyWith({
    String? id,
    String? shipmentId,
    String? trackingCode,
    String? claimantName,
    DisputeReason? reason,
    String? description,
    double? claimAmount,
    List<String>? evidencePhotos,
    DisputeStatus? status,
    List<DisputeTimelineItem>? timeline,
    DateTime? createdAt,
  }) {
    return DisputeModel(
      id: id ?? this.id,
      shipmentId: shipmentId ?? this.shipmentId,
      trackingCode: trackingCode ?? this.trackingCode,
      claimantName: claimantName ?? this.claimantName,
      reason: reason ?? this.reason,
      description: description ?? this.description,
      claimAmount: claimAmount ?? this.claimAmount,
      evidencePhotos: evidencePhotos ?? this.evidencePhotos,
      status: status ?? this.status,
      timeline: timeline ?? this.timeline,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'shipment_id': shipmentId,
        'tracking_code': trackingCode,
        'claimant_name': claimantName,
        'reason': reason.name,
        'description': description,
        'claim_amount': claimAmount,
        'evidence_photos': evidencePhotos,
        'status': status.name,
        'timeline': timeline.map((t) => t.toJson()).toList(),
        'created_at': createdAt.toIso8601String(),
      };

  factory DisputeModel.fromJson(Map<String, dynamic> json) => DisputeModel(
        id: json['id'] as String,
        shipmentId: json['shipment_id'] as String,
        trackingCode: json['tracking_code'] as String,
        claimantName: json['claimant_name'] as String,
        reason: DisputeReason.values.firstWhere(
          (e) => e.name == json['reason'],
          orElse: () => DisputeReason.damagedCargo,
        ),
        description: json['description'] as String,
        claimAmount: (json['claim_amount'] as num).toDouble(),
        evidencePhotos: (json['evidence_photos'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
        status: DisputeStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => DisputeStatus.underReview,
        ),
        timeline: (json['timeline'] as List<dynamic>?)
                ?.map((e) => DisputeTimelineItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  @override
  List<Object?> get props => [
        id,
        shipmentId,
        trackingCode,
        claimantName,
        reason,
        description,
        claimAmount,
        evidencePhotos,
        status,
        timeline,
        createdAt,
      ];
}
