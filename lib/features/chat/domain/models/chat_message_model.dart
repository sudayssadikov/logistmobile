import 'package:equatable/equatable.dart';
import '../../../auth/domain/models/user_model.dart';

enum MessageType {
  text,
  voiceNote,
  image,
  video,
  document,
  locationPin,
  systemAlert,
  callLog,
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
}

class VoiceNotePayload extends Equatable {
  final int durationSeconds;
  final List<double> waveformSamples;
  final bool isPlayed;
  final double playbackSpeed;
  final String? audioUrl;

  const VoiceNotePayload({
    required this.durationSeconds,
    this.waveformSamples = const [0.2, 0.5, 0.8, 0.4, 0.9, 0.6, 0.3, 0.7, 0.5, 0.8, 0.4, 0.9, 0.3, 0.6, 0.4],
    this.isPlayed = false,
    this.playbackSpeed = 1.0,
    this.audioUrl,
  });

  VoiceNotePayload copyWith({
    int? durationSeconds,
    List<double>? waveformSamples,
    bool? isPlayed,
    double? playbackSpeed,
    String? audioUrl,
  }) {
    return VoiceNotePayload(
      durationSeconds: durationSeconds ?? this.durationSeconds,
      waveformSamples: waveformSamples ?? this.waveformSamples,
      isPlayed: isPlayed ?? this.isPlayed,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      audioUrl: audioUrl ?? this.audioUrl,
    );
  }

  @override
  List<Object?> get props => [durationSeconds, waveformSamples, isPlayed, playbackSpeed, audioUrl];
}

class MediaAttachment extends Equatable {
  final String url;
  final String fileName;
  final int fileSizeBytes;
  final String? mimeType;
  final String? extension;

  const MediaAttachment({
    required this.url,
    required this.fileName,
    required this.fileSizeBytes,
    this.mimeType,
    this.extension,
  });

  String get formattedSize {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  List<Object?> get props => [url, fileName, fileSizeBytes, mimeType, extension];
}

class LocationPinPayload extends Equatable {
  final double latitude;
  final double longitude;
  final String title;
  final String address;

  const LocationPinPayload({
    required this.latitude,
    required this.longitude,
    required this.title,
    required this.address,
  });

  @override
  List<Object?> get props => [latitude, longitude, title, address];
}

class ReplySnippet extends Equatable {
  final String messageId;
  final String senderName;
  final String content;
  final MessageType type;

  const ReplySnippet({
    required this.messageId,
    required this.senderName,
    required this.content,
    required this.type,
  });

  @override
  List<Object?> get props => [messageId, senderName, content, type];
}

class ChatMessageModel extends Equatable {
  final String id;
  final String channelId;
  final String senderId;
  final String senderName;
  final UserRole senderRole;
  final MessageType type;
  final String content;
  final DateTime timestamp;
  final bool isMine;
  final MessageStatus status;
  final ReplySnippet? replyTo;
  final Map<String, int> reactions; // e.g. {'👍': 2, '❤️': 1, '🚛': 3}
  final bool isEdited;
  final bool isDeleted;
  final VoiceNotePayload? voicePayload;
  final MediaAttachment? mediaAttachment;
  final LocationPinPayload? locationPayload;

  const ChatMessageModel({
    required this.id,
    required this.channelId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    this.type = MessageType.text,
    required this.content,
    required this.timestamp,
    this.isMine = false,
    this.status = MessageStatus.read,
    this.replyTo,
    this.reactions = const {},
    this.isEdited = false,
    this.isDeleted = false,
    this.voicePayload,
    this.mediaAttachment,
    this.locationPayload,
  });

