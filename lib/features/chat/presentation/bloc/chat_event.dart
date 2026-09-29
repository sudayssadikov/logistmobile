import 'package:equatable/equatable.dart';
import '../../domain/models/chat_message_model.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();
  @override
  List<Object?> get props => [];
}

class FetchChatChannelsRequested extends ChatEvent {}

class FetchChatMessagesRequested extends ChatEvent {
  final String shipmentId;
  const FetchChatMessagesRequested(this.shipmentId);
  @override
  List<Object?> get props => [shipmentId];
}

class SendChatMessageSubmitted extends ChatEvent {
  final String shipmentId;
  final String content;
  final MessageType type;
  final VoiceNotePayload? voicePayload;
  final MediaAttachment? mediaAttachment;
  final LocationPinPayload? locationPayload;
  final ReplySnippet? replyTo;

  const SendChatMessageSubmitted({
    required this.shipmentId,
    required this.content,
    this.type = MessageType.text,
    this.voicePayload,
    this.mediaAttachment,
    this.locationPayload,
    this.replyTo,
  });

  @override
  List<Object?> get props => [
        shipmentId,
        content,
        type,
        voicePayload,
        mediaAttachment,
        locationPayload,
        replyTo,
      ];
}

class ToggleMessageReactionRequested extends ChatEvent {
  final String shipmentId;
  final String messageId;
  final String emoji;

  const ToggleMessageReactionRequested({
    required this.shipmentId,
    required this.messageId,
    required this.emoji,
  });

  @override
  List<Object?> get props => [shipmentId, messageId, emoji];
}

class EditChatMessageRequested extends ChatEvent {
  final String shipmentId;
  final String messageId;
  final String newContent;

  const EditChatMessageRequested({
    required this.shipmentId,
    required this.messageId,
    required this.newContent,
  });

  @override
  List<Object?> get props => [shipmentId, messageId, newContent];
}

class DeleteChatMessageRequested extends ChatEvent {
  final String shipmentId;
  final String messageId;

  const DeleteChatMessageRequested({
    required this.shipmentId,
    required this.messageId,
  });

  @override
  List<Object?> get props => [shipmentId, messageId];
}

class SetReplyingMessage extends ChatEvent {
  final ReplySnippet? replySnippet;

  const SetReplyingMessage(this.replySnippet);

  @override
  List<Object?> get props => [replySnippet];
}

class SearchMessagesQueryChanged extends ChatEvent {
  final String query;

  const SearchMessagesQueryChanged(this.query);

  @override
  List<Object?> get props => [query];
}

class StartVoiceRecording extends ChatEvent {}

class StopVoiceRecording extends ChatEvent {
  final bool cancel;

  const StopVoiceRecording({this.cancel = false});

  @override
  List<Object?> get props => [cancel];
}

class VoiceRecordingTick extends ChatEvent {
  final int durationSeconds;
  final List<double> waveformSamples;

  const VoiceRecordingTick({
    required this.durationSeconds,
    required this.waveformSamples,
  });

  @override
  List<Object?> get props => [durationSeconds, waveformSamples];
}
