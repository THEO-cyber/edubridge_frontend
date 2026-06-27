class ApiException implements Exception {
  final String message;
  final int? code;
  ApiException(this.message, [this.code]);

  @override
  String toString() => 'ApiException: $message (code: $code)';
}

class NetworkException extends ApiException {
  NetworkException(super.message);
}

class UnauthorizedException extends ApiException {
  UnauthorizedException(super.message);
}

class NotFoundException extends ApiException {
  NotFoundException(super.message);
}

class ValidationException extends ApiException {
  ValidationException(super.message);
}

class Requires2FAException implements Exception {
  final String tempToken;
  Requires2FAException(this.tempToken);
}
