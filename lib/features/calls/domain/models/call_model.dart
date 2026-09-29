import 'package:equatable/equatable.dart';
import '../../../auth/domain/models/user_model.dart';

enum CallType {
  audio,
  video,
}

enum CallStatus {
  idle,
  outgoing,
  incoming,
  connecting,
  active,
  ended,
  missed,
  declined,
}

enum CallDirection {
  incoming,
  outgoing,
}

class CallSessionModel extends Equatable {
  final String id;
  final String? shipmentId;
  final String callerId;
  final String callerName;
  final UserRole callerRole;
  final String? callerAvatar;
  final String receiverId;
  final String receiverName;
  final UserRole receiverRole;
  final String? receiverAvatar;
  final CallType type;
  final CallStatus status;
  final CallDirection direction;
  final DateTime startedAt;
  final DateTime? connectedAt;
  final DateTime? endedAt;
  final int durationSeconds;
  final bool isMicMuted;
  final bool isSpeakerOn;
  final bool isVideoEnabled;
  final bool isFrontCamera;
  final String networkQuality; // 'HD Excellent', 'Good', 'Fair'
  final String codec; // 'Opus 48kHz HD (E2EE)'

  const CallSessionModel({
    required this.id,
    this.shipmentId,
    required this.callerId,
    required this.callerName,
    required this.callerRole,
    this.callerAvatar,
    required this.receiverId,
    required this.receiverName,
    required this.receiverRole,
    this.receiverAvatar,
    this.type = CallType.audio,
    this.status = CallStatus.idle,
    this.direction = CallDirection.outgoing,
    required this.startedAt,
    this.connectedAt,
    this.endedAt,
    this.durationSeconds = 0,
    this.isMicMuted = false,
    this.isSpeakerOn = false,
    this.isVideoEnabled = true,
    this.isFrontCamera = true,
    this.networkQuality = 'HD Excellent',
    this.codec = 'Opus 48kHz (End-to-End Encrypted)',
  });

  String get formattedDuration {
    final minutes = (durationSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (durationSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  CallSessionModel copyWith({
    String? id,
    String? shipmentId,
    String? callerId,
    String? callerName,
    UserRole? callerRole,
    String? callerAvatar,
    String? receiverId,
    String? receiverName,
    UserRole? receiverRole,
    String? receiverAvatar,
    CallType? type,
    CallStatus? status,
    CallDirection? direction,
    DateTime? startedAt,
    DateTime? connectedAt,
    DateTime? endedAt,
    int? durationSeconds,
    bool? isMicMuted,
    bool? isSpeakerOn,
    bool? isVideoEnabled,
    bool? isFrontCamera,
    String? networkQuality,
    String? codec,
  }) {
    return CallSessionModel(
      id: id ?? this.id,
      shipmentId: shipmentId ?? this.shipmentId,
      callerId: callerId ?? this.callerId,
      callerName: callerName ?? this.callerName,
      callerRole: callerRole ?? this.callerRole,
      callerAvatar: callerAvatar ?? this.callerAvatar,
      receiverId: receiverId ?? this.receiverId,
      receiverName: receiverName ?? this.receiverName,
      receiverRole: receiverRole ?? this.receiverRole,
      receiverAvatar: receiverAvatar ?? this.receiverAvatar,
      type: type ?? this.type,
      status: status ?? this.status,
      direction: direction ?? this.direction,
      startedAt: startedAt ?? this.startedAt,
      connectedAt: connectedAt ?? this.connectedAt,
      endedAt: endedAt ?? this.endedAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      isMicMuted: isMicMuted ?? this.isMicMuted,
      isSpeakerOn: isSpeakerOn ?? this.isSpeakerOn,
      isVideoEnabled: isVideoEnabled ?? this.isVideoEnabled,
      isFrontCamera: isFrontCamera ?? this.isFrontCamera,
      networkQuality: networkQuality ?? this.networkQuality,
      codec: codec ?? this.codec,
    );
  }

  @override
  List<Object?> get props => [
        id,
        shipmentId,
        callerId,
        callerName,
        callerRole,
        callerAvatar,
        receiverId,
        receiverName,
        receiverRole,
        receiverAvatar,
        type,
        status,
        direction,
        startedAt,
        connectedAt,
        endedAt,
        durationSeconds,
        isMicMuted,
        isSpeakerOn,
        isVideoEnabled,
        isFrontCamera,
        networkQuality,
        codec,
      ];
}

class CallLogModel extends Equatable {
  final String id;
  final String participantName;
  final UserRole participantRole;
  final String? participantPhone;
  final CallType type;
  final CallDirection direction;
  final CallStatus outcome;
  final int durationSeconds;
  final DateTime timestamp;

  const CallLogModel({
    required this.id,
    required this.participantName,
    required this.participantRole,
    this.participantPhone,
    required this.type,
    required this.direction,
    required this.outcome,
    required this.durationSeconds,
    required this.timestamp,
  });

  String get formattedDuration {
    if (outcome == CallStatus.missed || outcome == CallStatus.declined) {
      return '0s';
    }
    final m = durationSeconds ~/ 60;
    final s = durationSeconds % 60;
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'participant_name': participantName,
        'participant_role': participantRole.key,
        'participant_phone': participantPhone,
        'type': type.name,
        'direction': direction.name,
        'outcome': outcome.name,
        'duration_seconds': durationSeconds,
        'timestamp': timestamp.toIso8601String(),
      };

  factory CallLogModel.fromJson(Map<String, dynamic> json) => CallLogModel(
        id: json['id'] as String? ?? 'LOG-00',
        participantName: json['participant_name'] as String? ?? json['participantName'] as String? ?? 'Contact',
        participantRole: UserRole.fromKey(json['participant_role'] as String? ?? json['participantRole'] as String?),
        participantPhone: json['participant_phone'] as String? ?? json['participantPhone'] as String?,
        type: (json['type'] as String?) == 'video' ? CallType.video : CallType.audio,
        direction: (json['direction'] as String?) == 'incoming' ? CallDirection.incoming : CallDirection.outgoing,
        outcome: CallStatus.values.firstWhere(
          (s) => s.name == (json['outcome'] as String? ?? 'ended'),
          orElse: () => CallStatus.ended,
        ),
        durationSeconds: (json['duration_seconds'] as num?)?.toInt() ?? (json['durationSeconds'] as num?)?.toInt() ?? 0,
        timestamp: json['timestamp'] != null
            ? DateTime.parse(json['timestamp'] as String)
            : DateTime.now(),
      );

  @override
  List<Object?> get props => [
        id,
        participantName,
        participantRole,
        participantPhone,
        type,
        direction,
        outcome,
        durationSeconds,
        timestamp,
      ];
}
