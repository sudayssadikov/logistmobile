import 'dart:async';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/chat_message_model.dart';
import '../../domain/repositories/chat_repository.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final IChatRepository _chatRepository;
  Timer? _recordingTimer;
  final Random _random = Random();

  ChatBloc(this._chatRepository) : super(const ChatState()) {
    on<FetchChatChannelsRequested>(_onFetchChatChannelsRequested);
    on<FetchChatMessagesRequested>(_onFetchChatMessagesRequested);
    on<SendChatMessageSubmitted>(_onSendChatMessageSubmitted);
    on<ToggleMessageReactionRequested>(_onToggleMessageReactionRequested);
    on<EditChatMessageRequested>(_onEditChatMessageRequested);
    on<DeleteChatMessageRequested>(_onDeleteChatMessageRequested);
    on<SetReplyingMessage>(_onSetReplyingMessage);
    on<SearchMessagesQueryChanged>(_onSearchMessagesQueryChanged);
    on<StartVoiceRecording>(_onStartVoiceRecording);
    on<StopVoiceRecording>(_onStopVoiceRecording);
    on<VoiceRecordingTick>(_onVoiceRecordingTick);
  }

  Future<void> _onFetchChatChannelsRequested(
    FetchChatChannelsRequested event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(status: ChatStatus.loading));
    final result = await _chatRepository.getChannels();
    result.when(
      success: (channels) {
        emit(state.copyWith(
          status: ChatStatus.success,
          channels: channels,
        ));
      },
      failure: (message, code, data) {
        emit(state.copyWith(
          status: ChatStatus.error,
          errorMessage: message,
        ));
      },
    );
  }

  Future<void> _onFetchChatMessagesRequested(
    FetchChatMessagesRequested event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(status: ChatStatus.loading));
    final result = await _chatRepository.getMessages(event.shipmentId);
    result.when(
      success: (messages) {
        emit(state.copyWith(
          status: ChatStatus.success,
          messages: messages,
        ));
      },
      failure: (message, code, data) {
        emit(state.copyWith(
          status: ChatStatus.error,
          errorMessage: message,
        ));
      },
    );
  }

  Future<void> _onSendChatMessageSubmitted(
    SendChatMessageSubmitted event,
    Emitter<ChatState> emit,
  ) async {
    final result = await _chatRepository.sendMessage(
      channelOrShipmentId: event.shipmentId,
      content: event.content,
      type: event.type,
      voicePayload: event.voicePayload,
      mediaAttachment: event.mediaAttachment,
      locationPayload: event.locationPayload,
      replyTo: event.replyTo,
    );

    result.when(
      success: (msg) {
        final updatedList = List<ChatMessageModel>.from(state.messages)..add(msg);
        emit(state.copyWith(
          messages: updatedList,
          clearReplying: true,
        ));
      },
      failure: (message, code, data) {
        emit(state.copyWith(
          status: ChatStatus.error,
          errorMessage: message,
        ));
      },
    );
  }

  Future<void> _onToggleMessageReactionRequested(
    ToggleMessageReactionRequested event,
    Emitter<ChatState> emit,
  ) async {
    final result = await _chatRepository.toggleReaction(
      channelOrShipmentId: event.shipmentId,
      messageId: event.messageId,
      emoji: event.emoji,
    );

    result.when(
      success: (updatedMsg) {
        final updatedList = state.messages.map((m) {
          return m.id == updatedMsg.id ? updatedMsg : m;
        }).toList();
        emit(state.copyWith(messages: updatedList));
      },
      failure: (_, __, ___) {},
    );
  }

  Future<void> _onEditChatMessageRequested(
    EditChatMessageRequested event,
    Emitter<ChatState> emit,
  ) async {
    final result = await _chatRepository.editMessage(
      channelOrShipmentId: event.shipmentId,
      messageId: event.messageId,
      newContent: event.newContent,
    );

    result.when(
      success: (updatedMsg) {
        final updatedList = state.messages.map((m) {
          return m.id == updatedMsg.id ? updatedMsg : m;
        }).toList();
        emit(state.copyWith(messages: updatedList));
      },
      failure: (_, __, ___) {},
    );
  }

  Future<void> _onDeleteChatMessageRequested(
    DeleteChatMessageRequested event,
    Emitter<ChatState> emit,
  ) async {
    final result = await _chatRepository.deleteMessage(
      channelOrShipmentId: event.shipmentId,
      messageId: event.messageId,
    );

    result.when(
      success: (_) {
        final updatedList = state.messages.map((m) {
          if (m.id == event.messageId) {
            return m.copyWith(isDeleted: true, content: 'This message was deleted');
          }
          return m;
        }).toList();
        emit(state.copyWith(messages: updatedList));
      },
      failure: (_, __, ___) {},
    );
  }

  void _onSetReplyingMessage(SetReplyingMessage event, Emitter<ChatState> emit) {
    if (event.replySnippet == null) {
      emit(state.copyWith(clearReplying: true));
    } else {
      emit(state.copyWith(replyingMessage: event.replySnippet));
    }
  }

  void _onSearchMessagesQueryChanged(SearchMessagesQueryChanged event, Emitter<ChatState> emit) {
    emit(state.copyWith(searchQuery: event.query));
  }

  void _onStartVoiceRecording(StartVoiceRecording event, Emitter<ChatState> emit) {
    _recordingTimer?.cancel();
    int seconds = 0;
    final samples = <double>[];

    emit(state.copyWith(
      isRecordingVoice: true,
      recordingDurationSeconds: 0,
      recordingWaveform: const [],
    ));

    _recordingTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (timer.tick % 5 == 0) {
        seconds++;
      }
      final newSample = 0.2 + _random.nextDouble() * 0.75;
      samples.add(newSample);
      if (samples.length > 25) samples.removeAt(0);

      add(VoiceRecordingTick(
        durationSeconds: seconds,
        waveformSamples: List<double>.from(samples),
      ));
    });
  }

  void _onStopVoiceRecording(StopVoiceRecording event, Emitter<ChatState> emit) {
    _recordingTimer?.cancel();
    _recordingTimer = null;
    emit(state.copyWith(
      isRecordingVoice: false,
      recordingDurationSeconds: 0,
      recordingWaveform: const [],
    ));
  }

  void _onVoiceRecordingTick(VoiceRecordingTick event, Emitter<ChatState> emit) {
    emit(state.copyWith(
      recordingDurationSeconds: event.durationSeconds,
      recordingWaveform: event.waveformSamples,
    ));
  }

  @override
  Future<void> close() {
    _recordingTimer?.cancel();
    return super.close();
  }
}
