import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/approvals/presentation/approvals_screen.dart';
import '../../features/audit/presentation/audit_screen.dart';
import '../../features/backup/presentation/backup_screen.dart';
import '../../features/bootstrap/presentation/bootstrap_screen.dart';
import '../../features/capture/presentation/capture_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/departments/presentation/departments_screen.dart';
import '../../features/document_viewer/presentation/viewer_screen.dart';
import '../../features/integrations/presentation/integrations_screen.dart';
import '../../features/license_activation/presentation/license_activation_screen.dart';
import '../../features/login/presentation/login_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/permissions/presentation/permissions_home_screen.dart';
import '../../features/permissions/presentation/permissions_target_screen.dart';
import '../../features/repository/presentation/repository_screen.dart';
import '../../features/reports/presentation/reports_screen.dart';
import '../../features/retention/presentation/retention_screen.dart';
import '../../features/search/presentation/search_screen.dart';
import '../../features/security/presentation/security_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/sharing/presentation/share_view_screen.dart';
import '../../features/sharing/presentation/sharing_screen.dart';
import '../../features/smart_upload/presentation/smart_upload_screen.dart';
import '../../features/users/presentation/users_screen.dart';
import '../../features/versions/presentation/versions_screen.dart';
import '../../features/workflow_designer/presentation/workflow_designer_screen.dart';
import '../auth/auth_providers.dart';
import '../auth/auth_state.dart';
import '../auth/module_access_events.dart';
import '../license/license_gate_provider.dart';
import '../widgets/access_denied_screen.dart';
import '../widgets/coming_soon_screen.dart';
import '../widgets/responsive_scaffold.dart';
import 'route_paths.dart';

/// Bridges Riverpod's authControllerProvider/licenseGateControllerProvider
/// into go_router's [Listenable]-based `refreshListenable`, so navigation
/// re-evaluates `redirect` whenever either state machine transitions
/// (e.g. reaching `authenticated`, forceSignOut() firing after a failed
/// token refresh, or the license gate flipping active after activation).
class _GoRouterRefreshNotifier extends ChangeNotifier {
  _GoRouterRefreshNotifier(Ref ref) {
    ref.listen(authControllerProvider, (_, _) => notifyListeners());
    ref.listen(licenseGateControllerProvider, (_, _) => notifyListeners());
  }
}

/// One route per nav item that has no real screen yet — a single
/// [ComingSoonScreen] builder parameterized by title, to avoid boilerplate.
const _stubRoutes = <String, String>{};

final goRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _GoRouterRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  final router = GoRouter(
    // Neutral splash, not /login — a company's license is not confirmed
    // active yet at this point, and /login must never render (even for a
    // single frame) until it is. See BootstrapScreen's doc comment.
    initialLocation: RoutePaths.bootstrap,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final matched = state.matchedLocation;
      final licenseState = ref.read(licenseGateControllerProvider);
      final authState = ref.read(authControllerProvider);

      // Neither check has resolved yet — park on the splash. This is the
      // fix for "/login renders even when the license hasn't been
      // confirmed": previously, while checking, redirect returned null and
      // just let whatever route was already matched (e.g. /login, typed
      // directly into the address bar) render as-is.
      if (licenseState.checking || authState.isLoading) {
        return matched == RoutePaths.bootstrap ? null : RoutePaths.bootstrap;
      }

      // This deployment's own license is checked before anything else —
      // no company user reaches /login, let alone any authenticated
      // route, while it's inactive. See core/license/license_gate_provider.dart.
      final atActivation = matched == RoutePaths.licenseActivation;
      if (!licenseState.active) return atActivation ? null : RoutePaths.licenseActivation;

      // A shared-record link (see features/sharing/presentation/
      // share_view_screen.dart) needs no EDMS account — the recipient was
      // never going to log in at all. Still gated on the license check
      // above (an unlicensed deployment blocks everything), just not on
      // "logged in".
      if (matched.startsWith('/s/')) return null;

      final loggedIn = authState.valueOrNull is LoginAuthenticated;
      final atLogin = matched == RoutePaths.login;

      // Both checks just resolved (coming from the splash) or the license
      // just got activated — send to the real destination in one hop
      // rather than landing on an intermediate screen first.
      if (matched == RoutePaths.bootstrap || atActivation) {
        return loggedIn ? RoutePaths.dashboard : RoutePaths.login;
      }

      if (!loggedIn && !atLogin) return RoutePaths.login;
      if (loggedIn && atLogin) return RoutePaths.dashboard;
      return null;
    },
    routes: [
      GoRoute(path: RoutePaths.bootstrap, builder: (context, state) => const BootstrapScreen()),
      GoRoute(path: RoutePaths.login, builder: (context, state) => const LoginScreen()),
      GoRoute(path: RoutePaths.licenseActivation, builder: (context, state) => const LicenseActivationScreen()),
      // Outside the ShellRoute, deliberately — no nav chrome for a
      // recipient who was never going to log in. See this file's redirect
      // bypass above.
      GoRoute(
        path: RoutePaths.shareView,
        builder: (context, state) => ShareViewScreen(token: state.pathParameters['token']!),
      ),
      ShellRoute(
        builder: (context, state, child) => ResponsiveScaffold(child: child),
        routes: [
          GoRoute(path: RoutePaths.dashboard, builder: (context, state) => const DashboardScreen()),
          GoRoute(path: RoutePaths.repository, builder: (context, state) => const RepositoryScreen()),
          GoRoute(
            path: RoutePaths.viewer,
            builder: (context, state) => ViewerScreen(documentId: state.pathParameters['documentId']!),
          ),
          GoRoute(path: RoutePaths.search, builder: (context, state) => const SearchScreen()),
          GoRoute(path: '/upload', builder: (context, state) => const SmartUploadScreen()),
          GoRoute(path: RoutePaths.sharing, builder: (context, state) => const SharingScreen()),
          GoRoute(path: RoutePaths.approvals, builder: (context, state) => const ApprovalsScreen()),
          GoRoute(path: RoutePaths.workflow, builder: (context, state) => const WorkflowDesignerScreen()),
          GoRoute(path: RoutePaths.versions, builder: (context, state) => const VersionsEmptyScreen()),
          GoRoute(
            path: RoutePaths.versionsDetail,
            builder: (context, state) => VersionsScreen(documentId: state.pathParameters['documentId']!),
          ),
          GoRoute(path: RoutePaths.audit, builder: (context, state) => const AuditScreen()),
          GoRoute(path: RoutePaths.retention, builder: (context, state) => const RetentionScreen()),
          GoRoute(path: RoutePaths.reports, builder: (context, state) => const ReportsScreen()),
          GoRoute(path: RoutePaths.notifications, builder: (context, state) => const NotificationsScreen()),
          GoRoute(path: RoutePaths.users, builder: (context, state) => const UsersScreen()),
          GoRoute(path: RoutePaths.permissions, builder: (context, state) => const PermissionsHomeScreen()),
          GoRoute(
            path: RoutePaths.permissionsDetail,
            builder: (context, state) => PermissionsTargetScreen(
              targetType: state.pathParameters['targetType']!,
              targetId: state.pathParameters['targetId']!,
            ),
          ),
          GoRoute(path: RoutePaths.capture, builder: (context, state) => const CaptureScreen()),
          GoRoute(path: RoutePaths.integrations, builder: (context, state) => const IntegrationsScreen()),
          GoRoute(path: RoutePaths.security, builder: (context, state) => const SecurityScreen()),
          GoRoute(path: RoutePaths.departments, builder: (context, state) => const DepartmentsScreen()),
          GoRoute(path: RoutePaths.settings, builder: (context, state) => const SettingsScreen()),
          GoRoute(path: RoutePaths.backup, builder: (context, state) => const BackupScreen()),
          GoRoute(path: RoutePaths.accessDenied, builder: (context, state) => const AccessDeniedScreen()),
          for (final entry in _stubRoutes.entries)
            GoRoute(path: entry.key, builder: (context, state) => ComingSoonScreen(title: entry.value)),
        ],
      ),
    ],
  );

  // Imperative navigation, independent of `redirect`: a 403 can happen on
  // any authenticated screen, not just at a route transition.
  final subscription = ref.watch(moduleAccessEventsProvider).onDenied.listen((_) {
    router.go(RoutePaths.accessDenied);
  });
  ref.onDispose(subscription.cancel);

  return router;
});
