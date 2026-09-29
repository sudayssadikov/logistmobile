import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final IAuthRepository _authRepository;

  AuthBloc(this._authRepository) : super(const AuthState()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginSubmitted>(_onAuthLoginSubmitted);
    on<AuthRegisterSubmitted>(_onAuthRegisterSubmitted);
    on<AuthSendOtpSubmitted>(_onAuthSendOtpSubmitted);
    on<AuthVerifyOtpSubmitted>(_onAuthVerifyOtpSubmitted);
    on<AuthBiometricLoginSubmitted>(_onAuthBiometricLoginSubmitted);
    on<AuthRoleSwitched>(_onAuthRoleSwitched);
    on<AuthUpdateProfileSubmitted>(_onAuthUpdateProfileSubmitted);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    final result = await _authRepository.getCurrentUser();
    result.when(
      success: (user) {
        if (user != null) {
          emit(state.copyWith(
            status: AuthStatus.authenticated,
            user: user,
            selectedRole: user.role,
          ));
        } else {
          emit(state.copyWith(status: AuthStatus.unauthenticated));
        }
      },
      failure: (message, code, data) {
        emit(state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: message,
        ));
      },
    );
  }

  Future<void> _onAuthLoginSubmitted(
    AuthLoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, selectedRole: event.role));
    final result = await _authRepository.loginWithPassword(
      emailOrPhone: event.emailOrPhone,
      password: event.password,
      role: event.role,
    );
    result.when(
      success: (user) {
        emit(state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          selectedRole: user.role,
        ));
      },
      failure: (message, code, data) {
        emit(state.copyWith(
          status: AuthStatus.error,
          errorMessage: message,
        ));
      },
    );
  }

  Future<void> _onAuthRegisterSubmitted(
    AuthRegisterSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, selectedRole: event.user.role));
    final result = await _authRepository.registerUser(
      user: event.user,
      password: event.password,
    );
    result.when(
      success: (user) {
        emit(state.copyWith(
          status: AuthStatus.unauthenticated,
          selectedRole: user.role,
        ));
      },
      failure: (message, code, data) {
        emit(state.copyWith(
          status: AuthStatus.error,
          errorMessage: message,
        ));
      },
    );
  }

  Future<void> _onAuthSendOtpSubmitted(
    AuthSendOtpSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    final result = await _authRepository.sendOtp(phone: event.phone);
    result.when(
      success: (_) {
        emit(state.copyWith(
          status: AuthStatus.otpSent,
          pendingPhone: event.phone,
        ));
      },
      failure: (message, code, data) {
        emit(state.copyWith(
          status: AuthStatus.error,
          errorMessage: message,
        ));
      },
    );
  }

  Future<void> _onAuthVerifyOtpSubmitted(
    AuthVerifyOtpSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    final result = await _authRepository.verifyOtp(
      phone: event.phone,
      otp: event.otp,
      role: event.role,
    );
    result.when(
      success: (user) {
        emit(state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          selectedRole: user.role,
        ));
      },
      failure: (message, code, data) {
        emit(state.copyWith(
          status: AuthStatus.error,
          errorMessage: message,
        ));
      },
    );
  }

  Future<void> _onAuthBiometricLoginSubmitted(
    AuthBiometricLoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    final result = await _authRepository.biometricLogin(role: event.role);
    result.when(
      success: (user) {
        emit(state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          selectedRole: user.role,
        ));
      },
      failure: (message, code, data) {
        emit(state.copyWith(
          status: AuthStatus.error,
          errorMessage: message,
        ));
      },
    );
  }

  Future<void> _onAuthRoleSwitched(
    AuthRoleSwitched event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    final result = await _authRepository.switchRole(event.newRole);
    result.when(
      success: (user) {
        emit(state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          selectedRole: user.role,
        ));
      },
      failure: (message, code, data) {
        emit(state.copyWith(
          status: AuthStatus.error,
          errorMessage: message,
        ));
      },
    );
  }

  Future<void> _onAuthUpdateProfileSubmitted(
    AuthUpdateProfileSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    final result = await _authRepository.updateProfile(event.updatedUser);
    result.when(
      success: (user) {
        emit(state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
        ));
      },
      failure: (message, code, data) {
        emit(state.copyWith(
          status: AuthStatus.error,
          errorMessage: message,
        ));
      },
    );
  }

  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.logout();
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }
}
