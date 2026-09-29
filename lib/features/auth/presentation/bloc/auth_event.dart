import 'package:equatable/equatable.dart';
import '../../domain/models/user_model.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthLoginSubmitted extends AuthEvent {
  final String emailOrPhone;
  final String password;
  final UserRole role;

  const AuthLoginSubmitted({
    required this.emailOrPhone,
    required this.password,
    required this.role,
  });

  @override
  List<Object?> get props => [emailOrPhone, password, role];
}

class AuthRegisterSubmitted extends AuthEvent {
  final UserModel user;
  final String password;

  const AuthRegisterSubmitted({
    required this.user,
    required this.password,
  });

  @override
  List<Object?> get props => [user, password];
}

class AuthSendOtpSubmitted extends AuthEvent {
  final String phone;

  const AuthSendOtpSubmitted({required this.phone});

  @override
  List<Object?> get props => [phone];
}

class AuthVerifyOtpSubmitted extends AuthEvent {
  final String phone;
  final String otp;
  final UserRole role;

  const AuthVerifyOtpSubmitted({
    required this.phone,
    required this.otp,
    required this.role,
  });

  @override
  List<Object?> get props => [phone, otp, role];
}

class AuthBiometricLoginSubmitted extends AuthEvent {
  final UserRole role;

  const AuthBiometricLoginSubmitted({required this.role});

  @override
  List<Object?> get props => [role];
}

class AuthRoleSwitched extends AuthEvent {
  final UserRole newRole;

  const AuthRoleSwitched(this.newRole);

  @override
  List<Object?> get props => [newRole];
}

class AuthUpdateProfileSubmitted extends AuthEvent {
  final UserModel updatedUser;

  const AuthUpdateProfileSubmitted(this.updatedUser);

  @override
  List<Object?> get props => [updatedUser];
}

class AuthLogoutRequested extends AuthEvent {}
