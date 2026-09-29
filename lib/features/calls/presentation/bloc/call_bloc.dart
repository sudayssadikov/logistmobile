import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_result.dart';
import '../../domain/models/call_model.dart';
import '../../domain/repositories/call_repository.dart';
import 'call_event.dart';
import 'call_state.dart';

class CallBloc extends Bloc<CallEvent, CallState> {
  final ICallRepository _repository;
  StreamSubscription<CallSessionModel?>? _sessionSubscription;
  Timer? _durationTimer;

  CallBloc(this._repository) : super(const CallState()) {
    on<StartCallRequested>(_onStartCallRequested);
    on<IncomingCallReceived>(_onIncomingCallReceived);
    on<AnswerCallRequested>(_onAnswerCallRequested);
    on<DeclineCallRequested>(_onDeclineCallRequested);
    on<EndCallRequested>(_onEndCallRequested);
    on<ToggleMuteRequested>(_onToggleMuteRequested);
    on<ToggleSpeakerRequested>(_onToggleSpeakerRequested);
    on<ToggleVideoRequested>(_onToggleVideoRequested);
    on<SwitchCameraRequested>(_onSwitchCameraRequested);
    on<CallDurationTick>(_onCallDurationTick);
    on<FetchCallLogsRequested>(_onFetchCallLogsRequested);

    _sessionSubscription = _repository.callSessionStream.listen((session) {
      if (session != null) {
        if (session.status == CallStatus.active && _durationTimer == null) {
          _startTimer();
        } else if (session.status == CallStatus.ended || session.status == CallStatus.declined) {
          _stopTimer();
        }
        add(IncomingCallReceived(session));
      } else {
        _stopTimer();
      }
    });
  }

  void _startTimer() {
    _durationTimer?.cancel();
    int seconds = 0;
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      seconds++;
      add(CallDurationTick(seconds));
    });
  }

  void _stopTimer() {
    _durationTimer?.cancel();
    _durationTimer = null;
  }

  Future<void> _onStartCallRequested(StartCallRequested event, Emitter<CallState> emit) async {
    emit(state.copyWith(status: CallBlocStatus.loading));
    final result = await _repository.startCall(
      receiverId: event.receiverId,
      receiverName: event.receiverName,
      type: event.type,
      shipmentId: event.shipmentId,
    );

    if (result is ApiSuccess<CallSessionModel>) {
      emit(state.copyWith(
        status: CallBlocStatus.ready,
        activeSession: result.data,
      ));
    } else if (result is ApiFailure<CallSessionModel>) {
      emit(state.copyWith(
        status: CallBlocStatus.error,
        errorMessage: result.message,
      ));
    }
  }

  void _onIncomingCallReceived(IncomingCallReceived event, Emitter<CallState> emit) {
    if (event.session.status == CallStatus.ended || event.session.status == CallStatus.declined) {
      emit(state.copyWith(clearActiveSession: true, status: CallBlocStatus.ready));
    } else {
      emit(state.copyWith(activeSession: event.session, status: CallBlocStatus.ready));
    }
  }

  Future<void> _onAnswerCallRequested(AnswerCallRequested event, Emitter<CallState> emit) async {
    final result = await _repository.answerCall(event.callId);
    if (result is ApiSuccess<CallSessionModel>) {
      _startTimer();
      emit(state.copyWith(activeSession: result.data));
    }
  }

  Future<void> _onDeclineCallRequested(DeclineCallRequested event, Emitter<CallState> emit) async {
    _stopTimer();
    await _repository.declineCall(event.callId);
    emit(state.copyWith(clearActiveSession: true));
  }

  Future<void> _onEndCallRequested(EndCallRequested event, Emitter<CallState> emit) async {
    _stopTimer();
    await _repository.endCall(event.callId);
    emit(state.copyWith(clearActiveSession: true));
    add(FetchCallLogsRequested());
  }

  Future<void> _onToggleMuteRequested(ToggleMuteRequested event, Emitter<CallState> emit) async {
    final result = await _repository.toggleMute(callId: event.callId, isMuted: event.isMuted);
    if (result is ApiSuccess<CallSessionModel>) {
      emit(state.copyWith(activeSession: result.data));
    }
  }

  Future<void> _onToggleSpeakerRequested(ToggleSpeakerRequested event, Emitter<CallState> emit) async {
    final result = await _repository.toggleSpeaker(callId: event.callId, isSpeakerOn: event.isSpeakerOn);
    if (result is ApiSuccess<CallSessionModel>) {
      emit(state.copyWith(activeSession: result.data));
    }
  }

  Future<void> _onToggleVideoRequested(ToggleVideoRequested event, Emitter<CallState> emit) async {
    final result = await _repository.toggleVideo(callId: event.callId, isVideoEnabled: event.isVideoEnabled);
    if (result is ApiSuccess<CallSessionModel>) {
      emit(state.copyWith(activeSession: result.data));
    }
  }

  Future<void> _onSwitchCameraRequested(SwitchCameraRequested event, Emitter<CallState> emit) async {
    final result = await _repository.switchCamera(callId: event.callId, isFrontCamera: event.isFrontCamera);
    if (result is ApiSuccess<CallSessionModel>) {
      emit(state.copyWith(activeSession: result.data));
    }
  }

  void _onCallDurationTick(CallDurationTick event, Emitter<CallState> emit) {
    if (state.activeSession != null) {
      emit(state.copyWith(
        activeSession: state.activeSession!.copyWith(durationSeconds: event.durationSeconds),
      ));
    }
  }

  Future<void> _onFetchCallLogsRequested(FetchCallLogsRequested event, Emitter<CallState> emit) async {
    final result = await _repository.getCallLogs();
    if (result is ApiSuccess<List<CallLogModel>>) {
      emit(state.copyWith(callLogs: result.data));
    }
  }

  @override
  Future<void> close() {
    _sessionSubscription?.cancel();
    _durationTimer?.cancel();
    return super.close();
  }
}
