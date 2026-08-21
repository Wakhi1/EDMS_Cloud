import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../features/notifications/presentation/notifications_panel.dart';
import '../../features/notifications/providers/notifications_providers.dart';
import '../auth/auth_providers.dart';
import '../auth/module_access.dart';
import '../branding/branding_provider.dart';
import '../models/company_branding.dart';
import '../navigation/nav_item.dart';
import '../router/route_paths.dart';
import '../theme/pspf_tokens.dart';
import '../theme/theme_mode_provider.dart';

const _kDesktopBreakpoint = 1024.0;
const _kTabletBreakpoint = 600.0;

/// The three responsive layouts from the design mockup: desktop (permanent
/// 238px drawer + search app bar), tablet (76px icon rail + hamburger
/// drawer), mobile (bottom nav + hamburger drawer, no search in the app
/// bar). Wraps every authenticated route via the ShellRoute in
/// core/router/app_router.dart.
class ResponsiveScaffold extends ConsumerWidget {
  const ResponsiveScaffold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= _kDesktopBreakpoint;
    final isTablet = width >= _kTabletBreakpoint && width < _kDesktopBreakpoint;
    final isMobile = width < _kTabletBreakpoint;
    final currentPath = GoRouterState.of(context).matchedLocation;
    final tokens = context.tokens;

    return Scaffold(
      appBar: _TopAppBar(showHamburger: !isDesktop, showSearch: isDesktop, currentPath: currentPath),
      drawer: isDesktop ? null : Drawer(child: _NavDrawerContent(currentPath: currentPath)),
      endDrawer: const NotificationsPanel(),
      body: Row(
        children: [
          if (isDesktop)
            SizedBox(
              width: 238,
              child: Material(
                color: tokens.surf,
                child: _NavDrawerContent(currentPath: currentPath),
              ),
            ),
          if (isTablet) _NavRail(currentPath: currentPath),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: isMobile ? _BottomNav(currentPath: currentPath) : null,
    );
  }
}

/// Every literal path a nav item (sidebar/rail/bottom-bar) links to — the
/// screens a user always reaches directly from navigation, never by
/// drilling into something else. Any OTHER matched route (viewer/:id,
/// versions/:id, permissions/:type/:id, ...) is a "detail" screen reached
/// by drilling in, and gets a back button in the app bar since it has no
/// other way out besides the browser's own back button (these routes are
/// entered via context.go(), which replaces rather than pushes, so
/// go_router's own canPop() is never true here regardless of how the user
/// arrived).
final _kTopLevelPaths = kNavGroups.expand((g) => g.items).map((i) => i.path).toSet();

String? _backTargetFor(String matchedLocation) {
  if (_kTopLevelPaths.contains(matchedLocation)) return null;
  if (matchedLocation.startsWith('/viewer/')) return RoutePaths.repository;
  if (matchedLocation.startsWith('/versions/')) return RoutePaths.versions;
  if (matchedLocation.startsWith('/permissions/')) return RoutePaths.permissions;
  return null;
}

class _TopAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const _TopAppBar({required this.showHamburger, required this.showSearch, required this.currentPath});

  final bool showHamburger;
  final bool showSearch;
  final String currentPath;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final themeMode = ref.watch(themeModeProvider);
    final searchController = TextEditingController();
    final unreadCount = ref.watch(notificationsListProvider).valueOrNull?.where((n) => !n.isRead).length ?? 0;
    final backTarget = _backTargetFor(currentPath);
    final branding = ref.watch(companyBrandingProvider).valueOrNull ?? CompanyBranding.fallback;

    return AppBar(
      leading: backTarget != null
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Back',
              onPressed: () => context.go(backTarget),
            )
          : showHamburger
              ? Builder(builder: (context) => IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ))
              : null,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Text(branding.shortLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
          if (showSearch) ...[
            const SizedBox(width: 22),
            SizedBox(
              width: 380,
              height: 34,
              child: TextField(
                controller: searchController,
                style: const TextStyle(fontSize: 13),
                decoration: const InputDecoration(
                  isDense: true,
                  hintText: 'Search records, members, claim numbers…',
                  prefixIcon: Icon(Icons.search, size: 18),
                ),
                onSubmitted: (q) => context.go('${RoutePaths.search}?q=${Uri.encodeQueryComponent(q)}'),
              ),
            ),
          ],
        ],
      ),
      actions: [
        Builder(
          builder: (context) => IconButton(
            icon: Badge(
              isLabelVisible: unreadCount > 0,
              label: Text(unreadCount > 99 ? '99+' : '$unreadCount'),
              child: Icon(PhosphorIconsDuotone.bell),
            ),
            tooltip: 'Notifications',
            onPressed: () => Scaffold.of(context).openEndDrawer(),
          ),
        ),
        IconButton(
          icon: Icon(themeMode == ThemeMode.dark ? PhosphorIconsDuotone.sun : PhosphorIconsDuotone.moon),
          tooltip: 'Toggle theme',
          onPressed: () {
            ref.read(themeModeProvider.notifier).setMode(themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
          },
        ),
        if (user != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(child: Text(user.role, style: const TextStyle(fontSize: 12))),
          ),
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Sign out',
          onPressed: () => ref.read(authControllerProvider.notifier).logout(),
        ),
      ],
    );
  }
}

