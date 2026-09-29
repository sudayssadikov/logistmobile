import 'dart:async';
import '../../../../core/network/api_result.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../domain/models/call_model.dart';
import '../../domain/repositories/call_repository.dart';

class CallRepositoryImpl implements ICallRepository {
  final DioClient? _dioClient;
  final StreamController<CallSessionModel?> _sessionController = StreamController<CallSessionModel?>.broadcast();
  CallSessionModel? _activeSession;
  final List<CallLogModel> _callLogs = [];

  CallRepositoryImpl([this._dioClient]);

  @override
  Stream<CallSessionModel?> get callSessionStream => _sessionController.stream;

  @override
  Future<ApiResult<CallSessionModel>> startCall({
    required String receiverId,
    required String receiverName,
    required CallType type,
    String? shipmentId,
  }) async {
    if (_dioClient != null) {
      try {
        await _dioClient!.post(
          '/calls/initiate',
          data: {
            'receiver_id': receiverId,
            'receiver_name': receiverName,
            'call_type': type.name,
            'shipment_id': shipmentId,
          },
        );
      } catch (_) {
        // Fallback
      }
    }

    await Future.delayed(const Duration(milliseconds: 150));

    final session = CallSessionModel(
      id: 'CALL-${DateTime.now().millisecondsSinceEpoch}',
      shipmentId: shipmentId,
      callerId: 'USR-ME',
      callerName: 'You',
      callerRole: UserRole.shipper,
      receiverId: receiverId,
      receiverName: receiverName,
      receiverRole: UserRole.driver,
      type: type,
      status: CallStatus.outgoing,
      direction: CallDirection.outgoing,
      startedAt: DateTime.now(),
    );

    _activeSession = session;
    _sessionController.add(_activeSession);

    // Simulate connection after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (_activeSession != null && _activeSession!.status == CallStatus.outgoing) {
        _activeSession = _activeSession!.copyWith(
          status: CallStatus.active,
          connectedAt: DateTime.now(),
        );
        _sessionController.add(_activeSession);
      }
    });

    return ApiSuccess(session);
  }

  @override
  Future<ApiResult<CallSessionModel>> answerCall(String callId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    if (_activeSession != null) {
      _activeSession = _activeSession!.copyWith(
        status: CallStatus.active,
        connectedAt: DateTime.now(),
      );
      _sessionController.add(_activeSession);
      return ApiSuccess(_activeSession!);
    }
    return const ApiFailure(message: 'Call session not found');
  }

  @override
  Future<ApiResult<CallSessionModel>> declineCall(String callId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    if (_activeSession != null) {
      _activeSession = _activeSession!.copyWith(
        status: CallStatus.declined,
        endedAt: DateTime.now(),
      );
      _sessionController.add(_activeSession);
      _activeSession = null;
      return ApiSuccess(
        CallSessionModel(
          id: callId,
          callerId: '',
          callerName: '',
          callerRole: UserRole.driver,
          receiverId: '',
          receiverName: '',
          receiverRole: UserRole.shipper,
          status: CallStatus.declined,
          startedAt: DateTime.now(),
        ),
      );
    }
    return const ApiFailure(message: 'Call session not found');
  }

  @override
  Future<ApiResult<CallSessionModel>> endCall(String callId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    if (_activeSession != null) {
      final ended = _activeSession!.copyWith(
        status: CallStatus.ended,
        endedAt: DateTime.now(),
      );

      // Add to logs
      _callLogs.insert(
        0,
        CallLogModel(
          id: 'LOG-${DateTime.now().millisecondsSinceEpoch}',
          participantName: ended.receiverName,
          participantRole: ended.receiverRole,
          type: ended.type,
          direction: ended.direction,
          outcome: CallStatus.ended,
          durationSeconds: ended.durationSeconds > 0 ? ended.durationSeconds : 12,
          timestamp: DateTime.now(),
        ),
      );

      _activeSession = null;
      _sessionController.add(null);
      return ApiSuccess(ended);
    }
    return const ApiFailure(message: 'No active call to end');
  }

  @override
  Future<ApiResult<CallSessionModel>> toggleMute({required String callId, required bool isMuted}) async {
    if (_activeSession != null) {
      _activeSession = _activeSession!.copyWith(isMicMuted: isMuted);
      _sessionController.add(_activeSession);
      return ApiSuccess(_activeSession!);
    }
    return const ApiFailure(message: 'No active call');
  }

  @override
  Future<ApiResult<CallSessionModel>> toggleSpeaker({required String callId, required bool isSpeakerOn}) async {
    if (_activeSession != null) {
      _activeSession = _activeSession!.copyWith(isSpeakerOn: isSpeakerOn);
      _sessionController.add(_activeSession);
      return ApiSuccess(_activeSession!);
    }
    return const ApiFailure(message: 'No active call');
  }

  @override
  Future<ApiResult<CallSessionModel>> toggleVideo({required String callId, required bool isVideoEnabled}) async {
    if (_activeSession != null) {
      _activeSession = _activeSession!.copyWith(isVideoEnabled: isVideoEnabled);
      _sessionController.add(_activeSession);
      return ApiSuccess(_activeSession!);
    }
    return const ApiFailure(message: 'No active call');
  }

  @override
  Future<ApiResult<CallSessionModel>> switchCamera({required String callId, required bool isFrontCamera}) async {
    if (_activeSession != null) {
      _activeSession = _activeSession!.copyWith(isFrontCamera: isFrontCamera);
      _sessionController.add(_activeSession);
      return ApiSuccess(_activeSession!);
    }
    return const ApiFailure(message: 'No active call');
  }

  @override
  Future<ApiResult<List<CallLogModel>>> getCallLogs() async {
    if (_dioClient != null) {
      try {
        final response = await _dioClient!.get('/calls/history');
        if (response.statusCode == 200 && response.data != null) {
          final List raw = response.data['data'] ?? [];
          if (raw.isNotEmpty) {
            return ApiSuccess(raw.map((e) => CallLogModel.fromJson(e)).toList());
          }
        }
      } catch (_) {
        // Fallback
      }
    }
    await Future.delayed(const Duration(milliseconds: 150));
    return ApiSuccess(_callLogs);
  }
}
