/// Riverpod providers for the dashboard feature.
///
/// Hierarchy:
///   • [dashboardRemoteDataSource] / [dashboardRepository] — DI seams,
///     keepAlive so they survive screen disposal
///   • Three role-specific use case providers
///   • [DashboardController] — async [DashboardStats] state. The
///     controller picks the right use case based on the current
///     user's [UserRole] and exposes a `refresh()` for pull-to-refresh
///
/// Generated file: `dashboard_provider.g.dart`.
library;

import 'package:dartz/dartz.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/errors/failures.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/dashboard_remote_datasource.dart';
import '../../data/repositories/dashboard_repository_impl.dart';
import '../../domain/entities/dashboard_stats_entity.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../../domain/usecases/get_admin_dashboard_usecase.dart';
import '../../domain/usecases/get_helpdesk_dashboard_usecase.dart';
import '../../domain/usecases/get_user_dashboard_usecase.dart';

part 'dashboard_provider.g.dart';

// ── Infrastructure ────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
DashboardRemoteDataSource dashboardRemoteDataSource(
  DashboardRemoteDataSourceRef ref,
) =>
    DashboardRemoteDataSource(ref.watch(supabaseClientProvider));

@Riverpod(keepAlive: true)
DashboardRepository dashboardRepository(DashboardRepositoryRef ref) =>
    DashboardRepositoryImpl(ref.watch(dashboardRemoteDataSourceProvider));

// ── Use cases ─────────────────────────────────────────────────────────

@riverpod
GetAdminDashboardUseCase getAdminDashboardUseCase(
  GetAdminDashboardUseCaseRef ref,
) =>
    GetAdminDashboardUseCase(ref.watch(dashboardRepositoryProvider));

@riverpod
GetHelpdeskDashboardUseCase getHelpdeskDashboardUseCase(
  GetHelpdeskDashboardUseCaseRef ref,
) =>
    GetHelpdeskDashboardUseCase(ref.watch(dashboardRepositoryProvider));

@riverpod
GetUserDashboardUseCase getUserDashboardUseCase(
  GetUserDashboardUseCaseRef ref,
) =>
    GetUserDashboardUseCase(ref.watch(dashboardRepositoryProvider));

// ── Controller ────────────────────────────────────────────────────────

/// Async [DashboardStats] for the dashboard screen.
///
/// `build()` reads the current user's role and dispatches to the
/// matching role-specific use case. `refresh()` simply re-runs the
/// same dispatch — bound to pull-to-refresh.
@riverpod
class DashboardController extends _$DashboardController {
  @override
  Future<DashboardStats> build() => _load();

  Future<void> refresh() async {
    state = const AsyncLoading<DashboardStats>();
    state = await AsyncValue.guard<DashboardStats>(_load);
  }

  /// Single source of truth for "fetch the right stats for this role".
  /// Re-watching `currentUserProvider` here means a sign-out/sign-in
  /// during the session rebuilds the controller automatically.
  Future<DashboardStats> _load() async {
    final UserEntity? user = ref.watch(currentUserProvider).valueOrNull;
    if (user == null) {
      // Auth controller will redirect; surface an empty stat snapshot
      // so the dashboard doesn't try to render mid-tear-down.
      return DashboardStats.empty();
    }

    final Either<Failure, DashboardStats> res;
    switch (user.role) {
      case UserRole.admin:
        res = await ref.read(getAdminDashboardUseCaseProvider).call();
      case UserRole.helpdesk:
        res = await ref
            .read(getHelpdeskDashboardUseCaseProvider)
            .call(userId: user.id);
      case UserRole.user:
        res = await ref
            .read(getUserDashboardUseCaseProvider)
            .call(userId: user.id);
    }

    return res.fold(
      (Failure f) => throw f,
      (DashboardStats s) => s,
    );
  }
}
