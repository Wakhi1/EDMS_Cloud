import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/models/notification_item.dart';
import '../../../core/theme/pspf_tokens.dart';
import '../../../core/widgets/empty_state.dart';
import '../../dashboard/providers/dashboard_providers.dart';
import '../providers/notifications_providers.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
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
    final notifsAsync = ref.watch(notificationsListProvider);
    final hasUnread = notifsAsync.valueOrNull?.any((n) => !n.isRead) ?? false;

    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Work / Notifications', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              ElevatedButton(
                onPressed: (!hasUnread || _markingAll) ? null : _markAllRead,
                child: _markingAll
                    ? const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Mark all read'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: notifsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => ErrorState(
                message: error is ApiException ? error.message : '$error',
                onRetry: () => ref.invalidate(notificationsListProvider),
              ),
              data: (items) {
                if (items.isEmpty) return const EmptyState(message: 'No notifications yet.');
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => _NotificationCard(item: items[i], onChanged: _refresh),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends ConsumerStatefulWidget {
  const _NotificationCard({required this.item, required this.onChanged});

  final NotificationItem item;
  final VoidCallback onChanged;

  @override
  ConsumerState<_NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends ConsumerState<_NotificationCard> {
  bool _marking = false;

  Future<void> _markRead() async {
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

    return Container(
      decoration: BoxDecoration(
        color: tokens.surf,
        border: Border.all(color: tokens.line),
        borderRadius: BorderRadius.zero,
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!item.isRead) Container(height: 3, color: tokens.acc, margin: const EdgeInsets.only(bottom: 10)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: TextStyle(fontSize: 13.5, fontWeight: item.isRead ? FontWeight.w400 : FontWeight.w700)),
                    if (item.body != null) ...[
                      const SizedBox(height: 4),
                      Text(item.body!, style: TextStyle(fontSize: 12.5, color: tokens.ink2)),
                    ],
                    const SizedBox(height: 6),
                    Text(item.createdAt?.replaceFirst('T', ' ').split('.').first ?? '—', style: TextStyle(fontSize: 11, color: tokens.ink2)),
                  ],
                ),
              ),
              if (!item.isRead)
                OutlinedButton(
                  onPressed: _marking ? null : _markRead,
                  child: _marking
                      ? const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Mark read'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
