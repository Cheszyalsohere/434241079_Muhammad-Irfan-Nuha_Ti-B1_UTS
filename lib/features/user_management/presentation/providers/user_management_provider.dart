/// Riverpod providers for the admin User Management feature.
///
/// Mirrors the project's standard layering:
///   • Infrastructure (`keepAlive`): datasource + repository
///   • Use case providers
///   • [UserSearchQuery] — `Notifier<String>` holding the list filter
///   • [UserManagementController] — `AsyncNotifier<List<UserEntity>>`
///     that loads the list (re-running when the search query changes)
///     and exposes `setRole` / `setActive` mutations that patch the
///     in-memory list optimistically.
///
/// Generated file: `user_management_provider.g.dart`.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/errors/failures.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/user_management_remote_datasource.dart';
import '../../data/repositories/user_management_repository_impl.dart';
import '../../domain/repositories/user_management_repository.dart';
import '../../domain/usecases/get_users_usecase.dart';
import '../../domain/usecases/set_user_active_usecase.dart';
import '../../domain/usecases/update_user_role_usecase.dart';

part 'user_management_provider.g.dart';

// ── Infrastructure ────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
UserManagementRemoteDataSource userManagementRemoteDataSource(
  UserManagementRemoteDataSourceRef ref,
) =>
    UserManagementRemoteDataSource(ref.watch(supabaseClientProvider));

@Riverpod(keepAlive: true)
UserManagementRepository userManagementRepository(
  UserManagementRepositoryRef ref,
) =>
    UserManagementRepositoryImpl(
      ref.watch(userManagementRemoteDataSourceProvider),
    );

// ── Use cases ─────────────────────────────────────────────────────────

@riverpod
GetUsersUseCase getUsersUseCase(GetUsersUseCaseRef ref) =>
    GetUsersUseCase(ref.watch(userManagementRepositoryProvider));

@riverpod
UpdateUserRoleUseCase updateUserRoleUseCase(UpdateUserRoleUseCaseRef ref) =>
    UpdateUserRoleUseCase(ref.watch(userManagementRepositoryProvider));

@riverpod
SetUserActiveUseCase setUserActiveUseCase(SetUserActiveUseCaseRef ref) =>
    SetUserActiveUseCase(ref.watch(userManagementRepositoryProvider));

// ── Search filter ─────────────────────────────────────────────────────

@riverpod
class UserSearchQuery extends _$UserSearchQuery {
  @override
  String build() => '';

  void set(String q) => state = q;
}

// ── Controller ────────────────────────────────────────────────────────

@riverpod
class UserManagementController extends _$UserManagementController {
  @override
  Future<List<UserEntity>> build() async {
    final String q = ref.watch(userSearchQueryProvider);
    return _fetch(q);
  }

  Future<List<UserEntity>> _fetch(String q) async {
    final res = await ref
        .read(getUsersUseCaseProvider)
        .call(search: q.trim().isEmpty ? null : q.trim());
    return res.fold((Failure f) => throw f, (List<UserEntity> list) => list);
  }

  Future<void> refresh() async {
    state = const AsyncLoading<List<UserEntity>>();
    state = await AsyncValue.guard<List<UserEntity>>(
      () => _fetch(ref.read(userSearchQueryProvider)),
    );
  }

  /// Change a user's role. Returns `(ok, error)` so the caller renders
  /// the failure message verbatim.
  Future<({bool ok, String? error})> setRole({
    required String userId,
    required UserRole role,
  }) async {
    final res = await ref
        .read(updateUserRoleUseCaseProvider)
        .call(userId: userId, role: role);
    return res.fold(
      (Failure f) => (ok: false, error: f.message),
      (UserEntity u) {
        _patch(u);
        return (ok: true, error: null);
      },
    );
  }

  /// Activate / deactivate a user. Returns `(ok, error)`.
  Future<({bool ok, String? error})> setActive({
    required String userId,
    required bool isActive,
  }) async {
    final res = await ref
        .read(setUserActiveUseCaseProvider)
        .call(userId: userId, isActive: isActive);
    return res.fold(
      (Failure f) => (ok: false, error: f.message),
      (UserEntity u) {
        _patch(u);
        return (ok: true, error: null);
      },
    );
  }

  /// Replace the matching row in the loaded list with [updated].
  void _patch(UserEntity updated) {
    final List<UserEntity>? cur = state.valueOrNull;
    if (cur == null) return;
    state = AsyncData<List<UserEntity>>(<UserEntity>[
      for (final UserEntity u in cur)
        if (u.id == updated.id) updated else u,
    ]);
  }
}
