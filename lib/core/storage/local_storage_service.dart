import 'dart:convert';
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

/// Abstract contract for local storage (Token persistence, User profile, App preferences)
abstract class ILocalStorageService {
  Future<void> saveToken(String token);
  Future<String?> getToken();
  Future<void> saveRefreshToken(String token);
  Future<String?> getRefreshToken();
  Future<void> clearAuthData();

  Future<void> saveUserRole(String role);
  Future<String?> getUserRole();

  Future<void> saveUserProfile(Map<String, dynamic> userJson);
  Future<Map<String, dynamic>?> getUserProfile();

  Future<void> saveThemeMode(ThemeMode mode);
  Future<ThemeMode> getThemeMode();

  Future<void> saveLanguage(String languageCode);
  Future<String> getLanguage();
}

/// In-memory & preference-backed storage implementation for cross-platform reliability
class LocalStorageService implements ILocalStorageService {
  // In-memory cache for ultra-fast sync access & mock session
  final Map<String, dynamic> _memoryStore = {};

  LocalStorageService() {
    _initDefaults();
  }

  void _initDefaults() {
    _memoryStore[AppConstants.themeModeKey] = 'dark';
    _memoryStore[AppConstants.languageKey] = 'en';
  }

  @override
  Future<void> saveToken(String token) async {
    _memoryStore[AppConstants.tokenKey] = token;
  }

  @override
  Future<String?> getToken() async {
    return _memoryStore[AppConstants.tokenKey] as String?;
  }

  @override
  Future<void> saveRefreshToken(String token) async {
    _memoryStore[AppConstants.refreshTokenKey] = token;
  }

  @override
  Future<String?> getRefreshToken() async {
    return _memoryStore[AppConstants.refreshTokenKey] as String?;
  }

  @override
  Future<void> clearAuthData() async {
    _memoryStore.remove(AppConstants.tokenKey);
    _memoryStore.remove(AppConstants.refreshTokenKey);
    _memoryStore.remove(AppConstants.userRoleKey);
    _memoryStore.remove(AppConstants.userProfileKey);
  }

  @override
  Future<void> saveUserRole(String role) async {
    _memoryStore[AppConstants.userRoleKey] = role;
  }

  @override
  Future<String?> getUserRole() async {
    return _memoryStore[AppConstants.userRoleKey] as String?;
  }

  @override
  Future<void> saveUserProfile(Map<String, dynamic> userJson) async {
    _memoryStore[AppConstants.userProfileKey] = jsonEncode(userJson);
  }

  @override
  Future<Map<String, dynamic>?> getUserProfile() async {
    final raw = _memoryStore[AppConstants.userProfileKey] as String?;
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveThemeMode(ThemeMode mode) async {
    _memoryStore[AppConstants.themeModeKey] = mode == ThemeMode.dark ? 'dark' : 'light';
  }

  @override
  Future<ThemeMode> getThemeMode() async {
    final mode = _memoryStore[AppConstants.themeModeKey] as String?;
    return mode == 'light' ? ThemeMode.light : ThemeMode.dark;
  }

  @override
  Future<void> saveLanguage(String languageCode) async {
    _memoryStore[AppConstants.languageKey] = languageCode;
  }

  @override
  Future<String> getLanguage() async {
    return (_memoryStore[AppConstants.languageKey] as String?) ?? 'en';
  }
}
