import 'package:equatable/equatable.dart';

enum UnitSystem { metric, imperial }
enum PreferredCurrency { uzs, usd, rub }
enum MapEngine { googleMaps, yandexMaps, openStreetMap }

class ActiveSession extends Equatable {
  final String id;
  final String deviceModel;
  final String ipAddress;
  final String location;
  final DateTime lastActive;
  final bool isCurrent;

  const ActiveSession({
    required this.id,
    required this.deviceModel,
    required this.ipAddress,
    required this.location,
    required this.lastActive,
    this.isCurrent = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'deviceModel': deviceModel,
        'ipAddress': ipAddress,
        'location': location,
        'lastActive': lastActive.toIso8601String(),
        'isCurrent': isCurrent,
      };

  factory ActiveSession.fromJson(Map<String, dynamic> json) => ActiveSession(
        id: json['id'] as String,
        deviceModel: json['deviceModel'] as String,
        ipAddress: json['ipAddress'] as String,
        location: json['location'] as String,
        lastActive: DateTime.parse(json['lastActive'] as String),
        isCurrent: json['isCurrent'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [id, deviceModel, ipAddress, location, lastActive, isCurrent];
}

class AppPreferences extends Equatable {
  final UnitSystem unitSystem;
  final PreferredCurrency currency;
  final MapEngine mapEngine;
  final double cacheSizeMB;

  const AppPreferences({
    this.unitSystem = UnitSystem.metric,
    this.currency = PreferredCurrency.uzs,
    this.mapEngine = MapEngine.yandexMaps,
    this.cacheSizeMB = 48.6,
  });

  AppPreferences copyWith({
    UnitSystem? unitSystem,
    PreferredCurrency? currency,
    MapEngine? mapEngine,
    double? cacheSizeMB,
  }) {
    return AppPreferences(
      unitSystem: unitSystem ?? this.unitSystem,
      currency: currency ?? this.currency,
      mapEngine: mapEngine ?? this.mapEngine,
      cacheSizeMB: cacheSizeMB ?? this.cacheSizeMB,
    );
  }

  @override
  List<Object?> get props => [unitSystem, currency, mapEngine, cacheSizeMB];
}

class SecuritySettings extends Equatable {
  final bool isBiometricEnabled;
  final bool is2FAEnabled;
  final List<ActiveSession> sessions;

  const SecuritySettings({
    this.isBiometricEnabled = true,
    this.is2FAEnabled = false,
    this.sessions = const [],
  });

  SecuritySettings copyWith({
    bool? isBiometricEnabled,
    bool? is2FAEnabled,
    List<ActiveSession>? sessions,
  }) {
    return SecuritySettings(
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      is2FAEnabled: is2FAEnabled ?? this.is2FAEnabled,
      sessions: sessions ?? this.sessions,
    );
  }

  @override
  List<Object?> get props => [isBiometricEnabled, is2FAEnabled, sessions];
}
