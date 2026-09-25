abstract class AppException implements Exception {
  const AppException(
    this.message, {
    this.code,
    this.statusCode,
    this.cause,
  });

  final String message;
  final String? code;
  final int? statusCode;
  final Object? cause;

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  const NetworkException(super.message, {super.code, super.statusCode, super.cause});
}

class UnauthorizedException extends NetworkException {
  const UnauthorizedException(super.message, {super.code, super.cause})
      : super(statusCode: 401);
}

class ServerException extends NetworkException {
  const ServerException(super.message, {super.code, super.statusCode, super.cause});
}
