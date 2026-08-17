import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/models/notification_item.dart';
import '../../../core/theme/pspf_tokens.dart';
import '../../../core/widgets/empty_state.dart';
import '../../dashboard/providers/dashboard_providers.dart';
import '../providers/notifications_providers.dart';

/// The right-hand slide-in "bar" from the design mockup
/// (`sc-if value="{{ notifOpen }}"` — a 330px overlay panel sliding in from
/// the right, not a full-page navigation). Used as the app's `endDrawer`,
/// opened by the top-bar bell icon via `Scaffold.of(context).openEndDrawer()`
/// instead of `context.go('/notifications')`.
class NotificationsPanel extends ConsumerStatefulWidget {
  const NotificationsPanel({super.key});

  @override
  ConsumerState<NotificationsPanel> createState() => _NotificationsPanelState();
}

class _NotificationsPanelState extends ConsumerState<NotificationsPanel> {
  bool _markingAll = false;

  void _refresh() {
    ref.invalidate(notificationsListProvider);
    ref.invalidate(dashboardNotificationsProvider);
  }

  Future<void> _markAllRead() async {
    setState(() => _markingAll = true);
    try {
      await ref.read(notificationsApiProvider).markAllRead();
      _refresh();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _markingAll = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final notifsAsync = ref.watch(notificationsListProvider);
    final hasUnread = notifsAsync.valueOrNull?.any((n) => !n.isRead) ?? false;

    return Drawer(
      width: 330,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Column(
        children: [
          Container(
            color: tokens.bar,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Notifications',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: tokens.barInk),
                  ),
                ),
                OutlinedButton(
                  onPressed: (!hasUnread || _markingAll) ? null : _markAllRead,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: tokens.barInk,
                    side: BorderSide(color: tokens.barInk.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: _markingAll
                      ? SizedBox(height: 12, width: 12, child: CircularProgressIndicator(strokeWidth: 2, color: tokens.barInk))
                      : const Text('Mark all read', style: TextStyle(fontSize: 11)),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 18, color: tokens.barInk),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Expanded(
            child: notifsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    error is ApiException ? error.message : '$error',
                    style: TextStyle(color: tokens.bad),
                  ),
                ),
              ),
              data: (items) {
                if (items.isEmpty) return const EmptyState(message: 'No notifications yet.');
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) => Divider(height: 1, color: tokens.line),
                  itemBuilder: (context, i) => _NotificationRow(item: items[i], onChanged: _refresh),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationRow extends ConsumerStatefulWidget {
  const _NotificationRow({required this.item, required this.onChanged});

  final NotificationItem item;
  final VoidCallback onChanged;

  @override
  ConsumerState<_NotificationRow> createState() => _NotificationRowState();
}

class _NotificationRowState extends ConsumerState<_NotificationRow> {
  bool _marking = false;

  Future<void> _markRead() async {
    if (widget.item.isRead || _marking) return;
    setState(() => _marking = true);
    try {
      await ref.read(notificationsApiProvider).markRead(widget.item.id);
      widget.onChanged();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _marking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final item = widget.item;

    return InkWell(
      onTap: _markRead,
      child: Container(
        color: item.isRead ? null : tokens.sel,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: _marking
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(PhosphorIconsDuotone.bell, size: 18, color: tokens.accD),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(fontSize: 13, fontWeight: item.isRead ? FontWeight.w400 : FontWeight.w700),
                  ),
                  if (item.body != null) ...[
                    const SizedBox(height: 3),
                    Text(item.body!, style: TextStyle(fontSize: 11.5, color: tokens.ink2)),
                  ],
                  const SizedBox(height: 3),
                  Text(
                    item.createdAt?.replaceFirst('T', ' ').split('.').first ?? '—',
                    style: TextStyle(fontSize: 10.5, color: tokens.ink3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
