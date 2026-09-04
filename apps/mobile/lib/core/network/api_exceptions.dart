class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class NetworkException extends ApiException {
  NetworkException() : super('No internet connection or API is offline.');
}

class RateLimitException extends ApiException {
  RateLimitException([
    super.message = 'Too many failed attempts. Try again later.',
  ]) : super(statusCode: 429);
}

class UnauthorizedException extends ApiException {
  UnauthorizedException()
    : super('Unauthorized. Invalid or expired token.', statusCode: 401);
}

class ConflictException extends ApiException {
  ConflictException(super.message) : super(statusCode: 409);
}

class ForbiddenException extends ApiException {
  ForbiddenException()
    : super(
        'Forbidden. You do not have permission to perform this action.',
        statusCode: 403,
      );
}
