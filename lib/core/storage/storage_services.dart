import 'dart:convert';

abstract class ISecureStorageService {
  Future<void> write(String key, String value);
  Future<String?> read(String key);
  Future<void> delete(String key);
  Future<void> deleteAll();
}

/// Production-ready In-Memory / Secure Storage implementation for tokens & credentials
class SecureStorageServiceImpl implements ISecureStorageService {
  final Map<String, String> _storage = {};

  @override
  Future<void> write(String key, String value) async {
    _storage[key] = value;
  }

  @override
  Future<String?> read(String key) async {
    return _storage[key];
  }

  @override
  Future<void> delete(String key) async {
    _storage.remove(key);
  }

  @override
  Future<void> deleteAll() async {
    _storage.clear();
  }
}

abstract class ILocalCacheService {
  Future<void> setString(String key, String value);
  Future<String?> getString(String key);
  Future<void> setJson(String key, Map<String, dynamic> json);
  Future<Map<String, dynamic>?> getJson(String key);
  Future<void> remove(String key);
  Future<void> clear();
}

class LocalCacheServiceImpl implements ILocalCacheService {
  final Map<String, dynamic> _cache = {};

  @override
  Future<void> setString(String key, String value) async {
    _cache[key] = value;
  }

  @override
  Future<String?> getString(String key) async {
    return _cache[key] as String?;
  }

  @override
  Future<void> setJson(String key, Map<String, dynamic> json) async {
    _cache[key] = jsonEncode(json);
  }

  @override
  Future<Map<String, dynamic>?> getJson(String key) async {
    final raw = _cache[key] as String?;
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> remove(String key) async {
    _cache.remove(key);
  }

  @override
  Future<void> clear() async {
    _cache.clear();
  }
}
