/// Abstract [ProfileRepository] — domain contract for Phase 7.
///
/// Wraps profile reads, profile field updates, avatar upload, and
/// password change. Returns `Either<Failure, T>` so the presentation
/// layer never deals in raw exceptions.
///
/// We deliberately reuse [UserEntity] from the auth feature instead of
/// inventing a `ProfileEntity` — the same row backs both sessions and
/// the profile screen, and divergent shapes would only invite drift.
library;

import 'dart:typed_data';

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../auth/domain/entities/user_entity.dart';

abstract interface class ProfileRepository {
  /// Load the latest profile for [userId].
  Future<Either<Failure, UserEntity>> getProfile(String userId);

  /// Save edited display fields.
  Future<Either<Failure, UserEntity>> updateProfile({
    required String userId,
    required String fullName,
    required String username,
  });

  /// Upload [bytes] as the avatar and persist the resulting URL on the
  /// profile row. Returns the refreshed [UserEntity] (with the new
  /// `avatarUrl`).
  Future<Either<Failure, UserEntity>> uploadAvatar({
    required String userId,
    required Uint8List bytes,
    String extension,
  });

  /// Clear the current avatar (sets `avatar_url = null`).
  Future<Either<Failure, UserEntity>> clearAvatar(String userId);

  /// Update the signed-in user's password via Supabase Auth.
  Future<Either<Failure, Unit>> changePassword(String newPassword);
}
