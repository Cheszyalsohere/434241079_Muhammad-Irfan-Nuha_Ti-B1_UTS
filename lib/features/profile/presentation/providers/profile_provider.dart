/// Riverpod providers for the Profile feature (Phase 7).
///
/// Hierarchy:
///   • Infrastructure (`@Riverpod(keepAlive: true)`):
///       - [profileRemoteDataSource]
///       - [profileRepository]
///   • Use case providers — one per use case.
///   • [ProfileController] — `AsyncNotifier<UserEntity?>` that exposes
///     imperative `refresh / updateProfile / uploadAvatar /
///     clearAvatar / changePassword` methods.
///   • [isEditingProfile] — `Notifier<bool>` toggling the edit-mode
///     UI on the profile screen.
///   • [isUploadingAvatar] — `Notifier<bool>` for the avatar overlay.
///
/// Generated file: `profile_provider.g.dart`.
library;

import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/errors/failures.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/profile_remote_datasource.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/usecases/change_password_usecase.dart';
import '../../domain/usecases/get_profile_usecase.dart';
import '../../domain/usecases/update_profile_usecase.dart';
import '../../domain/usecases/upload_avatar_usecase.dart';

part 'profile_provider.g.dart';

// ── Infrastructure ────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
ProfileRemoteDataSource profileRemoteDataSource(
  ProfileRemoteDataSourceRef ref,
) =>
    ProfileRemoteDataSource(ref.watch(supabaseClientProvider));

@Riverpod(keepAlive: true)
ProfileRepository profileRepository(ProfileRepositoryRef ref) =>
    ProfileRepositoryImpl(ref.watch(profileRemoteDataSourceProvider));

// ── Use cases ─────────────────────────────────────────────────────────

@riverpod
GetProfileUseCase getProfileUseCase(GetProfileUseCaseRef ref) =>
    GetProfileUseCase(ref.watch(profileRepositoryProvider));

@riverpod
UpdateProfileUseCase updateProfileUseCase(UpdateProfileUseCaseRef ref) =>
    UpdateProfileUseCase(ref.watch(profileRepositoryProvider));

@riverpod
UploadAvatarUseCase uploadAvatarUseCase(UploadAvatarUseCaseRef ref) =>
    UploadAvatarUseCase(ref.watch(profileRepositoryProvider));

@riverpod
ChangePasswordUseCase changePasswordUseCase(ChangePasswordUseCaseRef ref) =>
    ChangePasswordUseCase(ref.watch(profileRepositoryProvider));

// ── Edit-mode flags ───────────────────────────────────────────────────

/// Whether the profile screen is in edit mode (`true` ⇒ form fields
/// visible, save/cancel buttons shown).
@riverpod
class IsEditingProfile extends _$IsEditingProfile {
  @override
  bool build() => false;

  void enter() => state = true;
  void exit() => state = false;
  // ignore: avoid_positional_boolean_parameters
  void set(bool value) => state = value;
}

/// Whether an avatar upload is currently in flight (drives the
/// CircularProgressIndicator overlay on top of the avatar).
@riverpod
class IsUploadingAvatar extends _$IsUploadingAvatar {
  @override
  bool build() => false;

  // ignore: avoid_positional_boolean_parameters
  void set(bool value) => state = value;
}

// ── Controller ────────────────────────────────────────────────────────

/// Async controller for the profile screen.
///
/// `build()` derives the initial state from [currentUserProvider] —
/// the auth stream is the source of truth for the active session, so
/// the profile screen always opens with the same user the rest of the
/// app sees. Mutations refresh both this controller and the auth
/// session entity (the latter is what powers `currentUserProvider`).
@riverpod
class ProfileController extends _$ProfileController {
  @override
  Future<UserEntity?> build() async {
    final UserEntity? me = ref.watch(currentUserProvider).valueOrNull;
    if (me == null) return null;
    // Read-through to the latest DB row so the screen shows fresh data
    // even if the auth-stream entity is stale (e.g. avatar updated
    // from another device).
    final Either<Failure, UserEntity> res =
        await ref.read(getProfileUseCaseProvider).call(me.id);
    return res.fold(
      (Failure f) => throw f,
      (UserEntity u) => u,
    );
  }

  /// Force a re-read from the network.
  Future<void> refresh() async {
    state = const AsyncLoading<UserEntity?>();
    state = await AsyncValue.guard<UserEntity?>(() async {
      final UserEntity? me = ref.read(currentUserProvider).valueOrNull;
      if (me == null) return null;
      final Either<Failure, UserEntity> res =
          await ref.read(getProfileUseCaseProvider).call(me.id);
      return res.fold(
        (Failure f) => throw f,
        (UserEntity u) => u,
      );
    });
  }

  /// Update display fields. Returns `true` on success.
  Future<bool> updateProfile({
    required String fullName,
    required String username,
  }) async {
    final UserEntity? me = state.valueOrNull;
    if (me == null) return false;
    state = const AsyncLoading<UserEntity?>();
    final Either<Failure, UserEntity> res =
        await ref.read(updateProfileUseCaseProvider).call(
              userId: me.id,
              fullName: fullName.trim(),
              username: username.trim(),
            );
    return res.fold(
      (Failure f) {
        state = AsyncError<UserEntity?>(f, StackTrace.current);
        return false;
      },
      (UserEntity u) {
        state = AsyncData<UserEntity?>(u);
        return true;
      },
    );
  }

  /// Upload [bytes] as the avatar. Returns `true` on success. Caller
  /// is responsible for toggling [isUploadingAvatarProvider].
  Future<bool> uploadAvatar({
    required Uint8List bytes,
    String extension = 'jpg',
  }) async {
    final UserEntity? me = state.valueOrNull;
    if (me == null) return false;
    final Either<Failure, UserEntity> res =
        await ref.read(uploadAvatarUseCaseProvider).call(
              userId: me.id,
              bytes: bytes,
              extension: extension,
            );
    return res.fold(
      (Failure f) {
        state = AsyncError<UserEntity?>(f, StackTrace.current);
        return false;
      },
      (UserEntity u) {
        state = AsyncData<UserEntity?>(u);
        return true;
      },
    );
  }

  /// Remove the current avatar.
  Future<bool> clearAvatar() async {
    final UserEntity? me = state.valueOrNull;
    if (me == null) return false;
    final Either<Failure, UserEntity> res =
        await ref.read(uploadAvatarUseCaseProvider).call(
              userId: me.id,
              clear: true,
            );
    return res.fold(
      (Failure f) {
        state = AsyncError<UserEntity?>(f, StackTrace.current);
        return false;
      },
      (UserEntity u) {
        state = AsyncData<UserEntity?>(u);
        return true;
      },
    );
  }

  /// Change the signed-in user's password. Returns `(success, message)`
  /// so the caller can render either a success snackbar or the
  /// failure message verbatim without inspecting the controller state.
  Future<({bool ok, String? error})> changePassword(String newPassword) async {
    final Either<Failure, Unit> res =
        await ref.read(changePasswordUseCaseProvider).call(newPassword);
    return res.fold(
      (Failure f) => (ok: false, error: f.message),
      (_) => (ok: true, error: null),
    );
  }
}
