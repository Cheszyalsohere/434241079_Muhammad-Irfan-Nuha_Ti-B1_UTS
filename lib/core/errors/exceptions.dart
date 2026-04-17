/// Data-layer exceptions thrown by remote datasources. Repositories
/// catch these and map them to [Failure] before returning
/// `Either<Failure, T>`.
library;

/// Base class — never thrown directly.
sealed class AppException implements Exception {
  const AppException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message';
}

/// Server or database error (non-2xx, RLS denial, constraint violation).
final class ServerException extends AppException {
  const ServerException(super.message, {super.cause, this.statusCode});
  final int? statusCode;
}

/// Network transport error (no connection, timeout, DNS).
final class NetworkException extends AppException {
  const NetworkException(super.message, {super.cause});
}

/// Auth-specific error (invalid credentials, expired session, user
/// already exists, etc.).
final class AuthException extends AppException {
  const AuthException(super.message, {super.cause});
}

/// Local storage / serialization error.
final class CacheException extends AppException {
  const CacheException(super.message, {super.cause});
}

/// Business-rule violation surfaced before hitting the server.
final class ValidationException extends AppException {
  const ValidationException(super.message, {super.cause});
}
