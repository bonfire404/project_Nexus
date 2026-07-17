import 'package:go_router/go_router.dart';
import 'package:nexus/app/theme_controller.dart';
import 'package:nexus/features/auth/presentation/providers/auth_controller.dart';
import 'package:nexus/features/auth/presentation/screens/splash_screen.dart';
import 'package:nexus/features/auth/presentation/screens/role_selection_screen.dart';
import 'package:nexus/features/auth/presentation/screens/login_screen.dart';
import 'package:nexus/features/dashboard/presentation/screens/home_screen.dart';

/// Declarative router with auth-aware redirects.
class NexusRouter {
  NexusRouter._();

  /// Route paths
  static const String splash = '/splash';
  static const String roleSelect = '/role-select';
  static const String login = '/login';
  static const String home = '/home';

  /// Creates the GoRouter instance bound to [authController].
  static GoRouter create(
    AuthController authController, {
    ThemeController? themeController,
  }) {
    // Track splash completion
    bool splashDone = false;

    return GoRouter(
      initialLocation: splash,
      refreshListenable: authController,
      redirect: (context, state) {
        final isAuthenticated = authController.isAuthenticated;
        final hasRole = authController.selectedRole != null;
        final currentPath = state.matchedLocation;

        // Let splash finish first
        if (!splashDone && currentPath == splash) return null;

        // After splash or if navigating away from splash
        if (isAuthenticated) {
          // Already logged in — go home
          if (currentPath != home) return home;
          return null;
        }

        if (!hasRole) {
          // No role selected — go to role selection
          if (currentPath != roleSelect) return roleSelect;
          return null;
        }

        // Has role, not authenticated — go to login
        if (currentPath != login) return login;
        return null;
      },
      routes: [
        GoRoute(
          path: splash,
          builder: (context, state) => SplashScreen(
            onInitialized: () {
              splashDone = true;
              // Trigger a redirect evaluation
              authController.signalChange();
            },
          ),
        ),
        GoRoute(
          path: roleSelect,
          builder: (context, state) => RoleSelectionScreen(
            onRoleSelected: (role) {
              authController.selectRole(role);
            },
          ),
        ),
        GoRoute(
          path: login,
          builder: (context, state) => LoginScreen(
            authController: authController,
          ),
        ),
        GoRoute(
          path: home,
          builder: (context, state) => HomeScreen(
            authController: authController,
            themeController: themeController,
          ),
        ),
      ],
    );
  }
}
