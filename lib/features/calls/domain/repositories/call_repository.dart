import '../../../../core/network/api_result.dart';
import '../models/call_model.dart';

abstract class ICallRepository {
  Future<ApiResult<CallSessionModel>> startCall({
    required String receiverId,
    required String receiverName,
    required CallType type,
    String? shipmentId,
  });

  Future<ApiResult<CallSessionModel>> answerCall(String callId);
  Future<ApiResult<CallSessionModel>> declineCall(String callId);
  Future<ApiResult<CallSessionModel>> endCall(String callId);

  Future<ApiResult<CallSessionModel>> toggleMute({required String callId, required bool isMuted});
  Future<ApiResult<CallSessionModel>> toggleSpeaker({required String callId, required bool isSpeakerOn});
  Future<ApiResult<CallSessionModel>> toggleVideo({required String callId, required bool isVideoEnabled});
  Future<ApiResult<CallSessionModel>> switchCamera({required String callId, required bool isFrontCamera});

  Future<ApiResult<List<CallLogModel>>> getCallLogs();
  Stream<CallSessionModel?> get callSessionStream;
}
