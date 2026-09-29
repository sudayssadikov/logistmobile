import 'package:equatable/equatable.dart';
import '../../domain/models/security_model.dart';

enum SettingsStateStatus { initial, loading, success, failure }

class SettingsState extends Equatable {
  final SettingsStateStatus status;
  final SecuritySettings security;
  final AppPreferences preferences;
  final String? successMessage;
  final String? errorMessage;

  const SettingsState({
    this.status = SettingsStateStatus.initial,
    this.security = const SecuritySettings(),
    this.preferences = const AppPreferences(),
    this.successMessage,
    this.errorMessage,
  });

  SettingsState copyWith({
    SettingsStateStatus? status,
    SecuritySettings? security,
    AppPreferences? preferences,
    String? successMessage,
    String? errorMessage,
  }) {
    return SettingsState(
      status: status ?? this.status,
      security: security ?? this.security,
      preferences: preferences ?? this.preferences,
      successMessage: successMessage,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, security, preferences, successMessage, errorMessage];
}
