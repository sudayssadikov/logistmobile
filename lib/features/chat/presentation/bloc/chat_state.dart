import 'package:equatable/equatable.dart';
import '../../domain/models/chat_message_model.dart';

enum ChatStatus { initial, loading, success, error }

class ChatState extends Equatable {
  final ChatStatus status;
  final List<ChatChannelModel> channels;
  final List<ChatMessageModel> messages;
  final ReplySnippet? replyingMessage;
  final String searchQuery;
  final bool isRecordingVoice;
  final int recordingDurationSeconds;
  final List<double> recordingWaveform;
  final String? errorMessage;

  const ChatState({
    this.status = ChatStatus.initial,
    this.channels = const [],
    this.messages = const [],
    this.replyingMessage,
    this.searchQuery = '',
    this.isRecordingVoice = false,
    this.recordingDurationSeconds = 0,
    this.recordingWaveform = const [],
    this.errorMessage,
  });

  List<ChatMessageModel> get filteredMessages {
    if (searchQuery.trim().isEmpty) return messages;
    final q = searchQuery.toLowerCase();
    return messages.where((m) => m.content.toLowerCase().contains(q)).toList();
  }

  ChatState copyWith({
    ChatStatus? status,
    List<ChatChannelModel>? channels,
    List<ChatMessageModel>? messages,
    ReplySnippet? replyingMessage,
    bool clearReplying = false,
    String? searchQuery,
    bool? isRecordingVoice,
    int? recordingDurationSeconds,
    List<double>? recordingWaveform,
    String? errorMessage,
  }) {
    return ChatState(
      status: status ?? this.status,
      channels: channels ?? this.channels,
      messages: messages ?? this.messages,
      replyingMessage: clearReplying ? null : (replyingMessage ?? this.replyingMessage),
      searchQuery: searchQuery ?? this.searchQuery,
      isRecordingVoice: isRecordingVoice ?? this.isRecordingVoice,
      recordingDurationSeconds: recordingDurationSeconds ?? this.recordingDurationSeconds,
      recordingWaveform: recordingWaveform ?? this.recordingWaveform,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        channels,
        messages,
        replyingMessage,
        searchQuery,
        isRecordingVoice,
        recordingDurationSeconds,
        recordingWaveform,
        errorMessage,
      ];
}
