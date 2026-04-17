/// `go_router` configuration with auth-aware redirect.
///
/// Routes: /splash, /login, /register, /reset-password, /dashboard,
/// /tickets, /tickets/create, /tickets/:id, /notifications, /profile.
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
import '../../features/notification/presentation/screens/notification_screen.dart';
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
  static const String notifications = '/notifications';
  static const String profile = '/profile';

  static const Set<String> publicPaths = <String>{
    splash,
    login,
    register,
    resetPassword,
  };
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
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        builder: (_, __) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (_, __) => const DashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.tickets,
        builder: (_, __) => const TicketListScreen(),
        routes: <RouteBase>[
          GoRoute(
            path: 'create',
            builder: (_, __) => const CreateTicketScreen(),
          ),
          GoRoute(
            path: ':id',
            builder: (BuildContext _, GoRouterState state) =>
                TicketDetailScreen(ticketId: state.pathParameters['id'] ?? ''),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (_, __) => const NotificationScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (_, __) => const ProfileScreen(),
      ),
    ],
    errorBuilder: (BuildContext _, GoRouterState state) => Scaffold(
      appBar: AppBar(title: const Text('Halaman tidak ditemukan')),
      body: Center(child: Text('Route tidak dikenali: ${state.matchedLocation}')),
    ),
  );
}
