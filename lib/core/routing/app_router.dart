import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/devices/presentation/device_details_screen.dart';
import '../../features/devices/presentation/devices_screen.dart';
import '../../features/discovery/presentation/discovery_screen.dart';
import '../../features/guide/presentation/connection_guide_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/manual_connection/presentation/manual_connection_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/repair/domain/repair_models.dart';
import '../../features/repair/presentation/diagnostic_result_screen.dart';
import '../../features/repair/presentation/diagnostic_wizard_screen.dart';
import '../../features/repair/presentation/error_code_lookup_screen.dart';
import '../../features/repair/presentation/maintenance_screen.dart';
import '../../features/repair/presentation/repair_home_screen.dart';
import '../../features/remote/presentation/remote_screen.dart';
import '../../features/settings/presentation/privacy_policy_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/timer/presentation/timer_screen.dart';
import '../widgets/app_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
    GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
        GoRoute(path: '/remote', builder: (_, _) => const RemoteScreen()),
        GoRoute(path: '/devices', builder: (_, _) => const DevicesScreen()),
        GoRoute(
          path: '/repair',
          builder: (_, _) => const RepairHomeScreen(),
          routes: [
            GoRoute(
              path: 'diagnosis',
              pageBuilder: (_, state) => _slidePage(
                state,
                DiagnosticWizardScreen(
                  initialCategory: state.extra as RepairCategory?,
                ),
              ),
            ),
            GoRoute(
              path: 'result',
              pageBuilder: (_, state) => _slidePage(
                state,
                DiagnosticResultScreen(
                  result: state.extra! as DiagnosticResult,
                ),
              ),
            ),
            GoRoute(
              path: 'error-code',
              pageBuilder: (_, state) =>
                  _slidePage(state, const ErrorCodeLookupScreen()),
            ),
            GoRoute(
              path: 'maintenance',
              pageBuilder: (_, state) =>
                  _slidePage(state, const MaintenanceScreen()),
            ),
          ],
        ),
        GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
      ],
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/discovery',
      pageBuilder: (_, state) => _slidePage(state, const DiscoveryScreen()),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/manual-connection',
      pageBuilder: (_, state) =>
          _slidePage(state, const ManualConnectionScreen()),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/timers',
      pageBuilder: (_, state) => _slidePage(state, const TimerScreen()),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/devices/:id',
      pageBuilder: (_, state) => _slidePage(
        state,
        DeviceDetailsScreen(deviceId: state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/guide',
      pageBuilder: (_, state) =>
          _slidePage(state, const ConnectionGuideScreen()),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/privacy-policy',
      pageBuilder: (_, state) => _slidePage(state, const PrivacyPolicyScreen()),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.explore_off_rounded, size: 48),
          const SizedBox(height: 12),
          const Text('This page could not be found.'),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => context.go('/home'),
            child: const Text('Go home'),
          ),
        ],
      ),
    ),
  ),
);

CustomTransitionPage<void> _slidePage(
  GoRouterState state,
  Widget child,
) => CustomTransitionPage<void>(
  key: state.pageKey,
  child: child,
  transitionDuration: const Duration(milliseconds: 300),
  reverseTransitionDuration: const Duration(milliseconds: 240),
  transitionsBuilder: (context, animation, secondaryAnimation, child) =>
      SlideTransition(
        position: Tween(begin: const Offset(0, .035), end: Offset.zero).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        ),
        child: FadeTransition(opacity: animation, child: child),
      ),
);
