/// Use case: upload [bytes] as the user's avatar and persist the URL.
///
/// Pass `clear: true` (and skip [bytes]) to remove the current avatar.
library;

import 'dart:typed_data';

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../repositories/profile_repository.dart';

class UploadAvatarUseCase {
  const UploadAvatarUseCase(this._repo);

  final ProfileRepository _repo;

  Future<Either<Failure, UserEntity>> call({
    required String userId,
    Uint8List? bytes,
    String extension = 'jpg',
    bool clear = false,
  }) {
    if (clear) return _repo.clearAvatar(userId);
    if (bytes == null || bytes.isEmpty) {
      return Future<Either<Failure, UserEntity>>.value(
        const Left<Failure, UserEntity>(
          ValidationFailure('File avatar kosong.'),
        ),
      );
    }
    return _repo.uploadAvatar(
      userId: userId,
      bytes: bytes,
      extension: extension,
    );
  }
}
