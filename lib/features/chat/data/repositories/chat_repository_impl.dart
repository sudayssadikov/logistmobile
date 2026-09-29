import '../../../../core/network/api_result.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../domain/models/chat_message_model.dart';
import '../../domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements IChatRepository {
  final DioClient? _dioClient;
  final List<ChatChannelModel> _channels = [];
  final Map<String, List<ChatMessageModel>> _messages = {};

  ChatRepositoryImpl([this._dioClient]);

  @override
  Future<ApiResult<List<ChatChannelModel>>> getChannels() async {
    if (_dioClient != null) {
      try {
        final response = await _dioClient!.get('/chat/channels');
        if (response.statusCode == 200 && response.data != null) {
          // Channel updates
        }
      } catch (_) {
        // Fallback
      }
    }
    await Future.delayed(const Duration(milliseconds: 150));
    return ApiSuccess(_channels);
  }

  @override
  Future<ApiResult<List<ChatMessageModel>>> getMessages(String channelOrShipmentId) async {
    final key = channelOrShipmentId.startsWith('CH-')
        ? channelOrShipmentId.replaceFirst('CH-', '')
        : channelOrShipmentId;

    if (_dioClient != null) {
      try {
        final response = await _dioClient!.get('/chat/messages/$key');
        if (response.statusCode == 200 && response.data != null) {
          // Parse remote messages
        }
      } catch (_) {
        // Fallback
      }
    }

    await Future.delayed(const Duration(milliseconds: 150));
    final list = _messages[key] ?? [];
    return ApiSuccess(list);
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
        await _dioClient!.post(
          '/chat/messages',
          data: {
            'channel_id': key,
            'content': content,
            'type': type.name,
          },
        );
      } catch (_) {
        // Fallback
      }
    }

    await Future.delayed(const Duration(milliseconds: 100));

    final msg = ChatMessageModel(
      id: 'MSG-${DateTime.now().millisecondsSinceEpoch}',
      channelId: 'CH-$key',
      senderId: 'USR-ME',
      senderName: 'You',
      senderRole: UserRole.shipper,
      type: type,
      content: content,
      timestamp: DateTime.now(),
      isMine: true,
      status: MessageStatus.delivered,
      voicePayload: voicePayload,
      mediaAttachment: mediaAttachment,
      locationPayload: locationPayload,
      replyTo: replyTo,
    );

    _messages.putIfAbsent(key, () => []).add(msg);
    return ApiSuccess(msg);
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
    final list = _messages[key] ?? [];
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
    final list = _messages[key] ?? [];
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
    final list = _messages[key] ?? [];
    final index = list.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      final current = list[index];
      list[index] = current.copyWith(isDeleted: true, content: 'This message was deleted');
      return const ApiSuccess(true);
    }
    return const ApiFailure(message: 'Message not found');
  }
}
