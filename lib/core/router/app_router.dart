import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:kawangizi_mobile/features/auth/presentation/auth_controller.dart';
import 'package:kawangizi_mobile/features/auth/presentation/login_screen.dart';
import 'package:kawangizi_mobile/features/auth/presentation/welcome_screen.dart';
import 'package:kawangizi_mobile/features/shell/presentation/app_shell.dart';
import 'package:kawangizi_mobile/features/dashboard/presentation/dashboard_screen.dart';
import 'package:kawangizi_mobile/features/scanner/presentation/scanner_screen.dart';
import 'package:kawangizi_mobile/features/history/presentation/history_screen.dart';
import 'package:kawangizi_mobile/features/handover/presentation/handover_screen.dart';
import 'package:kawangizi_mobile/features/incident/presentation/incident_screen.dart';
import 'package:kawangizi_mobile/features/community/presentation/community_screen.dart';
import 'package:kawangizi_mobile/features/community/presentation/thread_detail_screen.dart';
import 'package:kawangizi_mobile/features/community/presentation/create_post_sheet.dart';
import 'package:kawangizi_mobile/features/profile/presentation/profile_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter(AuthController auth) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/welcome',
    refreshListenable: auth,
    routes: [
      GoRoute(
        path: '/welcome',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/login',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const LoginScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShell(
          navigationShell: navigationShell,
          auth: auth,
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (_, __) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/scanner',
                builder: (_, __) => const ScannerScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                builder: (_, __) => const HistoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/community',
                builder: (_, __) => const CommunityScreen(),
              ),
              GoRoute(
                path: '/community/thread/:id',
                builder: (context, state) => ThreadDetailScreen(
                  postId: state.pathParameters['id']!,
                ),
              ),
              GoRoute(
                path: '/community/create',
                builder: (context, _) => CreatePostSheet(
                  onClose: () => context.pop(),
                  onSubmit: () => context.pop(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (_, __) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/handover',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const HandoverScreen(),
      ),
      GoRoute(
        path: '/incident',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const IncidentScreen(),
      ),
    ],
    redirect: (context, state) {
      final loading = auth.loading;
      final user = auth.user;
      final location = state.matchedLocation;

      if (loading) {
        return null; // show splash/loading
      }

      final isLoggedIn = user != null;
      final isGuest = user?.isGuest == true;

      final isAuthPage = location == '/welcome' || location == '/login';

      if (!isLoggedIn) {
        return isAuthPage ? null : '/welcome';
      }

      if (isAuthPage) return '/';

      // Guest restrictions
      if (isGuest) {
        final allowed = ['/scanner', '/community', '/profile'];
        final isAllowed = allowed.any((p) => location.startsWith(p));
        if (!isAllowed) return '/scanner';
      }

      return null;
    },
  );
}
