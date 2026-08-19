import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/models/integration_row.dart';
import '../../../core/models/storage_provider_ids.dart';
import '../../../core/theme/pspf_tokens.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/status_chip.dart';
import '../../repository/providers/repository_providers.dart';
import '../providers/integrations_providers.dart';
import 'create_integration_dialog.dart';
import 'edit_integration_dialog.dart';
import 'import_from_storage_dialog.dart';
import 'storage_browser_dialog.dart';


const _kIntegrationIcons = <String, IconData>{
  'ad': PhosphorIconsDuotone.shieldCheck,
  'aws_s3': PhosphorIconsDuotone.folder,
  'azure_blob': PhosphorIconsDuotone.folder,
  'gcp_storage': PhosphorIconsDuotone.folder,
  'local': PhosphorIconsDuotone.folder,
  'smtp': PhosphorIconsDuotone.bell,
  'hris': PhosphorIconsDuotone.usersThree,
  'sms': PhosphorIconsDuotone.plugs,
  'watched_folder': PhosphorIconsDuotone.eye,
  'ftp': PhosphorIconsDuotone.uploadSimple,
  'email_intake': PhosphorIconsDuotone.envelopeSimple,
};

IconData _iconFor(String id) => _kIntegrationIcons[id] ?? PhosphorIconsDuotone.plugs;

class IntegrationsScreen extends ConsumerWidget {
  const IntegrationsScreen({super.key});

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<({String id, String name, String description, String endpoint, String status})>(
      context: context,
      builder: (_) => const CreateIntegrationDialog(),
    );
    if (result == null) return;

    try {
      await ref.read(integrationsApiProvider).create(
            id: result.id,
            name: result.name,
            description: result.description.isNotEmpty ? result.description : null,
            endpoint: result.endpoint.isNotEmpty ? result.endpoint : null,
            status: result.status,
          );
      ref.invalidate(integrationsListProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Integration created.')));
      }
    } on ApiException catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final integrationsAsync = ref.watch(integrationsListProvider);

