import 'package:equatable/equatable.dart';
import '../../domain/models/call_model.dart';

enum CallBlocStatus {
  initial,
  loading,
  ready,
  error,
}

class CallState extends Equatable {
  final CallBlocStatus status;
  final CallSessionModel? activeSession;
  final List<CallLogModel> callLogs;
  final String? errorMessage;

  const CallState({
    this.status = CallBlocStatus.initial,
    this.activeSession,
    this.callLogs = const [],
    this.errorMessage,
  });

  bool get hasActiveCall => activeSession != null &&
      (activeSession!.status == CallStatus.active ||
          activeSession!.status == CallStatus.outgoing ||
          activeSession!.status == CallStatus.incoming ||
          activeSession!.status == CallStatus.connecting);

  CallState copyWith({
    CallBlocStatus? status,
    CallSessionModel? activeSession,
    bool clearActiveSession = false,
    List<CallLogModel>? callLogs,
    String? errorMessage,
  }) {
    return CallState(
      status: status ?? this.status,
      activeSession: clearActiveSession ? null : (activeSession ?? this.activeSession),
      callLogs: callLogs ?? this.callLogs,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, activeSession, callLogs, errorMessage];
}
