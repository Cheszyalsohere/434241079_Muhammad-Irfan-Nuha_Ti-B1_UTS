/// `go_router` configuration with auth-aware redirect.
///
/// Routes: /splash, /login, /register, /reset-password, /dashboard,
/// /tickets, /tickets/create, /tickets/:id, /history, /notifications,
/// /profile.
///
/// The router listens to Supabase auth state via a [ChangeNotifier]
/// adapter so redirects fire whenever the session changes
/// (sign-in / sign-out).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/history/presentation/screens/history_screen.dart';
import '../../features/notification/presentation/screens/notification_screen.dart';
import '../../features/profile/presentation/screens/change_password_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/ticket/presentation/screens/create_ticket_screen.dart';
import '../../features/ticket/presentation/screens/ticket_detail_screen.dart';
import '../../features/ticket/presentation/screens/ticket_list_screen.dart';

/// Route names kept as constants to avoid magic strings.
abstract final class AppRoutes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String resetPassword = '/reset-password';
  static const String dashboard = '/dashboard';
  static const String tickets = '/tickets';
  static const String ticketCreate = '/tickets/create';
  static const String ticketDetail = '/tickets/:id';
  static const String history = '/history';
  static const String notifications = '/notifications';
  static const String profile = '/profile';
  static const String changePassword = '/profile/change-password';

  static const Set<String> publicPaths = <String>{
    splash,
    login,
    register,
    resetPassword,
  };
}

/// Wraps a route's [child] in a 200ms fade transition. Used as the
/// uniform `pageBuilder` for every [GoRoute] so route changes feel
/// consistent across the app.
CustomTransitionPage<void> _fadePage({
  required Widget child,
  LocalKey? key,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 200),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (
      BuildContext _,
      Animation<double> animation,
      Animation<double> __,
      Widget child,
    ) =>
        FadeTransition(opacity: animation, child: child),
  );
}

/// Adapts `Stream<AuthState>` into a `Listenable` for `go_router`'s
/// `refreshListenable` so auth changes trigger a redirect re-evaluation.
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Stream<AuthState> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<AuthState> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

GoRouter buildRouter() {
  final _AuthRefreshNotifier refresh = _AuthRefreshNotifier(
    Supabase.instance.client.auth.onAuthStateChange,
  );

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (BuildContext context, GoRouterState state) {
      final Session? session = Supabase.instance.client.auth.currentSession;
      final bool loggedIn = session != null;
      final String loc = state.matchedLocation;
      final bool isPublic = AppRoutes.publicPaths.contains(loc);

      // Splash manages its own navigation once the min delay elapses.
      if (loc == AppRoutes.splash) return null;

      if (!loggedIn && !isPublic) return AppRoutes.login;
      if (loggedIn && isPublic) return AppRoutes.dashboard;
      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (_, GoRouterState state) =>
            _fadePage(key: state.pageKey, child: const SplashScreen()),
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (_, GoRouterState state) =>
            _fadePage(key: state.pageKey, child: const LoginScreen()),
      ),
      GoRoute(
        path: AppRoutes.register,
        pageBuilder: (_, GoRouterState state) =>
            _fadePage(key: state.pageKey, child: const RegisterScreen()),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        pageBuilder: (_, GoRouterState state) =>
            _fadePage(key: state.pageKey, child: const ResetPasswordScreen()),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        pageBuilder: (_, GoRouterState state) =>
            _fadePage(key: state.pageKey, child: const DashboardScreen()),
      ),
      GoRoute(
        path: AppRoutes.tickets,
        pageBuilder: (_, GoRouterState state) =>
            _fadePage(key: state.pageKey, child: const TicketListScreen()),
        routes: <RouteBase>[
          GoRoute(
            path: 'create',
            pageBuilder: (_, GoRouterState state) => _fadePage(
              key: state.pageKey,
              child: const CreateTicketScreen(),
            ),
          ),
          GoRoute(
            path: ':id',
            pageBuilder: (_, GoRouterState state) => _fadePage(
              key: state.pageKey,
              child: TicketDetailScreen(
                ticketId: state.pathParameters['id'] ?? '',
              ),
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.history,
        pageBuilder: (_, GoRouterState state) =>
            _fadePage(key: state.pageKey, child: const HistoryScreen()),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        pageBuilder: (_, GoRouterState state) =>
            _fadePage(key: state.pageKey, child: const NotificationScreen()),
      ),
      GoRoute(
        path: AppRoutes.profile,
        pageBuilder: (_, GoRouterState state) =>
            _fadePage(key: state.pageKey, child: const ProfileScreen()),
        routes: <RouteBase>[
          GoRoute(
            path: 'change-password',
            pageBuilder: (_, GoRouterState state) => _fadePage(
              key: state.pageKey,
              child: const ChangePasswordScreen(),
            ),
          ),
        ],
      ),
    ],
    errorBuilder: (BuildContext _, GoRouterState state) => Scaffold(
      appBar: AppBar(title: const Text('Halaman tidak ditemukan')),
      body: Center(child: Text('Route tidak dikenali: ${state.matchedLocation}')),
    ),
  );
}
