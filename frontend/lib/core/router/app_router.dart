import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/approvals/presentation/approvals_screen.dart';
import '../../features/audit/presentation/audit_screen.dart';
import '../../features/backup/presentation/backup_screen.dart';
import '../../features/capture/presentation/capture_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/departments/presentation/departments_screen.dart';
import '../../features/document_viewer/presentation/viewer_screen.dart';
import '../../features/integrations/presentation/integrations_screen.dart';
import '../../features/login/presentation/login_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/permissions/presentation/permissions_home_screen.dart';
import '../../features/permissions/presentation/permissions_target_screen.dart';
import '../../features/platform_admin/presentation/companies_list_screen.dart';
import '../../features/platform_admin/presentation/company_detail_screen.dart';
import '../../features/platform_admin/presentation/platform_admin_login_screen.dart';
import '../../features/platform_admin/presentation/platform_admin_shell.dart';
import '../../features/repository/presentation/repository_screen.dart';
import '../../features/reports/presentation/reports_screen.dart';
import '../../features/retention/presentation/retention_screen.dart';
import '../../features/search/presentation/search_screen.dart';
import '../../features/security/presentation/security_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/sharing_placeholder/presentation/sharing_placeholder_screen.dart';
import '../../features/smart_upload/presentation/smart_upload_screen.dart';
import '../../features/users/presentation/users_screen.dart';
import '../../features/versions/presentation/versions_screen.dart';
import '../../features/workflow_designer/presentation/workflow_designer_screen.dart';
import '../auth/auth_providers.dart';
import '../auth/auth_state.dart';
import '../auth/module_access_events.dart';
import '../platform_admin/platform_admin_providers.dart';
import '../widgets/access_denied_screen.dart';
import '../widgets/coming_soon_screen.dart';
import '../widgets/responsive_scaffold.dart';
import 'route_paths.dart';

/// Bridges Riverpod's authControllerProvider into go_router's
/// [Listenable]-based `refreshListenable`, so navigation re-evaluates
/// `redirect` whenever the login state machine transitions (e.g. reaching
/// `authenticated`, or forceSignOut() firing after a failed token refresh).
class _GoRouterRefreshNotifier extends ChangeNotifier {
  _GoRouterRefreshNotifier(Ref ref) {
    ref.listen(authControllerProvider, (_, _) => notifyListeners());
    ref.listen(platformAdminAuthControllerProvider, (_, _) => notifyListeners());
  }
}

/// One route per nav item that has no real screen yet — a single
/// [ComingSoonScreen] builder parameterized by title, to avoid boilerplate.
const _stubRoutes = <String, String>{};

final goRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _GoRouterRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  final router = GoRouter(
    initialLocation: RoutePaths.login,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      // /platform-admin/* is a fully separate auth domain (DocSecore
      // staff, not a company user) — branch off before any tenant-auth
      // logic runs, and never fall through to it.
      if (state.matchedLocation.startsWith('/platform-admin')) {
        final paState = ref.read(platformAdminAuthControllerProvider);
        if (paState.isLoading) return null;

        final loggedIn = paState.valueOrNull != null;
        final atPaLogin = state.matchedLocation == RoutePaths.platformAdminLogin;

        if (!loggedIn && !atPaLogin) return RoutePaths.platformAdminLogin;
        if (loggedIn && atPaLogin) return RoutePaths.platformAdminCompanies;
        return null;
      }

      final authState = ref.read(authControllerProvider);
      // Cold-start /api/auth/me check still in flight — hold at the
      // current location rather than bouncing to /login and back.
      if (authState.isLoading) return null;

      final loggedIn = authState.valueOrNull is LoginAuthenticated;
      final atLogin = state.matchedLocation == RoutePaths.login;

      if (!loggedIn && !atLogin) return RoutePaths.login;
      if (loggedIn && atLogin) return RoutePaths.dashboard;
      return null;
    },
    routes: [
      GoRoute(path: RoutePaths.login, builder: (context, state) => const LoginScreen()),
      GoRoute(path: RoutePaths.platformAdminLogin, builder: (context, state) => const PlatformAdminLoginScreen()),
      ShellRoute(
        builder: (context, state, child) => PlatformAdminShell(child: child),
        routes: [
          GoRoute(path: RoutePaths.platformAdminCompanies, builder: (context, state) => const CompaniesListScreen()),
          GoRoute(
            path: RoutePaths.platformAdminCompanyDetail,
            builder: (context, state) => CompanyDetailScreen(companyId: int.parse(state.pathParameters['id']!)),
          ),
        ],
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
          GoRoute(path: RoutePaths.sharing, builder: (context, state) => const SharingPlaceholderScreen()),
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
