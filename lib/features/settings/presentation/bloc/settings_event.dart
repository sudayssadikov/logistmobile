import 'package:equatable/equatable.dart';
import '../../domain/models/security_model.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();
  @override
  List<Object?> get props => [];
}

class LoadSettingsRequested extends SettingsEvent {}

class ToggleBiometricsRequested extends SettingsEvent {
  final bool enabled;
  const ToggleBiometricsRequested(this.enabled);
  @override
  List<Object?> get props => [enabled];
}

class Toggle2FARequested extends SettingsEvent {
  final bool enabled;
  const Toggle2FARequested(this.enabled);
  @override
  List<Object?> get props => [enabled];
}

class TerminateOtherSessionsRequested extends SettingsEvent {}

class UpdateUnitSystemRequested extends SettingsEvent {
  final UnitSystem unit;
  const UpdateUnitSystemRequested(this.unit);
  @override
  List<Object?> get props => [unit];
}

class UpdateCurrencyRequested extends SettingsEvent {
  final PreferredCurrency currency;
  const UpdateCurrencyRequested(this.currency);
  @override
  List<Object?> get props => [currency];
}

class UpdateMapEngineRequested extends SettingsEvent {
  final MapEngine engine;
  const UpdateMapEngineRequested(this.engine);
  @override
  List<Object?> get props => [engine];
}

class ClearCacheRequested extends SettingsEvent {}
