import '../models/security_model.dart';

abstract class ISettingsRepository {
  Future<SecuritySettings> getSecuritySettings();
  Future<void> toggleBiometrics(bool enabled);
  Future<void> toggle2FA(bool enabled);
  Future<void> terminateOtherSessions();
  Future<AppPreferences> getPreferences();
  Future<void> updatePreferences(AppPreferences preferences);
  Future<double> clearCache();
}