    return Padding(
      padding: const EdgeInsets.all(18),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Administration / Integrations', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _create(context, ref),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add integration'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const _StorageLocationCard(),
            const SizedBox(height: 20),
            Text('Connected systems', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 10),
            integrationsAsync.when(
              loading: () => const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
              error: (error, _) => ErrorState(
                message: error is ApiException ? error.message : '$error',
                onRetry: () => ref.invalidate(integrationsListProvider),
              ),
              data: (rows) {
                if (rows.isEmpty) return const EmptyState(message: 'No integrations configured.');
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 320,
                    mainAxisExtent: 250,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: rows.length,
                  itemBuilder: (context, i) => _IntegrationCard(row: rows[i]),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StorageLocationCard extends ConsumerWidget {
  const _StorageLocationCard();

  Future<void> _select(BuildContext context, WidgetRef ref, String provider) async {
    try {
      await ref.read(integrationsApiProvider).setStorageLocation(provider);
      ref.invalidate(storageLocationProvider);
      ref.invalidate(integrationsListProvider);
    } on ApiException catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final activeAsync = ref.watch(storageLocationProvider);

    return Container(
      decoration: BoxDecoration(border: Border.all(color: tokens.line), color: tokens.surf),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Storage location', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            'New document uploads go to whichever provider is selected below. Existing documents keep reading from wherever they were originally stored.',
            style: TextStyle(fontSize: 12, color: tokens.ink2),
          ),
          const SizedBox(height: 12),
          activeAsync.when(
            loading: () => const SizedBox(height: 30, child: LinearProgressIndicator()),
            error: (error, _) => Text('$error', style: TextStyle(color: tokens.bad, fontSize: 12)),
            data: (active) => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final id in kStorageProviderIds)
                  OutlinedButton.icon(
                    onPressed: id == active ? null : () => _select(context, ref, id),
                    icon: id == active ? const Icon(Icons.check, size: 15) : const SizedBox.shrink(),
                    label: Text(id),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: id == active ? tokens.sel : null,
                      side: BorderSide(color: id == active ? tokens.acc : tokens.line2),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IntegrationCard extends ConsumerStatefulWidget {
  const _IntegrationCard({required this.row});

  final IntegrationRow row;

  @override
  ConsumerState<_IntegrationCard> createState() => _IntegrationCardState();
}

class _IntegrationCardState extends ConsumerState<_IntegrationCard> {
  bool _testing = false;
  ({bool ok, String message})? _lastResult;

  Future<void> _test() async {
    setState(() => _testing = true);
    try {
      final result = await ref.read(integrationsApiProvider).testConnection(widget.row.id);
      setState(() => _lastResult = result);
      ref.invalidate(integrationsListProvider);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _edit() async {
    final result = await showDialog<({String name, String description, String status, String endpoint, Map<String, dynamic>? configJson})>(
      context: context,
      builder: (_) => EditIntegrationDialog(integration: widget.row),
    );
    if (result == null) return;

    try {
      await ref.read(integrationsApiProvider).update(
            widget.row.id,
            name: result.name.isNotEmpty ? result.name : null,
            description: result.description,
            status: result.status,
            endpoint: result.endpoint.isNotEmpty ? result.endpoint : null,
            configJson: result.configJson,
          );
      ref.invalidate(integrationsListProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Integration updated.')));
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _delete() async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete ${widget.row.name}?',
      body: 'This removes the integration entry. This cannot be undone.',
      okLabel: 'Delete',
      danger: true,
    );
    if (confirmed == null) return;

    try {
      await ref.read(integrationsApiProvider).delete(widget.row.id);
      ref.invalidate(integrationsListProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Integration deleted.')));
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  void _browse() {
    showDialog<void>(
      context: context,
      builder: (_) => StorageBrowserDialog(integrationId: widget.row.id, integrationName: widget.row.name),
    );
  }

  /// Two-step: pick a source prefix via the existing browse dialog (in
  /// select mode, so it can also create a folder there first if needed),
  /// then configure and run the import against it.
  Future<void> _import() async {
    final prefix = await showDialog<String>(
      context: context,
      builder: (_) => StorageBrowserDialog(integrationId: widget.row.id, integrationName: widget.row.name, selectMode: true),
    );
    if (prefix == null || !mounted) return;

    final result = await showDialog<({int importedCount, int skippedCount})>(
      context: context,
      builder: (_) => ImportFromStorageDialog(integrationId: widget.row.id, integrationName: widget.row.name, prefix: prefix),
    );
    if (result == null || !mounted) return;

    ref.invalidate(repositoryDocumentsProvider);
    ref.invalidate(foldersProvider);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Imported ${result.importedCount} file(s)'
          '${result.skippedCount > 0 ? ' (${result.skippedCount} skipped as duplicates)' : ''}.'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final row = widget.row;
    final isStorage = kStorageProviderIds.contains(row.id);

    return Container(
      decoration: BoxDecoration(border: Border.all(color: tokens.line), color: tokens.surf),
      padding: const EdgeInsets.all(13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(_iconFor(row.id), size: 24, color: tokens.accD),
              const SizedBox(width: 8),
              Expanded(
                child: Text(row.name, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700), maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
              StatusChip.forIntegrationStatus(row.status),
            ],
          ),
          if (row.description != null) ...[
            const SizedBox(height: 6),
            Text(row.description!, style: TextStyle(fontSize: 12, color: tokens.ink2), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 6),
          if (row.endpoint != null)
            Text(row.endpoint!, style: TextStyle(fontSize: 11, color: tokens.ink3), maxLines: 1, overflow: TextOverflow.ellipsis)
          else if (row.lastSyncAt != null)
            Text('Last sync ${row.lastSyncAt}', style: TextStyle(fontSize: 11, color: tokens.ink3)),
          if (_lastResult != null) ...[
            const SizedBox(height: 4),
            Text(
              '${_lastResult!.ok ? '✓' : '✗'} ${_lastResult!.message}',
              style: TextStyle(fontSize: 11, color: _lastResult!.ok ? tokens.ok : tokens.bad),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const Spacer(),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              OutlinedButton(
                onPressed: _testing ? null : _test,
                child: _testing
                    ? const SizedBox(height: 12, width: 12, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Test connection', style: TextStyle(fontSize: 11.5)),
              ),
              OutlinedButton(onPressed: _edit, child: const Text('Edit', style: TextStyle(fontSize: 11.5))),
              OutlinedButton(onPressed: _delete, child: const Text('Delete', style: TextStyle(fontSize: 11.5))),
              if (isStorage) OutlinedButton(onPressed: _browse, child: const Text('Browse folders', style: TextStyle(fontSize: 11.5))),
              if (isStorage) OutlinedButton(onPressed: _import, child: const Text('Import', style: TextStyle(fontSize: 11.5))),
            ],
          ),
        ],
      ),
    );
  }
}
