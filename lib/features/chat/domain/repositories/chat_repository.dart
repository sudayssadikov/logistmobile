import '../../../../core/network/api_result.dart';
import '../models/chat_message_model.dart';

abstract class IChatRepository {
  Future<ApiResult<List<ChatChannelModel>>> getChannels();
  Future<ApiResult<List<ChatMessageModel>>> getMessages(String channelOrShipmentId);

  Future<ApiResult<ChatMessageModel>> sendMessage({
    required String channelOrShipmentId,
    required String content,
    required MessageType type,
    VoiceNotePayload? voicePayload,
    MediaAttachment? mediaAttachment,
    LocationPinPayload? locationPayload,
    ReplySnippet? replyTo,
  });

  Future<ApiResult<ChatMessageModel>> toggleReaction({
    required String channelOrShipmentId,
    required String messageId,
    required String emoji,
  });

  Future<ApiResult<ChatMessageModel>> editMessage({
    required String channelOrShipmentId,
    required String messageId,
    required String newContent,
  });

  Future<ApiResult<bool>> deleteMessage({
    required String channelOrShipmentId,
    required String messageId,
  });
}
