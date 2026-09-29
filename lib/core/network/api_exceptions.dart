import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode;
  final dynamic data;

  const ApiException({
    required this.message,
    this.statusCode,
    this.errorCode,
    this.data,
  });

  factory ApiException.fromDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
          message: 'Connection timed out. Please check your internet connection.',
          errorCode: 'TIMEOUT',
        );
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final responseData = error.response?.data;
        String errorMessage = 'An unexpected server error occurred.';
        String? errCode;

        if (responseData is Map<String, dynamic>) {
          errorMessage = responseData['message'] as String? ??
              responseData['detail'] as String? ??
              errorMessage;
          errCode = responseData['error_code'] as String?;
        }

        switch (statusCode) {
          case 400:
            return ApiException(
              message: errorMessage,
              statusCode: 400,
              errorCode: errCode ?? 'BAD_REQUEST',
              data: responseData,
            );
          case 401:
            return const ApiException(
              message: 'Session expired or unauthorized. Please log in again.',
              statusCode: 401,
              errorCode: 'UNAUTHORIZED',
            );
          case 403:
            return const ApiException(
              message: 'You do not have permission to perform this action.',
              statusCode: 403,
              errorCode: 'FORBIDDEN',
            );
          case 404:
            return ApiException(
              message: errorMessage.isNotEmpty ? errorMessage : 'Requested resource not found.',
              statusCode: 404,
              errorCode: 'NOT_FOUND',
            );
          case 422:
            return ApiException(
              message: 'Invalid input data. Please check the form fields.',
              statusCode: 422,
              errorCode: 'VALIDATION_ERROR',
              data: responseData,
            );
          case 500:
          case 502:
          case 503:
            return const ApiException(
              message: 'Server is currently unavailable. Please try again later.',
              statusCode: 500,
              errorCode: 'SERVER_ERROR',
            );
          default:
            return ApiException(
              message: errorMessage,
              statusCode: statusCode,
              errorCode: errCode,
              data: responseData,
            );
        }
      case DioExceptionType.cancel:
        return const ApiException(message: 'Request was cancelled.', errorCode: 'CANCELLED');
      case DioExceptionType.connectionError:
      default:
        return const ApiException(
          message: 'No internet connection detected. Working in offline mode.',
          errorCode: 'NO_CONNECTION',
        );
    }
  }

  @override
  String toString() => 'ApiException: [$errorCode] $message (Status: $statusCode)';
}