class _NavDrawerContent extends ConsumerWidget {
  const _NavDrawerContent({required this.currentPath});

  final String currentPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final user = ref.watch(currentUserProvider);

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: tokens.line))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SIGNED IN AS', style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 3),
              Text(user?.fullName ?? '—', style: Theme.of(context).textTheme.titleSmall),
              Text(user?.role ?? '—', style: TextStyle(fontSize: 12, color: tokens.accD)),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              for (final group in kNavGroups) _NavGroupSection(group: group, currentPath: currentPath),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(border: Border(top: BorderSide(color: tokens.line))),
          child: OutlinedButton.icon(
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            icon: const Icon(Icons.logout, size: 16),
            label: const Text('Sign out'),
          ),
        ),
      ],
    );
  }
}

class _NavGroupSection extends ConsumerWidget {
  const _NavGroupSection({required this.group, required this.currentPath});

  final NavGroup group;
  final String currentPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(currentUserProvider)?.role;
    final unreadCount = ref.watch(notificationsListProvider).valueOrNull?.where((n) => !n.isRead).length ?? 0;

    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
            child: Text(group.title.toUpperCase(), style: Theme.of(context).textTheme.labelSmall),
          ),
          for (final item in group.items)
            _NavTile(
              item: item,
              selected: currentPath == item.path,
              maybeLocked: item.moduleKey != null && role != null && !(kModuleAllowedRoles[item.moduleKey]?.contains(role) ?? true),
              trailingCount: item.path == RoutePaths.notifications ? unreadCount : 0,
            ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({required this.item, required this.selected, required this.maybeLocked, this.trailingCount = 0});

  final NavItem item;
  final bool selected;
  final bool maybeLocked;
  final int trailingCount;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return InkWell(
      onTap: () => context.go(item.path),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? tokens.sel : Colors.transparent,
          border: Border(left: BorderSide(color: selected ? tokens.acc : Colors.transparent, width: 3)),
        ),
        child: Row(
          children: [
            Icon(item.icon, size: 18, color: selected ? tokens.ink : tokens.ink2),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(fontSize: 13.5, color: selected ? tokens.ink : tokens.ink2, fontWeight: selected ? FontWeight.w600 : FontWeight.w400),
              ),
            ),
            if (trailingCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                color: tokens.bad,
                child: Text(
                  trailingCount > 99 ? '99+' : '$trailingCount',
                  style: const TextStyle(fontSize: 10.5, color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
            if (maybeLocked) Icon(Icons.lock_outline, size: 13, color: tokens.ink3),
          ],
        ),
      ),
    );
  }
}

class _NavRail extends ConsumerWidget {
  const _NavRail({required this.currentPath});

  final String currentPath;

  static final _flatItems = kNavGroups.expand((g) => g.items).toList(growable: false);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final selectedIndex = _flatItems.indexWhere((i) => i.path == currentPath);

    return SizedBox(
      width: 76,
      child: Material(
        color: tokens.surf,
        child: NavigationRail(
          backgroundColor: tokens.surf,
          selectedIndex: selectedIndex < 0 ? null : selectedIndex,
          labelType: NavigationRailLabelType.all,
          onDestinationSelected: (i) => context.go(_flatItems[i].path),
          destinations: [
            for (final item in _flatItems)
              NavigationRailDestination(
                icon: Icon(item.icon, size: 20),
                label: Text(item.shortLabel ?? item.label, style: const TextStyle(fontSize: 10)),
              ),
          ],
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.currentPath});

  final String currentPath;

  @override
  Widget build(BuildContext context) {
    final flatItems = kNavGroups.expand((g) => g.items).toList(growable: false);
    final primary = [for (final p in kBottomNavPaths) flatItems.firstWhere((i) => i.path == p)];
    final selectedIndex = kBottomNavPaths.indexOf(currentPath);

    return BottomNavigationBar(
      currentIndex: selectedIndex < 0 ? 0 : selectedIndex,
      type: BottomNavigationBarType.fixed,
      onTap: (i) {
        if (i == primary.length) {
          Scaffold.of(context).openDrawer();
          return;
        }
        context.go(primary[i].path);
      },
      items: [
        for (final item in primary)
          BottomNavigationBarItem(icon: Icon(item.icon, size: 20), label: item.shortLabel ?? item.label),
        const BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'More'),
      ],
    );
  }
}
