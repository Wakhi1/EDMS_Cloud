import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../router/route_paths.dart';

class NavItem {
  const NavItem({
    required this.label,
    required this.icon,
    required this.path,
    this.moduleKey,
    this.shortLabel,
  });

  final String label;
  final String? shortLabel;
  final PhosphorIconData icon;
  final String path;

  /// Key into [kModuleAllowedRoles] (core/auth/module_access.dart) — null
  /// means not server-gated (e.g. dashboard, sharing placeholder).
  final String? moduleKey;
}

class NavGroup {
  const NavGroup(this.title, this.items);

  final String title;
  final List<NavItem> items;
}

/// Matches the design mockup's grouping (Work / Records / Governance /
/// Security & Access / Administration). Phase 1 implements Dashboard,
/// Repository, Search and the Sharing placeholder; everything else routes
/// to a "Coming in Phase 2" stand-in screen so navigation never dead-ends.
const kNavGroups = <NavGroup>[
  NavGroup('Work', [
    NavItem(label: 'Dashboard', shortLabel: 'Home', icon: PhosphorIconsDuotone.gauge, path: RoutePaths.dashboard),
    NavItem(label: 'Approvals', shortLabel: 'Approve', icon: PhosphorIconsDuotone.checkSquareOffset, path: '/approvals', moduleKey: 'approvals'),
    NavItem(label: 'Notifications', shortLabel: 'Alerts', icon: PhosphorIconsDuotone.bell, path: '/notifications'),
  ]),
  NavGroup('Records', [
    NavItem(label: 'Repository', shortLabel: 'Files', icon: PhosphorIconsDuotone.folders, path: RoutePaths.repository, moduleKey: 'repository'),
    NavItem(label: 'Smart Upload', shortLabel: 'Upload', icon: PhosphorIconsDuotone.uploadSimple, path: '/upload', moduleKey: 'capture'),
    NavItem(label: 'Capture & Scan', shortLabel: 'Capture', icon: PhosphorIconsDuotone.scan, path: '/capture', moduleKey: 'capture'),
    NavItem(label: 'Search', shortLabel: 'Search', icon: PhosphorIconsDuotone.magnifyingGlass, path: RoutePaths.search, moduleKey: 'repository'),
    NavItem(label: 'Sharing & Links', shortLabel: 'Share', icon: PhosphorIconsDuotone.shareNetwork, path: RoutePaths.sharing),
    NavItem(label: 'Version History', shortLabel: 'Versions', icon: PhosphorIconsDuotone.clockCounterClockwise, path: '/versions', moduleKey: 'versions'),
  ]),
  NavGroup('Governance', [
    NavItem(label: 'Audit Trail', shortLabel: 'Audit', icon: PhosphorIconsDuotone.listMagnifyingGlass, path: '/audit', moduleKey: 'audit'),
    NavItem(label: 'Retention & Disposal', shortLabel: 'Retention', icon: PhosphorIconsDuotone.archive, path: '/retention', moduleKey: 'retention'),
  ]),
  NavGroup('Security & Access', [
    NavItem(label: 'Folder & Document Access', shortLabel: 'Access', icon: PhosphorIconsDuotone.lockKey, path: '/permissions', moduleKey: 'permissions'),
    NavItem(label: 'Authentication & Sessions', shortLabel: 'Security', icon: PhosphorIconsDuotone.shieldCheck, path: '/security'),
    NavItem(label: 'Users & Groups', shortLabel: 'Users', icon: PhosphorIconsDuotone.usersThree, path: '/users', moduleKey: 'users'),
  ]),
  NavGroup('Administration', [
    NavItem(label: 'Workflow Designer', shortLabel: 'Workflow', icon: PhosphorIconsDuotone.flowArrow, path: '/workflow', moduleKey: 'workflow'),
    NavItem(label: 'Departments', shortLabel: 'Depts', icon: PhosphorIconsDuotone.buildings, path: '/departments', moduleKey: 'departments'),
    NavItem(label: 'Integrations', shortLabel: 'Links', icon: PhosphorIconsDuotone.plugs, path: '/integrations', moduleKey: 'integrations'),
    NavItem(label: 'Reports', shortLabel: 'Reports', icon: PhosphorIconsDuotone.chartBar, path: '/reports', moduleKey: 'reports'),
    // Settings has no moduleKey: every role reaches it for the self-service
    // Profile/Appearance tabs; the System Settings tab itself is gated
    // client-side (see settings_screen.dart's _kSystemSettingsRoles) since
    // the underlying API is admin/Records-Manager only.
    NavItem(label: 'Settings', shortLabel: 'Settings', icon: PhosphorIconsDuotone.gearSix, path: '/settings'),
    // No moduleKey: backup access is hard-gated server-side, not part of
    // the configurable module matrix — see module_access.dart's note.
    NavItem(label: 'Backup & Disaster Recovery', shortLabel: 'Backup', icon: PhosphorIconsDuotone.cloudArrowUp, path: '/backup'),
  ]),
];

const kBottomNavPaths = [RoutePaths.dashboard, RoutePaths.repository, RoutePaths.search, '/approvals'];
