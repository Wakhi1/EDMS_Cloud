/// Client-side fallback map of module -> role names permitted to view it,
/// used ONLY to render a helpful "Permitted roles: ..." line on the Access
/// Denied screen. This is NOT the source of truth for access control — the
/// server's `role_module_permissions` table (via `requireModuleAccess`
/// middleware) is authoritative, and every 403 it returns is what actually
/// drives denial in this app. Keep in sync with the seed data used for
/// local dev (see scratchpad/seed_role_module_permissions.sql) — mismatches
/// here only produce a slightly wrong hint, never a real access change.
const kModuleAllowedRoles = <String, List<String>>{
  'repository': [
    'Records Officer',
    'Approving Manager',
    'Finance Officer',
    'Records Manager',
    'System Administrator',
    'Internal Auditor',
  ],
  'viewer': [
    'Records Officer',
    'Approving Manager',
    'Finance Officer',
    'Records Manager',
    'System Administrator',
    'Internal Auditor',
  ],
  'capture': ['Records Officer', 'System Administrator'],
  'versions': ['Records Officer', 'Records Manager', 'System Administrator'],
  'permissions': ['Records Manager', 'System Administrator'],
  'approvals': ['Approving Manager', 'Finance Officer', 'System Administrator'],
  'workflow': ['Records Manager', 'System Administrator'],
  'audit': ['Records Manager', 'System Administrator', 'Internal Auditor'],
  'retention': ['Records Manager', 'System Administrator'],
  'integrations': ['System Administrator'],
  'reports': [
    'Approving Manager',
    'Finance Officer',
    'Records Manager',
    'System Administrator',
    'Internal Auditor',
  ],
  'users': ['Records Manager', 'System Administrator'],
  'departments': ['Records Manager', 'System Administrator'],
  'settings': ['Records Manager', 'System Administrator'],
  // NOTE: 'backup' is deliberately NOT listed here. Unlike every module
  // above, backup/restore access is hard-gated server-side via allowRoles
  // (see backend/routes/backup.routes.js), not the configurable
  // role_module_permissions matrix — so it must NOT appear as a column in
  // the Permissions Matrix screen (kPermissionModules, derived from this
  // map's keys), where toggling it would look like it does something but
  // wouldn't actually change access. The Backup nav item has no moduleKey
  // for the same reason; its access-denied redirect still works via the
  // normal global-403 handler, it just won't show a "Permitted roles" hint.
};

/// The 11 module strings actually checked by `requireModuleAccess(...)`
/// across the backend — the canonical column list for the role×module
/// permission matrix (core/api/resources/permissions_api.dart#matrix).
/// Derived from [kModuleAllowedRoles]' keys rather than retyped, so the two
/// lists can never drift.
final kPermissionModules = kModuleAllowedRoles.keys.toList(growable: false);

/// Backend denial messages look like "Your role is not permitted to open
/// `<module>`" (backend/middleware/rbac.middleware.js). Best-effort extraction
/// for display only — if the format ever changes, this just returns null
/// and the permitted-roles hint is omitted, nothing else breaks.
String? moduleFromDeniedMessage(String message) {
  final match = RegExp(r'open (\w+)$').firstMatch(message);
  return match?.group(1);
}
