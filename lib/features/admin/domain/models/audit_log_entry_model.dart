import 'package:equatable/equatable.dart';

class AuditLogEntryModel extends Equatable {
  final String id;
  final String actorId;
  final String actorName;
  final String targetId;
  final String actionType; // 'USER_SUSPEND', 'ESCROW_FREEZE', 'KYC_APPROVE', 'DISPUTE_SETTLE'
  final String description;
  final String ipAddress;
  final String deviceFingerprint;
  final DateTime timestamp;

  const AuditLogEntryModel({
    required this.id,
    required this.actorId,
    required this.actorName,
    required this.targetId,
    required this.actionType,
    required this.description,
    required this.ipAddress,
    required this.deviceFingerprint,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'actorId': actorId,
        'actorName': actorName,
        'targetId': targetId,
        'actionType': actionType,
        'description': description,
        'ipAddress': ipAddress,
        'deviceFingerprint': deviceFingerprint,
        'timestamp': timestamp.toIso8601String(),
      };

  factory AuditLogEntryModel.fromJson(Map<String, dynamic> json) => AuditLogEntryModel(
        id: json['id'] as String,
        actorId: json['actorId'] as String,
        actorName: json['actorName'] as String,
        targetId: json['targetId'] as String,
        actionType: json['actionType'] as String,
        description: json['description'] as String,
        ipAddress: json['ipAddress'] as String,
        deviceFingerprint: json['deviceFingerprint'] as String,
        timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
      );

  @override
  List<Object?> get props => [
        id,
        actorId,
        actorName,
        targetId,
        actionType,
        description,
        ipAddress,
        deviceFingerprint,
        timestamp,
      ];
}
