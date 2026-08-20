import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/models/backup_row.dart';
import '../../../core/theme/pspf_tokens.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/result_dialog.dart';
import '../../../core/widgets/status_chip.dart';
import '../providers/backup_providers.dart';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _running = false;

  Future<void> _runBackup() async {
    setState(() => _running = true);
    try {
      await ref.read(backupApiProvider).run();
      ref.invalidate(backupsListProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Backup completed and pushed to the active storage provider.')));
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final backupsAsync = ref.watch(backupsListProvider);

    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Administration / Backup & Disaster Recovery', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _running ? null : _runBackup,
                icon: _running
                    ? const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.backup, size: 16),
                label: const Text('Run backup now'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _DisasterRecoveryPanel(),
                  const SizedBox(height: 16),
                  Text('Backup history', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  backupsAsync.when(
                    loading: () => const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
                    error: (error, _) => ErrorState(
                      message: error is ApiException ? error.message : '$error',
                      onRetry: () => ref.invalidate(backupsListProvider),
                    ),
                    data: (rows) {
                      if (rows.isEmpty) return const EmptyState(message: 'No backups yet — run one to get started.');
                      return Container(
                        decoration: BoxDecoration(border: Border.all(color: context.tokens.line)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              color: context.tokens.surf2,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                              child: Row(
                                children: [
                                  Expanded(flex: 3, child: Text('File', style: Theme.of(context).textTheme.labelSmall)),
                                  Expanded(child: Text('Size', style: Theme.of(context).textTheme.labelSmall)),
                                  Expanded(child: Text('Provider', style: Theme.of(context).textTheme.labelSmall)),
                                  Expanded(child: Text('Status', style: Theme.of(context).textTheme.labelSmall)),
                                  Expanded(flex: 2, child: Text('Created', style: Theme.of(context).textTheme.labelSmall)),
                                  const SizedBox(width: 90),
                                ],
                              ),
                            ),
                            for (final b in rows) _BackupRowTile(row: b),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackupRowTile extends ConsumerWidget {
  const _BackupRowTile({required this.row});

  final BackupRow row;

  String _formatSize(int? bytes) {
    if (bytes == null) return '—';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    final phrase = await ConfirmDialog.show(
      context,
      title: 'Restore "${row.fileKey}"?',
      body: 'This overwrites the live database with this backup\'s contents. A fresh safety backup of the current state is taken automatically first, but this action is otherwise immediate and irreversible without another restore.',
      fieldLabel: 'Type the file name exactly to confirm',
      note: 'Type: ${row.fileKey}',
      okLabel: 'Restore now',
      danger: true,
    );
    if (phrase == null || phrase.isEmpty) return;

    try {
      await ref.read(backupApiProvider).restore(row.id, phrase);
      ref.invalidate(backupsListProvider);
      if (context.mounted) await ResultDialog.showSuccess(context, 'Restore completed.');
    } on ApiException catch (e) {
      if (context.mounted) await ResultDialog.showError(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: tokens.line))),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(row.fileKey, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
          Expanded(child: Text(_formatSize(row.sizeBytes), style: const TextStyle(fontSize: 12.5))),
          Expanded(child: Text(row.storageProvider, style: const TextStyle(fontSize: 12.5))),
          Expanded(
            child: StatusChip(
              row.status,
              tone: row.status == 'completed' ? StatusTone.ok : (row.status == 'failed' ? StatusTone.bad : StatusTone.warn),
            ),
          ),
          Expanded(flex: 2, child: Text(row.createdAt, style: TextStyle(fontSize: 11.5, color: tokens.ink2))),
          SizedBox(
            width: 90,
            child: row.status == 'completed'
                ? OutlinedButton(onPressed: () => _restore(context, ref), child: const Text('Restore', style: TextStyle(fontSize: 11.5)))
                : null,
          ),
        ],
      ),
    );
  }
}

class _DisasterRecoveryPanel extends StatelessWidget {
  const _DisasterRecoveryPanel();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      decoration: BoxDecoration(border: Border.all(color: tokens.line), color: tokens.surf),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Disaster recovery arrangements', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          const _DrLine('Recovery Point Objective (RPO)', 'Up to 24 hours of data loss if the automatic nightly backup is enabled in System Settings, or since the last manual "Run backup now".'),
          const _DrLine('Recovery Time Objective (RTO)', 'Typically under 15 minutes for a database restore via this screen, given a reachable database server.'),
          const _DrLine('Where backups live', 'Every backup is AES-256-GCM encrypted (same envelope encryption as documents) and pushed to the storage provider currently active in Integrations — never left as plaintext on this server.'),
          const _DrLine('Full server/infrastructure loss', 'This screen restores the application\'s data, not infrastructure. Provisioning a new server, restoring this codebase, and pointing it at a restored database is a manual runbook step outside this app\'s scope — contact ICT.'),
          const _DrLine('Who to contact', 'ICT department users are notified automatically on every backup and restore (see Notifications).'),
        ],
      ),
    );
  }
}

class _DrLine extends StatelessWidget {
  const _DrLine(this.label, this.body);

  final String label;
  final String body;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
          Text(body, style: TextStyle(fontSize: 12, color: tokens.ink2)),
        ],
      ),
    );
  }
}
