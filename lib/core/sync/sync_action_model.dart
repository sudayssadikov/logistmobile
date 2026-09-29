import 'dart:convert';
import 'package:equatable/equatable.dart';

enum SyncActionType {
  advanceStatus,
  submitPod,
  sendChatMessage,
  streamGpsTelemetry,
  submitBid,
}

class SyncActionModel extends Equatable {
  final String id;
  final SyncActionType type;
  final String endpoint;
  final String method; // POST, PUT, PATCH
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int retryCount;

  const SyncActionModel({
    required this.id,
    required this.type,
    required this.endpoint,
    required this.method,
    required this.payload,
    required this.createdAt,
    this.retryCount = 0,
  });

  SyncActionModel copyWith({int? retryCount}) {
    return SyncActionModel(
      id: id,
      type: type,
      endpoint: endpoint,
      method: method,
      payload: payload,
      createdAt: createdAt,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'endpoint': endpoint,
        'method': method,
        'payload': payload,
        'created_at': createdAt.toIso8601String(),
        'retry_count': retryCount,
      };

  factory SyncActionModel.fromJson(Map<String, dynamic> json) => SyncActionModel(
        id: json['id'] as String,
        type: SyncActionType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => SyncActionType.advanceStatus,
        ),
        endpoint: json['endpoint'] as String,
        method: json['method'] as String? ?? 'POST',
        payload: (json['payload'] as Map<String, dynamic>?) ?? {},
        createdAt: DateTime.parse(json['created_at'] as String),
        retryCount: json['retry_count'] as int? ?? 0,
      );

  String toRawJson() => jsonEncode(toJson());

  factory SyncActionModel.fromRawJson(String raw) =>
      SyncActionModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);

  @override
  List<Object?> get props => [id, type, endpoint, method, payload, createdAt, retryCount];
}
