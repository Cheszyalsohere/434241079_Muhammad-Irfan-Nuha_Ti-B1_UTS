/// Domain-level failure types returned via `Either<Failure, T>`. Each
/// carries a user-friendly Indonesian message suitable for display.
library;

/// Base failure.
sealed class Failure {
  const Failure(this.message);

  /// User-facing message (Indonesian).
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

final class ServerFailure extends Failure {
  const ServerFailure([
    super.message = 'Terjadi kesalahan pada server. Coba lagi nanti.',
  ]);
}

final class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = 'Tidak ada koneksi internet. Periksa jaringan Anda.',
  ]);
}

final class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Email atau kata sandi salah.']);
}

final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Data tidak ditemukan.']);
}

final class PermissionFailure extends Failure {
  const PermissionFailure([
    super.message = 'Anda tidak memiliki akses untuk tindakan ini.',
  ]);
}

final class UnknownFailure extends Failure {
  const UnknownFailure([
    super.message = 'Terjadi kesalahan tak terduga. Coba lagi.',
  ]);
}
