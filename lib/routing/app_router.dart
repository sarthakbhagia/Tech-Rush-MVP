import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/auth/auth_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/job_listing/job_listing_screen.dart';
import '../screens/job_detail/job_detail_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/demo_widgets_screen.dart';
import '../widgets/app_bottom_nav.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return appRouter;
});

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    // Fullscreen Routes (Outside Bottom Navigation)
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const SplashScreen();
      },
    ),
    GoRoute(
      path: '/auth',
      builder: (BuildContext context, GoRouterState state) {
        return const AuthScreen();
      },
    ),
    GoRoute(
      path: '/job/:id',
      builder: (BuildContext context, GoRouterState state) {
        final jobId = state.pathParameters['id'] ?? 'job-1';
        return JobDetailScreen(jobId: jobId);
      },
    ),
    GoRoute(
      path: '/demo',
      builder: (BuildContext context, GoRouterState state) {
        return const DemoWidgetsScreen();
      },
    ),

    // Persistent Bottom Tab Navigation ShellRoute
    ShellRoute(
      builder: (BuildContext context, GoRouterState state, Widget child) {
        return AppBottomNavScaffold(child: child);
      },
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (BuildContext context, GoRouterState state) {
            return const DashboardScreen();
          },
        ),
        GoRoute(
          path: '/listings',
          builder: (BuildContext context, GoRouterState state) {
            return const JobListingScreen();
          },
        ),
        GoRoute(
          path: '/profile',
          builder: (BuildContext context, GoRouterState state) {
            return const ProfileScreen();
          },
        ),
      ],
    ),
  ],
);
