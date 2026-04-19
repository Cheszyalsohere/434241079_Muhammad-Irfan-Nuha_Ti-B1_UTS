/// Riverpod `@riverpod` providers for auth state + operations.
///
/// Hierarchy:
///   • [supabaseClient]      — singleton handle to `Supabase.instance.client`
///   • [authRemoteDataSource]/[authRepository] — DI seams
///   • Use case providers    — one per use case
///   • [authState]           — `Stream<UserEntity?>` of session changes
///   • [currentUser]         — `AsyncValue<UserEntity?>` derived from the stream
///   • [AuthController]      — imperative `login` / `register` / `logout` /
///                             `resetPassword` exposed to screens; tracks
///                             a `Future<void>` so screens can show loading.
///
/// Generated file `auth_provider.g.dart` is produced by
/// `dart run build_runner build`.
library;

import 'package:dartz/dartz.dart' show Either, Unit;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/errors/failures.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/reset_password_usecase.dart';

part 'auth_provider.g.dart';

// ── Infrastructure ────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
sb.SupabaseClient supabaseClient(SupabaseClientRef ref) =>
    sb.Supabase.instance.client;

@Riverpod(keepAlive: true)
AuthRemoteDataSource authRemoteDataSource(AuthRemoteDataSourceRef ref) =>
    AuthRemoteDataSource(ref.watch(supabaseClientProvider));

@Riverpod(keepAlive: true)
AuthRepository authRepository(AuthRepositoryRef ref) =>
    AuthRepositoryImpl(ref.watch(authRemoteDataSourceProvider));

// ── Use cases ─────────────────────────────────────────────────────────

@riverpod
LoginUseCase loginUseCase(LoginUseCaseRef ref) =>
    LoginUseCase(ref.watch(authRepositoryProvider));

@riverpod
RegisterUseCase registerUseCase(RegisterUseCaseRef ref) =>
    RegisterUseCase(ref.watch(authRepositoryProvider));

@riverpod
LogoutUseCase logoutUseCase(LogoutUseCaseRef ref) =>
    LogoutUseCase(ref.watch(authRepositoryProvider));

@riverpod
ResetPasswordUseCase resetPasswordUseCase(ResetPasswordUseCaseRef ref) =>
    ResetPasswordUseCase(ref.watch(authRepositoryProvider));

// ── State ─────────────────────────────────────────────────────────────

/// Live auth state. Emits the current user (or `null`) on subscribe and
/// every Supabase auth event afterwards.
@Riverpod(keepAlive: true)
Stream<UserEntity?> authState(AuthStateRef ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
}

/// Convenience wrapper turning the stream into an `AsyncValue` for
/// screens that just want `when()` UI.
@Riverpod(keepAlive: true)
AsyncValue<UserEntity?> currentUser(CurrentUserRef ref) {
  return ref.watch(authStateProvider);
}

// ── Mutation controller ───────────────────────────────────────────────

/// Tracks the outcome of the most recent auth mutation.
///
/// State semantics:
///   • `AsyncData(null)`  — idle (no mutation in flight, no recent error)
///   • `AsyncLoading()`   — mutation in progress
///   • `AsyncError`       — last mutation failed; `error` is a [Failure]
///   • `AsyncData(value)` — last mutation succeeded; opaque marker string
///     ('login' | 'register' | 'logout' | 'reset') so screens can react.
@riverpod
class AuthController extends _$AuthController {
  @override
  FutureOr<String?> build() => null;

  Future<bool> login({required String email, required String password}) async {
    state = const AsyncLoading<String?>();
    final Either<Failure, UserEntity> result =
        await ref.read(loginUseCaseProvider).call(
              email: email,
              password: password,
            );
    return result.fold(
      (Failure f) {
        state = AsyncError<String?>(f, StackTrace.current);
        return false;
      },
      (UserEntity _) {
        state = const AsyncData<String?>('login');
        return true;
      },
    );
  }

  Future<bool> register({
    required String email,
    required String password,
    required String username,
    required String fullName,
  }) async {
    state = const AsyncLoading<String?>();
    final Either<Failure, UserEntity> result =
        await ref.read(registerUseCaseProvider).call(
              email: email,
              password: password,
              username: username,
              fullName: fullName,
            );
    return result.fold(
      (Failure f) {
        state = AsyncError<String?>(f, StackTrace.current);
        return false;
      },
      (UserEntity _) {
        state = const AsyncData<String?>('register');
        return true;
      },
    );
  }

  Future<bool> logout() async {
    state = const AsyncLoading<String?>();
    final Either<Failure, Unit> result =
        await ref.read(logoutUseCaseProvider).call();
    return result.fold(
      (Failure f) {
        state = AsyncError<String?>(f, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncData<String?>('logout');
        return true;
      },
    );
  }

  Future<bool> resetPassword({required String email}) async {
    state = const AsyncLoading<String?>();
    final Either<Failure, Unit> result =
        await ref.read(resetPasswordUseCaseProvider).call(email: email);
    return result.fold(
      (Failure f) {
        state = AsyncError<String?>(f, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncData<String?>('reset');
        return true;
      },
    );
  }

  /// Reset the controller back to idle (e.g. after the screen consumes
  /// a success notification or an error snackbar).
  void clear() => state = const AsyncData<String?>(null);
}
