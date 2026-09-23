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
/// 212px drawer + search app bar), tablet (76px icon rail + hamburger
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
              width: 212,
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
  if (matchedLocation.startsWith('/versions')) return RoutePaths.repository;
  if (matchedLocation.startsWith('/permissions/')) return RoutePaths.permissions;
  return null;
}

class _TopAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const _TopAppBar({required this.showHamburger, required this.showSearch, required this.currentPath});

  final bool showHamburger;
  final bool showSearch;
  final String currentPath;

  @override
  Size get preferredSize => const Size.fromHeight(52);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final themeMode = ref.watch(themeModeProvider);
    final searchController = TextEditingController();
    final unreadCount = ref.watch(notificationsListProvider).valueOrNull?.where((n) => !n.isRead).length ?? 0;
    final backTarget = _backTargetFor(currentPath);
    final branding = ref.watch(companyBrandingProvider).valueOrNull ?? CompanyBranding.fallback;

    final tokens = context.tokens;
    final initials = (user?.fullName ?? '').split(RegExp(r'\s+')).where((p) => p.isNotEmpty).take(2).map((p) => p[0].toUpperCase()).join();

    return AppBar(
      toolbarHeight: 52,
      titleSpacing: 14,
      leading: backTarget != null
          ? IconButton(icon: const Icon(Icons.arrow_back), tooltip: 'Back', onPressed: () => context.go(backTarget))
          : showHamburger
          ? Builder(
              builder: (context) => IconButton(icon: const Icon(Icons.menu), onPressed: () => Scaffold.of(context).openDrawer()),
            )
          : null,
      automaticallyImplyLeading: false,
      // Brand left, search centred in the remaining space, actions right.
      title: Row(
        children: [
          Text(branding.shortLabel, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          if (showSearch)
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: SizedBox(
                    height: 36,
                    child: TextField(
                      controller: searchController,
                      style: const TextStyle(fontSize: 12.5),
                      textAlignVertical: TextAlignVertical.center,
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: tokens.surf2,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                        hintText: 'Search records, members, claim numbers…',
                        hintStyle: TextStyle(fontSize: 12.5, color: tokens.ink3),
                        prefixIcon: Icon(PhosphorIconsRegular.magnifyingGlass, size: 15, color: tokens.ink3),
                        prefixIconConstraints: const BoxConstraints(minWidth: 34),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.zero,
                          borderSide: BorderSide(color: tokens.line),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.zero,
                          borderSide: BorderSide(color: tokens.accD),
                        ),
                      ),
                      onSubmitted: (q) => context.go('${RoutePaths.search}?q=${Uri.encodeQueryComponent(q)}'),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      actions: [
        Builder(
          builder: (context) => IconButton(
            visualDensity: VisualDensity.compact,
            icon: Badge(
              isLabelVisible: unreadCount > 0,
              label: Text(unreadCount > 99 ? '99+' : '$unreadCount'),
              child: Icon(PhosphorIconsRegular.bell, size: 19),
            ),
            tooltip: 'Notifications',
            onPressed: () => Scaffold.of(context).openEndDrawer(),
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: Icon(themeMode == ThemeMode.dark ? PhosphorIconsRegular.sun : PhosphorIconsRegular.moon, size: 19),
          tooltip: 'Toggle theme',
          onPressed: () {
            ref.read(themeModeProvider.notifier).setMode(themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
          },
        ),
        if (user != null)
          PopupMenuButton<String>(
            tooltip: '${user.fullName} · ${user.role}',
            offset: const Offset(0, 44),
            onSelected: (v) {
              if (v == 'logout') ref.read(authControllerProvider.notifier).logout();
            },
            itemBuilder: (_) => [
              PopupMenuItem<String>(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: tokens.ink),
                    ),
                    Text(user.role, style: TextStyle(fontSize: 11.5, color: tokens.accD)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(value: 'logout', child: Text('Sign out')),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    color: tokens.acc,
                    child: Text(
                      initials.isEmpty ? '?' : initials,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 7),
                  if (MediaQuery.sizeOf(context).width >= 1200) Text(user.role, style: TextStyle(fontSize: 12, color: tokens.ink2)),
                  Icon(PhosphorIconsRegular.caretDown, size: 12, color: tokens.ink3),
                ],
              ),
            ),
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
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: tokens.line)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user?.fullName ?? '—',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              Text(
                user?.role ?? '—',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11.5, color: tokens.accD),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 8),
            children: [for (final group in kNavGroups) _NavGroupSection(group: group, currentPath: currentPath)],
          ),
        ),
        InkWell(
          onTap: () => ref.read(authControllerProvider.notifier).logout(),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: tokens.line)),
            ),
            child: Row(
              children: [
                Icon(PhosphorIconsRegular.signOut, size: 16, color: tokens.ink2),
                const SizedBox(width: 10),
                Text('Sign out', style: TextStyle(fontSize: 12.5, color: tokens.ink2)),
              ],
            ),
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
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 3),
            child: Text(
              group.title.toUpperCase(),
              style: TextStyle(fontSize: 10, letterSpacing: 0.8, fontWeight: FontWeight.w700, color: context.tokens.ink3),
            ),
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

class _NavTile extends ConsumerWidget {
  const _NavTile({required this.item, required this.selected, required this.maybeLocked, this.trailingCount = 0});

  final NavItem item;
  final bool selected;
  final bool maybeLocked;
  final int trailingCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    return InkWell(
      onTap: () {
        // Every nav click starts the target page fresh — see
        // resetPerUserUiState's doc comment (core/auth/auth_providers.dart).
        resetPerUserUiStateFromWidget(ref);
        context.go(item.path);
      },
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 11),
        decoration: BoxDecoration(
          color: selected ? tokens.sel : Colors.transparent,
          border: Border(left: BorderSide(color: selected ? tokens.acc : Colors.transparent, width: 3)),
        ),
        child: Row(
          children: [
            Icon(item.icon, size: 16, color: selected ? tokens.accD : tokens.ink2),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12.5, color: selected ? tokens.ink : tokens.ink2, fontWeight: selected ? FontWeight.w600 : FontWeight.w400),
              ),
            ),
            if (trailingCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
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
          onDestinationSelected: (i) {
            resetPerUserUiStateFromWidget(ref);
            context.go(_flatItems[i].path);
          },
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

class _BottomNav extends ConsumerWidget {
  const _BottomNav({required this.currentPath});

  final String currentPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        resetPerUserUiStateFromWidget(ref);
        context.go(primary[i].path);
      },
      items: [
        for (final item in primary) BottomNavigationBarItem(icon: Icon(item.icon, size: 20), label: item.shortLabel ?? item.label),
        const BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'More'),
      ],
    );
  }
}
