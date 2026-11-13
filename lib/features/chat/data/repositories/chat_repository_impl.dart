import '../../../../core/network/api_result.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../domain/models/chat_message_model.dart';
import '../../domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements IChatRepository {
  final DioClient? _dioClient;
  final Map<String, List<ChatMessageModel>> _localMessages = {};

  ChatRepositoryImpl([this._dioClient]);

  @override
  Future<ApiResult<List<ChatChannelModel>>> getChannels() async {
    if (_dioClient == null) {
      return const ApiFailure(message: 'Server bilan aloqa mavjud emas');
    }
    try {
      final response = await _dioClient!.get('/chat/channels');
      if (response.statusCode == 200 && response.data != null) {
        final rawData = response.data['data'] as List<dynamic>? ?? [];
        final channels = rawData
            .map((item) => ChatChannelModel.fromJson(item as Map<String, dynamic>))
            .toList();
        return ApiSuccess(channels);
      }
      return ApiFailure(message: response.data?['message'] ?? 'Chat kanallarini yuklab bo\'lmadi');
    } catch (e) {
      return ApiFailure(message: 'Chat kanallarini yuklab bo\'lmadi: ${e.toString()}');
    }
  }

  @override
  Future<ApiResult<List<ChatMessageModel>>> getMessages(String channelOrShipmentId) async {
    final key = channelOrShipmentId.startsWith('CH-')
        ? channelOrShipmentId.replaceFirst('CH-', '')
        : channelOrShipmentId;

    if (_dioClient == null) {
      return const ApiFailure(message: 'Server bilan aloqa mavjud emas');
    }
    try {
      final response = await _dioClient!.get('/chat/$key');
      if (response.statusCode == 200 && response.data != null) {
        final rawData = response.data['data'] as List<dynamic>? ?? [];
        final messages = rawData
            .map((item) => ChatMessageModel.fromJson(item as Map<String, dynamic>))
            .toList();
        _localMessages[key] = messages;
        return ApiSuccess(messages);
      }
      return ApiFailure(message: response.data?['message'] ?? 'Xabarlarni yuklab bo\'lmadi');
    } catch (e) {
      return ApiFailure(message: 'Xabarlarni yuklab bo\'lmadi: ${e.toString()}');
    }
  }

  @override
  Future<ApiResult<ChatMessageModel>> sendMessage({
    required String channelOrShipmentId,
    required String content,
    required MessageType type,
    VoiceNotePayload? voicePayload,
    MediaAttachment? mediaAttachment,
    LocationPinPayload? locationPayload,
    ReplySnippet? replyTo,
  }) async {
    final key = channelOrShipmentId.startsWith('CH-')
        ? channelOrShipmentId.replaceFirst('CH-', '')
        : channelOrShipmentId;

    if (_dioClient != null) {
      try {
        final payload = {
          'type': type.name,
          'content': content,
          if (voicePayload != null)
            'voicePayload': {
              'durationSeconds': voicePayload.durationSeconds,
              'waveformSamples': voicePayload.waveformSamples,
              'isPlayed': voicePayload.isPlayed,
              'playbackSpeed': voicePayload.playbackSpeed,
            },
          if (mediaAttachment != null)
            'mediaAttachment': {
              'url': mediaAttachment.url,
              'fileName': mediaAttachment.fileName,
              'fileSizeBytes': mediaAttachment.fileSizeBytes,
            },
          if (locationPayload != null)
            'locationPayload': {
              'latitude': locationPayload.latitude,
              'longitude': locationPayload.longitude,
              'title': locationPayload.title,
              'address': locationPayload.address,
            },
        };

        final response = await _dioClient!.post(
          '/chat/$key',
          data: payload,
        );

        if (response.statusCode == 200 && response.data != null) {
          final msgData = response.data['data'] as Map<String, dynamic>;
          final msg = ChatMessageModel.fromJson(msgData);
          _localMessages.putIfAbsent(key, () => []).add(msg);
          return ApiSuccess(msg);
        }
      } catch (_) {}
    }

    // Unsent offline queue message (status: sending / pending)
    final localMsg = ChatMessageModel(
      id: 'MSG-${DateTime.now().millisecondsSinceEpoch}',
      channelId: key,
      senderId: 'USR-ME',
      senderName: 'You',
      senderRole: UserRole.shipper,
      type: type,
      content: content,
      timestamp: DateTime.now(),
      isMine: true,
      status: MessageStatus.sending, // Yuborilmagan / navbatda
      voicePayload: voicePayload,
      mediaAttachment: mediaAttachment,
      locationPayload: locationPayload,
      replyTo: replyTo,
    );

    _localMessages.putIfAbsent(key, () => []).add(localMsg);
    return ApiSuccess(localMsg);
  }

  @override
  Future<ApiResult<ChatMessageModel>> toggleReaction({
    required String channelOrShipmentId,
    required String messageId,
    required String emoji,
  }) async {
    final key = channelOrShipmentId.startsWith('CH-')
        ? channelOrShipmentId.replaceFirst('CH-', '')
        : channelOrShipmentId;
    final list = _localMessages[key] ?? [];
    final index = list.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      final current = list[index];
      final currentMap = Map<String, int>.from(current.reactions);
      if (currentMap.containsKey(emoji)) {
        if (currentMap[emoji]! > 1) {
          currentMap[emoji] = currentMap[emoji]! - 1;
        } else {
          currentMap.remove(emoji);
        }
      } else {
        currentMap[emoji] = 1;
      }
      final updated = current.copyWith(reactions: currentMap);
      list[index] = updated;
      return ApiSuccess(updated);
    }
    return const ApiFailure(message: 'Message not found');
  }

  @override
  Future<ApiResult<ChatMessageModel>> editMessage({
    required String channelOrShipmentId,
    required String messageId,
    required String newContent,
  }) async {
    final key = channelOrShipmentId.startsWith('CH-')
        ? channelOrShipmentId.replaceFirst('CH-', '')
        : channelOrShipmentId;
    final list = _localMessages[key] ?? [];
    final index = list.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      final current = list[index];
      final updated = current.copyWith(content: newContent, isEdited: true);
      list[index] = updated;
      return ApiSuccess(updated);
    }
    return const ApiFailure(message: 'Message not found');
  }

  @override
  Future<ApiResult<bool>> deleteMessage({
    required String channelOrShipmentId,
    required String messageId,
  }) async {
    final key = channelOrShipmentId.startsWith('CH-')
        ? channelOrShipmentId.replaceFirst('CH-', '')
        : channelOrShipmentId;
    final list = _localMessages[key] ?? [];
    final index = list.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      final current = list[index];
      list[index] = current.copyWith(isDeleted: true, content: 'This message was deleted');
      return const ApiSuccess(true);
    }
    return const ApiFailure(message: 'Message not found');
  }
}