  ChatMessageModel copyWith({
    String? id,
    String? channelId,
    String? senderId,
    String? senderName,
    UserRole? senderRole,
    MessageType? type,
    String? content,
    DateTime? timestamp,
    bool? isMine,
    MessageStatus? status,
    ReplySnippet? replyTo,
    Map<String, int>? reactions,
    bool? isEdited,
    bool? isDeleted,
    VoiceNotePayload? voicePayload,
    MediaAttachment? mediaAttachment,
    LocationPinPayload? locationPayload,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      channelId: channelId ?? this.channelId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderRole: senderRole ?? this.senderRole,
      type: type ?? this.type,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isMine: isMine ?? this.isMine,
      status: status ?? this.status,
      replyTo: replyTo ?? this.replyTo,
      reactions: reactions ?? this.reactions,
      isEdited: isEdited ?? this.isEdited,
      isDeleted: isDeleted ?? this.isDeleted,
      voicePayload: voicePayload ?? this.voicePayload,
      mediaAttachment: mediaAttachment ?? this.mediaAttachment,
      locationPayload: locationPayload ?? this.locationPayload,
    );
  }

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] as String? ?? 'MSG-${DateTime.now().millisecondsSinceEpoch}',
      channelId: json['channelId'] as String? ?? json['channel_id'] as String? ?? '',
      senderId: json['senderId'] as String? ?? json['sender_id'] as String? ?? '',
      senderName: json['senderName'] as String? ?? json['sender_name'] as String? ?? 'User',
      senderRole: UserRole.values.firstWhere(
        (r) => r.name.toLowerCase() == (json['senderRole'] ?? json['sender_role'] ?? '').toString().toLowerCase(),
        orElse: () => UserRole.shipper,
      ),
      type: MessageType.values.firstWhere(
        (t) => t.name.toLowerCase() == (json['type'] ?? '').toString().toLowerCase(),
        orElse: () => MessageType.text,
      ),
      content: json['content'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isMine: json['isMine'] as bool? ?? json['is_mine'] as bool? ?? false,
      status: MessageStatus.values.firstWhere(
        (s) => s.name.toLowerCase() == (json['status'] ?? '').toString().toLowerCase(),
        orElse: () => MessageStatus.read,
      ),
      reactions: json['reactions'] != null ? Map<String, int>.from(json['reactions'] as Map) : const {},
      isEdited: json['isEdited'] as bool? ?? json['is_edited'] as bool? ?? false,
      isDeleted: json['isDeleted'] as bool? ?? json['is_deleted'] as bool? ?? false,
      voicePayload: json['voicePayload'] != null
          ? VoiceNotePayload(
              durationSeconds: json['voicePayload']['durationSeconds'] as int? ?? 3,
              audioUrl: json['content'] as String?,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'channelId': channelId,
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole.name,
      'type': type.name,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'isMine': isMine,
      'status': status.name,
      'reactions': reactions,
      'isEdited': isEdited,
      'isDeleted': isDeleted,
    };
  }

  @override
  List<Object?> get props => [
        id,
        channelId,
        senderId,
        senderName,
        senderRole,
        type,
        content,
        timestamp,
        isMine,
        status,
        replyTo,
        reactions,
        isEdited,
        isDeleted,
        voicePayload,
        mediaAttachment,
        locationPayload,
      ];
}

class ChatChannelModel extends Equatable {
  final String id;
  final String shipmentId;
  final String shipmentTitle;
  final String trackingCode;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final List<String> participantNames;
  final bool isOnline;
  final String? typingIndicator;

  const ChatChannelModel({
    required this.id,
    required this.shipmentId,
    required this.shipmentTitle,
    required this.trackingCode,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.participantNames = const [],
    this.isOnline = true,
    this.typingIndicator,
  });

  factory ChatChannelModel.fromJson(Map<String, dynamic> json) {
    return ChatChannelModel(
      id: json['id'] as String? ?? '',
      shipmentId: json['shipmentId'] as String? ?? json['shipment_id'] as String? ?? '',
      shipmentTitle: json['shipmentTitle'] as String? ?? json['shipment_title'] as String? ?? 'Shipment',
      trackingCode: json['trackingCode'] as String? ?? json['tracking_code'] as String? ?? 'TRK-001',
      lastMessage: json['lastMessage'] as String? ?? json['last_message'] as String? ?? '',
      lastMessageTime: json['lastMessageTime'] != null
          ? DateTime.tryParse(json['lastMessageTime'].toString()) ?? DateTime.now()
          : DateTime.now(),
      unreadCount: json['unreadCount'] as int? ?? json['unread_count'] as int? ?? 0,
      participantNames: json['participantNames'] != null
          ? List<String>.from(json['participantNames'] as List)
          : const [],
      isOnline: json['isOnline'] as bool? ?? json['is_online'] as bool? ?? true,
    );
  }

  ChatChannelModel copyWith({
    String? id,
    String? shipmentId,
    String? shipmentTitle,
    String? trackingCode,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
    List<String>? participantNames,
    bool? isOnline,
    String? typingIndicator,
  }) {
    return ChatChannelModel(
      id: id ?? this.id,
      shipmentId: shipmentId ?? this.shipmentId,
      shipmentTitle: shipmentTitle ?? this.shipmentTitle,
      trackingCode: trackingCode ?? this.trackingCode,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      participantNames: participantNames ?? this.participantNames,
      isOnline: isOnline ?? this.isOnline,
      typingIndicator: typingIndicator,
    );
  }

  @override
  List<Object?> get props => [
        id,
        shipmentId,
        shipmentTitle,
        trackingCode,
        lastMessage,
        lastMessageTime,
        unreadCount,
        participantNames,
        isOnline,
        typingIndicator,
      ];
}
