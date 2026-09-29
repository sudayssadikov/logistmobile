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
  final String? typingIndicator; // e.g. 'typing...', 'recording audio...'

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
