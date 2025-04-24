import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:short_url_mobile/core/constant/route_constant.dart';
import 'package:short_url_mobile/core/helpers/app_transition_helper.dart';
import 'package:short_url_mobile/core/helpers/logger_helper.dart';
import 'package:short_url_mobile/core/helpers/route_observer_helper.dart';
import 'package:short_url_mobile/domain/repositories/auth_repository.dart';
import 'package:short_url_mobile/presentation/pages/home/home_page.dart';
import 'package:short_url_mobile/presentation/pages/login/login_page.dart';
import 'package:short_url_mobile/dependency.dart' as di;
import 'package:short_url_mobile/presentation/pages/not_found/not_found_page.dart';
import 'package:short_url_mobile/presentation/pages/setting/setting_page.dart';

class AppRouter {
  static final AuthRepository _authRepository = di.sl<AuthRepository>();
  static final LoggerUtil _logger = di.sl<LoggerUtil>();

  // Create router configuration
  static final GoRouter router = GoRouter(
    navigatorKey: di.navigatorKey,
    initialLocation: RouteConstants.root,
    debugLogDiagnostics: true, // Set to false in production
    observers: [AppRouteObserver()],
    errorBuilder: (context, state) => const NotFoundPage(),

    // Define redirect logic
    redirect: (BuildContext context, GoRouterState state) async {
      try {
        // Check if the user is authenticated using Either
        final authResult = await _authRepository.isLoggedIn();

        // Extract the boolean value using fold
        bool isLoggedIn = false;
        authResult.fold(
          (failure) {
            // On failure, assume not logged in
            _logger.error('Auth check failed: ${failure.message}');
            isLoggedIn = false;
          },
          (result) {
            // On success, use the result
            isLoggedIn = result;
          },
        );

        final bool isGoingToLogin =
            state.matchedLocation == RouteConstants.login;

        // If not logged in and not going to login, redirect to login
        if (!isLoggedIn && !isGoingToLogin) {
          return RouteConstants.login;
        }

        // If logged in and going to login, redirect to home
        if (isLoggedIn && isGoingToLogin) {
          return RouteConstants.dashboard;
        }

        // No redirect needed
        return null;
      } catch (e) {
        _logger.error('Error during navigation redirect: $e');
        // On error, redirect to login as a safe fallback
        return RouteConstants.login;
      }
    },

    // Define routes
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          // You can wrap child with scaffold with navigation drawer, bottom nav, etc.
          return Scaffold(
            body: child,
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _calculateSelectedIndex(state),
              onTap: (int idx) => _onItemTapped(idx, context),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard),
                  label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings),
                  label: 'Settings',
                ),
              ],
            ),
          );
        },
        routes: [
          // Dashboard route
          GoRoute(
            path: RouteConstants.dashboard,
            pageBuilder: (context, state) {
              return AppTransitionPage(
                key: state.pageKey,
                child: const HomePage(),
              );
            },
          ),
          // Settings route
          GoRoute(
            path: RouteConstants.settings,
            pageBuilder: (context, state) {
              return AppTransitionPage(
                key: state.pageKey,
                child: const SettingPage(),
              );
            },
          ),
        ],
      ),

      GoRoute(
        // name: home,
        path: RouteConstants.root,
        redirect: (_, __) => RouteConstants.dashboard,
      ),
      GoRoute(
        // name: login,
        path: RouteConstants.login,
        builder: (context, state) => const LoginPage(),
      ),
    ],
  );

  static int _calculateSelectedIndex(GoRouterState state) {
    final String location = state.matchedLocation;
    if (location.startsWith(RouteConstants.dashboard)) {
      return 0;
    }
    if (location.startsWith(RouteConstants.settings)) {
      return 1;
    }
    return 0;
  }

  static void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        GoRouter.of(context).go(RouteConstants.dashboard);
        break;
      case 1:
        GoRouter.of(context).go(RouteConstants.settings);
        break;
    }
  }
}
