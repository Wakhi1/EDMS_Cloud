/// Typed path constants for go_router routes. Kept as plain strings (not an
/// enum) so go_router's path-parameter syntax (`:id`) stays readable.
class RoutePaths {
  const RoutePaths._();

  static const login = '/login';
  static const dashboard = '/dashboard';
  static const repository = '/repository';
  static const viewer = '/viewer/:documentId';
  static const search = '/search';
  static const sharing = '/sharing';
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

  // Platform admin (DocSecore staff) — a fully separate route tree/auth
  // domain from everything above, see core/platform_admin/.
  static const platformAdminLogin = '/platform-admin/login';
  static const platformAdminCompanies = '/platform-admin';
  static const platformAdminCompanyDetail = '/platform-admin/companies/:id';

  static String viewerFor(String documentId) => '/viewer/$documentId';
  static String versionsFor(String documentId) => '/versions/$documentId';
  static String permissionsFor(String targetType, String targetId) => '/permissions/$targetType/$targetId';
  static String platformAdminCompanyFor(String id) => '/platform-admin/companies/$id';
}
