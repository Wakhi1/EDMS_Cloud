/// Typed path constants for go_router routes. Kept as plain strings (not an
/// enum) so go_router's path-parameter syntax (`:id`) stays readable.
class RoutePaths {
  const RoutePaths._();

  /// Neutral splash — the real [initialLocation], so a fresh app load never
  /// briefly renders /login (or any other real screen) before the license
  /// and auth checks have actually resolved. See core/router/app_router.dart.
  static const bootstrap = '/bootstrap';
  static const login = '/login';
  static const licenseActivation = '/activate-license';
  static const dashboard = '/dashboard';
  static const repository = '/repository';
  static const viewer = '/viewer/:documentId';
  static const search = '/search';
  static const sharing = '/sharing';
  /// Public, unauthenticated landing page for a shared-record link — see
  /// features/sharing/presentation/share_view_screen.dart and this file's
  /// note on app_router.dart's redirect allowlist.
  static const shareView = '/s/:token';
  static String shareViewFor(String token) => '/s/$token';
  static const accessDenied = '/access-denied';
  static const devWidgets = '/dev/widgets';
  static const approvals = '/approvals';
  static const workflow = '/workflow';
  static const versions = '/versions';
  static const versionsDetail = '/versions/:documentId';
  static const audit = '/audit';
  static const retention = '/retention';
  static const reports = '/reports';
  static const notifications = '/notifications';
  static const users = '/users';
  static const permissions = '/permissions';
  static const permissionsDetail = '/permissions/:targetType/:targetId';
  static const capture = '/capture';
  static const integrations = '/integrations';
  static const security = '/security';
  static const departments = '/departments';
  static const settings = '/settings';
  static const backup = '/backup';

  static String viewerFor(String documentId) => '/viewer/$documentId';
  static String versionsFor(String documentId) => '/versions/$documentId';
  static String permissionsFor(String targetType, String targetId) => '/permissions/$targetType/$targetId';
}
