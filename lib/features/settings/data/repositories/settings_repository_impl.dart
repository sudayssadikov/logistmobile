import 'dart:async';
import 'package:local_auth/local_auth.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/models/security_model.dart';
import '../../domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements ISettingsRepository {
  final DioClient? _dioClient;
  final LocalAuthentication _localAuth = LocalAuthentication();

  SecuritySettings _securitySettings = SecuritySettings(
    isBiometricEnabled: true,
    is2FAEnabled: false,
    sessions: [
      ActiveSession(
        id: 'SES-01',
        deviceModel: 'Samsung Galaxy / iPhone (Mobile Device)',
        ipAddress: '178.218.201.44',
        location: 'Tashkent, Uzbekistan',
        lastActive: DateTime.now(),
        isCurrent: true,
      ),
      ActiveSession(
        id: 'SES-02',
        deviceModel: 'Chrome on macOS / Windows',
        ipAddress: '84.54.120.12',
        location: 'Samarkand, Uzbekistan',
        lastActive: DateTime.now().subtract(const Duration(hours: 3)),
        isCurrent: false,
      ),
    ],
  );

  AppPreferences _preferences = const AppPreferences(
    unitSystem: UnitSystem.metric,
    currency: PreferredCurrency.uzs,
    mapEngine: MapEngine.yandexMaps,
    cacheSizeMB: 54.2,
  );

  SettingsRepositoryImpl([this._dioClient]);

  @override
  Future<SecuritySettings> getSecuritySettings() async {
    if (_dioClient != null) {
      try {
        final response = await _dioClient!.get('/auth/security-settings');
        if (response.statusCode == 200 && response.data != null) {
          // Backend response
        }
      } catch (_) {
        // Fallback
      }
    }
    await Future.delayed(const Duration(milliseconds: 150));
    return _securitySettings;
  }

  @override
  Future<void> toggleBiometrics(bool enabled) async {
    if (enabled) {
      try {
        final canCheck = await _localAuth.canCheckBiometrics;
        final isDeviceSupported = await _localAuth.isDeviceSupported();
        if (canCheck || isDeviceSupported) {
          final authenticated = await _localAuth.authenticate(
            localizedReason: 'LogiFlow tizimiga xavfsiz kirish uchun biometriyani faollashtiring',
            options: const AuthenticationOptions(
              stickyAuth: true,
              biometricOnly: false,
            ),
          );
          if (!authenticated) return;
        }
      } catch (_) {
        // Device without biometric hardware: allow toggle in demo/emulator
      }
    }

    _securitySettings = _securitySettings.copyWith(isBiometricEnabled: enabled);
  }

  @override
  Future<void> toggle2FA(bool enabled) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _securitySettings = _securitySettings.copyWith(is2FAEnabled: enabled);
  }

  @override
  Future<void> terminateOtherSessions() async {
    if (_dioClient != null) {
      try {
        await _dioClient!.post('/auth/sessions/terminate-others');
      } catch (_) {
        // Fallback
      }
    }
    await Future.delayed(const Duration(milliseconds: 200));
    final currentOnly = _securitySettings.sessions.where((s) => s.isCurrent).toList();
    _securitySettings = _securitySettings.copyWith(sessions: currentOnly);
  }

  @override
  Future<AppPreferences> getPreferences() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _preferences;
  }

  @override
  Future<void> updatePreferences(AppPreferences preferences) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _preferences = preferences;
  }

  @override
  Future<double> clearCache() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _preferences = _preferences.copyWith(cacheSizeMB: 0.4);
    return 0.4;
  }
}
