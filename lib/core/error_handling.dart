class ApiException implements Exception {
  final String message;
  final int? code;
  ApiException(this.message, [this.code]);

  @override
  String toString() => 'ApiException: $message (code: $code)';
}

class NetworkException extends ApiException {
  NetworkException(String message) : super(message);
}

class UnauthorizedException extends ApiException {
  UnauthorizedException(String message) : super(message);
}

class NotFoundException extends ApiException {
  NotFoundException(String message) : super(message);
}

class ValidationException extends ApiException {
  ValidationException(String message) : super(message);
}

class Requires2FAException implements Exception {
  final String tempToken;
  Requires2FAException(this.tempToken);
}
