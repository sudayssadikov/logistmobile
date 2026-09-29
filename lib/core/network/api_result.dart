import 'api_exceptions.dart';

/// Standard Result wrapper for functional error handling in clean architecture
sealed class ApiResult<T> {
  const ApiResult();

  bool get isSuccess => this is ApiSuccess<T>;
  bool get isFailure => this is ApiFailure<T>;

  T? get dataOrNull => this is ApiSuccess<T> ? (this as ApiSuccess<T>).data : null;
  String? get errorOrNull => this is ApiFailure<T> ? (this as ApiFailure<T>).message : null;

  R when<R>({
    required R Function(T data) success,
    required R Function(String message, int? statusCode, dynamic errorData) failure,
  }) {
    if (this is ApiSuccess<T>) {
      return success((this as ApiSuccess<T>).data);
    } else if (this is ApiFailure<T>) {
      final fail = this as ApiFailure<T>;
      return failure(fail.message, fail.statusCode, fail.errorData);
    }
    throw StateError('Unknown ApiResult state: $this');
  }
}

class ApiSuccess<T> extends ApiResult<T> {
  final T data;
  const ApiSuccess(this.data);
}

class ApiFailure<T> extends ApiResult<T> {
  final String message;
  final int? statusCode;
  final dynamic errorData;

  const ApiFailure({
    required this.message,
    this.statusCode,
    this.errorData,
  });

  factory ApiFailure.fromException(ApiException exception) {
    return ApiFailure(
      message: exception.message,
      statusCode: exception.statusCode,
      errorData: exception.data,
    );
  }
}
