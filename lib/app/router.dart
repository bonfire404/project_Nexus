import 'package:go_router/go_router.dart';
import 'package:nexus/features/auth/presentation/providers/auth_controller.dart';
import 'package:nexus/features/auth/presentation/screens/splash_screen.dart';
import 'package:nexus/features/auth/presentation/screens/role_selection_screen.dart';
import 'package:nexus/features/auth/presentation/screens/login_screen.dart';
import 'package:nexus/features/dashboard/presentation/screens/home_screen.dart';
import 'package:nexus/features/programs/presentation/screens/program_listing_screen.dart';
import 'package:nexus/features/programs/presentation/screens/program_details_screen.dart';

/// Declarative router with auth-aware redirects.
class NexusRouter {
  NexusRouter._();

  /// Route paths
  static const String splash = '/splash';
  static const String roleSelect = '/role-select';
  static const String login = '/login';
  static const String home = '/home';
  static const String programs = '/programs';
  static const String programDetails = '/programs/:id';

  /// Creates the GoRouter instance bound to [authController].
  static GoRouter create(AuthController authController) {
    // Track splash completion
    bool splashDone = false;

    return GoRouter(
      initialLocation: splash,
      refreshListenable: authController,
      redirect: (context, state) {
        final isAuthenticated = authController.isAuthenticated;
        final hasRole = authController.selectedRole != null;
        final currentPath = state.matchedLocation;

        // 1. Let splash finish first
        if (!splashDone) {
          return currentPath == splash ? null : splash;
        }

        // 2. If at splash but it's done, move to next logical screen
        if (currentPath == splash) {
          if (isAuthenticated) return home;
          if (hasRole) return login;
          return roleSelect;
        }

        // 3. Authenticated users should be at home (or deeper)
        if (isAuthenticated) {
          if (currentPath == login || currentPath == roleSelect) {
            return home;
          }
          return null;
        }

        // 4. No role selected — must be at role selection
        if (!hasRole) {
          return currentPath == roleSelect ? null : roleSelect;
        }

        // 5. Has role but not authenticated — go to login
        // We removed the roleSelect check here so it redirects once a role is picked
        if (currentPath != login && currentPath != roleSelect) {
          return login;
        }
        
        // If at roleSelect but already have a role, go to login
        if (currentPath == roleSelect && hasRole) {
          return login;
        }

        return null;
      },
      routes: [
        GoRoute(
          path: splash,
          builder: (context, state) => SplashScreen(
            onInitialized: () {
              splashDone = true;
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
          ),
        ),
        GoRoute(
          path: programs,
          builder: (context, state) => const ProgramListingScreen(),
        ),
        GoRoute(
          path: programDetails,
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return ProgramDetailsScreen(programId: id);
          },
        ),
      ],
    );
  }
}
