import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/settings_repository.dart';
import 'settings_event.dart';
import 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final ISettingsRepository _repository;

  SettingsBloc({required ISettingsRepository repository})
      : _repository = repository,
        super(const SettingsState()) {
    on<LoadSettingsRequested>(_onLoadSettings);
    on<ToggleBiometricsRequested>(_onToggleBiometrics);
    on<Toggle2FARequested>(_onToggle2FA);
    on<TerminateOtherSessionsRequested>(_onTerminateOtherSessions);
    on<UpdateUnitSystemRequested>(_onUpdateUnitSystem);
    on<UpdateCurrencyRequested>(_onUpdateCurrency);
    on<UpdateMapEngineRequested>(_onUpdateMapEngine);
    on<ClearCacheRequested>(_onClearCache);
  }

  Future<void> _onLoadSettings(
    LoadSettingsRequested event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(status: SettingsStateStatus.loading));
    try {
      final sec = await _repository.getSecuritySettings();
      final prefs = await _repository.getPreferences();
      emit(state.copyWith(
        status: SettingsStateStatus.success,
        security: sec,
        preferences: prefs,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: SettingsStateStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onToggleBiometrics(
    ToggleBiometricsRequested event,
    Emitter<SettingsState> emit,
  ) async {
    await _repository.toggleBiometrics(event.enabled);
    emit(state.copyWith(
      security: state.security.copyWith(isBiometricEnabled: event.enabled),
    ));
  }

  Future<void> _onToggle2FA(
    Toggle2FARequested event,
    Emitter<SettingsState> emit,
  ) async {
    await _repository.toggle2FA(event.enabled);
    emit(state.copyWith(
      security: state.security.copyWith(is2FAEnabled: event.enabled),
    ));
  }

  Future<void> _onTerminateOtherSessions(
    TerminateOtherSessionsRequested event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(status: SettingsStateStatus.loading));
    await _repository.terminateOtherSessions();
    final sec = await _repository.getSecuritySettings();
    emit(state.copyWith(
      status: SettingsStateStatus.success,
      security: sec,
      successMessage: 'Other sessions terminated successfully',
    ));
  }

  Future<void> _onUpdateUnitSystem(
    UpdateUnitSystemRequested event,
    Emitter<SettingsState> emit,
  ) async {
    final updated = state.preferences.copyWith(unitSystem: event.unit);
    await _repository.updatePreferences(updated);
    emit(state.copyWith(preferences: updated));
  }

  Future<void> _onUpdateCurrency(
    UpdateCurrencyRequested event,
    Emitter<SettingsState> emit,
  ) async {
    final updated = state.preferences.copyWith(currency: event.currency);
    await _repository.updatePreferences(updated);
    emit(state.copyWith(preferences: updated));
  }

  Future<void> _onUpdateMapEngine(
    UpdateMapEngineRequested event,
    Emitter<SettingsState> emit,
  ) async {
    final updated = state.preferences.copyWith(mapEngine: event.engine);
    await _repository.updatePreferences(updated);
    emit(state.copyWith(preferences: updated));
  }

  Future<void> _onClearCache(
    ClearCacheRequested event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(status: SettingsStateStatus.loading));
    final newSize = await _repository.clearCache();
    emit(state.copyWith(
      status: SettingsStateStatus.success,
      preferences: state.preferences.copyWith(cacheSizeMB: newSize),
      successMessage: 'Cache cleared successfully',
    ));
  }
}
