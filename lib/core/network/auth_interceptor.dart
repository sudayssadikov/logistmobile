import 'dart:async';
import 'package:dio/dio.dart';
import '../storage/local_storage_service.dart';

class AuthInterceptor extends QueuedInterceptor {
  final Dio dio;
  final ILocalStorageService storage;
  bool _isRefreshing = false;
  Completer<String?>? _refreshTokenCompleter;

  AuthInterceptor({required this.dio, required this.storage});

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip token injection for public authentication routes
    final isPublic = options.path.contains('/auth/login') ||
        options.path.contains('/auth/otp') ||
        options.path.contains('/auth/register');

    if (!isPublic) {
      final token = await storage.getToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    options.headers['Accept'] = 'application/json';
    options.headers['Content-Type'] = 'application/json';

    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401 &&
        !err.requestOptions.path.contains('/auth/login') &&
        !err.requestOptions.path.contains('/auth/refresh')) {
      final newAccessToken = await _performTokenRefresh();

      if (newAccessToken != null) {
        final retryOptions = err.requestOptions;
        retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';

        try {
          final response = await dio.fetch(retryOptions);
          return handler.resolve(response);
        } catch (e) {
          return handler.next(err);
        }
      }
    }

    return handler.next(err);
  }

  Future<String?> _performTokenRefresh() async {
    if (_isRefreshing) {
      return _refreshTokenCompleter?.future;
    }

    _isRefreshing = true;
    _refreshTokenCompleter = Completer<String?>();

    try {
      final refreshToken = await storage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        _refreshTokenCompleter?.complete(null);
        return null;
      }

      final refreshDio = Dio(
        BaseOptions(
          baseUrl: dio.options.baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      final response = await refreshDio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : <String, dynamic>{};
        final newAccess = data['access_token'] as String?;
        final newRefresh = data['refresh_token'] as String?;

        if (newAccess != null) {
          await storage.saveToken(newAccess);
          if (newRefresh != null) {
            await storage.saveRefreshToken(newRefresh);
          }
          _refreshTokenCompleter?.complete(newAccess);
          return newAccess;
        }
      }
    } catch (_) {
      await storage.clearAuthData();
    } finally {
      _isRefreshing = false;
    }

    _refreshTokenCompleter?.complete(null);
    return null;
  }
}
