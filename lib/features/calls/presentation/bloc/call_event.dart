import 'package:equatable/equatable.dart';
import '../../domain/models/call_model.dart';

abstract class CallEvent extends Equatable {
  const CallEvent();

  @override
  List<Object?> get props => [];
}

class StartCallRequested extends CallEvent {
  final String receiverId;
  final String receiverName;
  final CallType type;
  final String? shipmentId;

  const StartCallRequested({
    required this.receiverId,
    required this.receiverName,
    required this.type,
    this.shipmentId,
  });

  @override
  List<Object?> get props => [receiverId, receiverName, type, shipmentId];
}

class IncomingCallReceived extends CallEvent {
  final CallSessionModel session;

  const IncomingCallReceived(this.session);

  @override
  List<Object?> get props => [session];
}

class AnswerCallRequested extends CallEvent {
  final String callId;

  const AnswerCallRequested(this.callId);

  @override
  List<Object?> get props => [callId];
}

class DeclineCallRequested extends CallEvent {
  final String callId;

  const DeclineCallRequested(this.callId);

  @override
  List<Object?> get props => [callId];
}

class EndCallRequested extends CallEvent {
  final String callId;

  const EndCallRequested(this.callId);

  @override
  List<Object?> get props => [callId];
}

class ToggleMuteRequested extends CallEvent {
  final String callId;
  final bool isMuted;

  const ToggleMuteRequested({required this.callId, required this.isMuted});

  @override
  List<Object?> get props => [callId, isMuted];
}

class ToggleSpeakerRequested extends CallEvent {
  final String callId;
  final bool isSpeakerOn;

  const ToggleSpeakerRequested({required this.callId, required this.isSpeakerOn});

  @override
  List<Object?> get props => [callId, isSpeakerOn];
}

class ToggleVideoRequested extends CallEvent {
  final String callId;
  final bool isVideoEnabled;

  const ToggleVideoRequested({required this.callId, required this.isVideoEnabled});

  @override
  List<Object?> get props => [callId, isVideoEnabled];
}

class SwitchCameraRequested extends CallEvent {
  final String callId;
  final bool isFrontCamera;

  const SwitchCameraRequested({required this.callId, required this.isFrontCamera});

  @override
  List<Object?> get props => [callId, isFrontCamera];
}

class CallDurationTick extends CallEvent {
  final int durationSeconds;

  const CallDurationTick(this.durationSeconds);

  @override
  List<Object?> get props => [durationSeconds];
}

class FetchCallLogsRequested extends CallEvent {}
