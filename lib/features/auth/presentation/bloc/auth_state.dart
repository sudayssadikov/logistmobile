import 'package:equatable/equatable.dart';
import '../../domain/models/user_model.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  otpSent,
  error,
}

class AuthState extends Equatable {
  final AuthStatus status;
  final UserModel? user;
  final UserRole selectedRole;
  final String? errorMessage;
  final String? pendingPhone;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.selectedRole = UserRole.shipper,
    this.errorMessage,
    this.pendingPhone,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    UserRole? selectedRole,
    String? errorMessage,
    String? pendingPhone,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      selectedRole: selectedRole ?? this.selectedRole,
      errorMessage: errorMessage,
      pendingPhone: pendingPhone ?? this.pendingPhone,
    );
  }

  @override
  List<Object?> get props => [status, user, selectedRole, errorMessage, pendingPhone];
}
