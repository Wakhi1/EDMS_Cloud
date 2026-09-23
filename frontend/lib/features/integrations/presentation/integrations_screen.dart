import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/api/resources/api_keys_api.dart';
import '../../../core/models/integration_row.dart';
import '../../../core/models/storage_provider_ids.dart';
import '../../../core/theme/pspf_tokens.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/result_dialog.dart';
import '../../../core/widgets/status_chip.dart';
import '../../repository/providers/repository_providers.dart';
import '../providers/integrations_providers.dart';
import 'create_integration_dialog.dart';
import 'edit_integration_dialog.dart';
import 'integration_guides.dart';
import 'storage_explorer.dart';

const _kIntegrationIcons = <String, IconData>{
  'ad': PhosphorIconsDuotone.shieldCheck,
  'aws_s3': PhosphorIconsDuotone.cloud,
  'azure_blob': PhosphorIconsDuotone.cloud,
  'gcp_storage': PhosphorIconsDuotone.cloud,
  'local': PhosphorIconsDuotone.hardDrives,
  'smtp': PhosphorIconsDuotone.envelope,
  'hris': PhosphorIconsDuotone.usersThree,
  'sms': PhosphorIconsDuotone.chatText,
  'watched_folder': PhosphorIconsDuotone.eye,
  'ftp': PhosphorIconsDuotone.uploadSimple,
  'email_intake': PhosphorIconsDuotone.envelopeSimple,
  'webhook': PhosphorIconsDuotone.cloudArrowUp,
};

IconData _iconFor(String id) => _kIntegrationIcons[id] ?? PhosphorIconsDuotone.plugs;

/// Pseudo-entry in the list for the local watched-folder agent's API keys.
const _kAgentKeysId = '__agent_keys';

const _kGroups = <(String, List<String>)>[
  ('Storage', ['local', 'aws_s3', 'azure_blob', 'gcp_storage']),
  ('Capture', ['ftp', 'email_intake', 'watched_folder', _kAgentKeysId]),
  ('Sign-in & messaging', ['ad', 'smtp', 'sms']),
  ('Outbound', ['webhook']),
];

final _selectedIntegrationProvider = StateProvider.autoDispose<String?>((ref) => null);

class IntegrationsScreen extends ConsumerWidget {
  const IntegrationsScreen({super.key});

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<({String id, String name, String description, String endpoint, String status})>(
      context: context,
      builder: (_) => const CreateIntegrationDialog(),
    );
    if (result == null) return;

    try {
      await ref
          .read(integrationsApiProvider)
          .create(
            id: result.id,
            name: result.name,
            description: result.description.isNotEmpty ? result.description : null,
            endpoint: result.endpoint.isNotEmpty ? result.endpoint : null,
            status: result.status,
          );
      ref.invalidate(integrationsListProvider);
      ref.read(_selectedIntegrationProvider.notifier).state = result.id;
    } on ApiException catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final integrationsAsync = ref.watch(integrationsListProvider);
    final active = ref.watch(storageLocationProvider).valueOrNull;
    final wide = MediaQuery.sizeOf(context).width >= 900;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Integrations', style: Theme.of(context).textTheme.titleMedium),
                    Text('Administration / Integrations — storage, capture, sign-in and messaging', style: TextStyle(fontSize: 11, color: tokens.ink3)),
                  ],
                ),
              ),
              OutlinedButton.icon(onPressed: () => _create(context, ref), icon: const Icon(Icons.add, size: 16), label: const Text('Add integration')),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: integrationsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) =>
                  ErrorState(message: error is ApiException ? error.message : '$error', onRetry: () => ref.invalidate(integrationsListProvider)),
              data: (rows) {
                if (rows.isEmpty) return const EmptyState(message: 'No integrations configured.');
                final byId = {for (final r in rows) r.id: r};
                final grouped = <String>{for (final g in _kGroups) ...g.$2};
                final others = rows.where((r) => !grouped.contains(r.id)).map((r) => r.id).toList();
                final groups = [..._kGroups, if (others.isNotEmpty) ('Other', others)];
                final selectedId = ref.watch(_selectedIntegrationProvider) ?? rows.first.id;

                final list = _IntegrationList(groups: groups, byId: byId, selectedId: selectedId, activeStorage: active);
                final detail = selectedId == _kAgentKeysId
                    ? const SingleChildScrollView(child: _ApiKeysCard())
                    : byId[selectedId] == null
                    ? const EmptyState(message: 'Select an integration.')
                    : _IntegrationDetail(key: ValueKey(selectedId), row: byId[selectedId]!, isActiveStorage: active == selectedId);

                if (!wide) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: 180, child: list),
                      const SizedBox(height: 12),
                      Expanded(child: detail),
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(width: 250, child: list),
                    const SizedBox(width: 12),
                    Expanded(child: detail),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _IntegrationList extends ConsumerWidget {
  const _IntegrationList({required this.groups, required this.byId, required this.selectedId, required this.activeStorage});

  final List<(String, List<String>)> groups;
  final Map<String, IntegrationRow> byId;
  final String selectedId;
  final String? activeStorage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    Color statusColor(String status) => switch (status) {
      'connected' => tokens.ok,
      'error' => tokens.bad,
      _ => tokens.ink3,
    };

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: tokens.line),
        color: tokens.surf,
      ),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 8),
        children: [
          for (final (title, ids) in groups) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: Text(
                title.toUpperCase(),
                style: TextStyle(fontSize: 10, letterSpacing: 0.8, fontWeight: FontWeight.w700, color: tokens.ink3),
              ),
            ),
            for (final id in ids)
              if (id == _kAgentKeysId || byId.containsKey(id))
                InkWell(
                  onTap: () => ref.read(_selectedIntegrationProvider.notifier).state = id,
                  child: Container(
                    height: 34,
                    padding: const EdgeInsets.symmetric(horizontal: 9),
                    decoration: BoxDecoration(
                      color: selectedId == id ? tokens.sel : null,
                      border: Border(left: BorderSide(color: selectedId == id ? tokens.acc : Colors.transparent, width: 3)),
                    ),
                    child: Row(
                      children: [
                        Icon(id == _kAgentKeysId ? PhosphorIconsDuotone.key : _iconFor(id), size: 16, color: tokens.accD),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            id == _kAgentKeysId ? 'Local agent keys' : byId[id]!.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12.5, fontWeight: selectedId == id ? FontWeight.w600 : FontWeight.w400),
                          ),
                        ),
                        if (id == activeStorage)
                          Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            color: tokens.accT,
                            child: Text(
                              'ACTIVE',
                              style: TextStyle(fontSize: 8.5, letterSpacing: 0.4, color: tokens.accD, fontWeight: FontWeight.w700),
                            ),
                          ),
                        if (id != _kAgentKeysId)
                          Tooltip(
                            message: byId[id]!.status,
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor(byId[id]!.status)),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}

/// Selected integration: header with actions, then Settings (form + setup
/// guide) and — for storage — Browse.
class _IntegrationDetail extends ConsumerStatefulWidget {
  const _IntegrationDetail({super.key, required this.row, required this.isActiveStorage});

  final IntegrationRow row;
  final bool isActiveStorage;

  @override
  ConsumerState<_IntegrationDetail> createState() => _IntegrationDetailState();
}

class _IntegrationDetailState extends ConsumerState<_IntegrationDetail> {
  bool _testing = false;
  ({bool ok, String message})? _lastResult;
  int _tab = 0;

  bool get _isStorage => kStorageProviderIds.contains(widget.row.id);

  Future<void> _test() async {
    setState(() => _testing = true);
    try {
      final result = await ref.read(integrationsApiProvider).testConnection(widget.row.id);
      if (mounted) setState(() => _lastResult = result);
      ref.invalidate(integrationsListProvider);
    } on ApiException catch (e) {
      if (mounted) setState(() => _lastResult = (ok: false, message: e.message));
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _save(IntegrationEdit result) async {
    try {
      await ref
          .read(integrationsApiProvider)
          .update(
            widget.row.id,
            name: result.name.isNotEmpty ? result.name : null,
            description: result.description,
            status: result.status,
            endpoint: result.endpoint.isNotEmpty ? result.endpoint : null,
            configJson: result.configJson,
          );
      ref.invalidate(integrationsListProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${widget.row.name} saved.')));
    } on ApiException catch (e) {
      if (mounted) await ResultDialog.showError(context, e.message);
    }
  }

  Future<void> _makeActive() async {
    try {
      await ref.read(integrationsApiProvider).setStorageLocation(widget.row.id);
      ref.invalidate(storageLocationProvider);
      ref.invalidate(integrationsListProvider);
    } on ApiException catch (e) {
      if (mounted) await ResultDialog.showError(context, e.message);
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
      ref.read(_selectedIntegrationProvider.notifier).state = null;
      ref.invalidate(integrationsListProvider);
    } on ApiException catch (e) {
      if (mounted) await ResultDialog.showError(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final row = widget.row;
    final folders = ref.watch(foldersProvider).valueOrNull ?? const [];
    final guide = kIntegrationGuides[row.id];

    final settings = LayoutBuilder(
      builder: (context, constraints) {
        final form = EditIntegrationDialog(integration: row, folders: folders, onSubmit: _save);
        final guideBox = guide == null ? null : _GuidePanel(guide: guide);
        if (constraints.maxWidth < 760 || guideBox == null) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [?guideBox, if (guideBox != null) const SizedBox(height: 16), form]),
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: form),
            ),
            Container(width: 1, color: tokens.line),
            Expanded(
              flex: 4,
              child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: guideBox),
            ),
          ],
        );
      },
    );

    Widget tab(int index, String label, IconData icon) => InkWell(
      onTap: () => setState(() => _tab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: _tab == index ? tokens.acc : Colors.transparent, width: 2)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: _tab == index ? tokens.accD : tokens.ink2),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12.5, fontWeight: _tab == index ? FontWeight.w600 : FontWeight.w400)),
          ],
        ),
      ),
    );

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: tokens.line),
        color: tokens.surf,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 0),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  color: tokens.accT,
                  child: Icon(_iconFor(row.id), size: 18, color: tokens.accD),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              row.name,
                              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          StatusChip.forIntegrationStatus(row.status),
                          if (widget.isActiveStorage) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              color: tokens.accT,
                              child: Text(
                                'NEW UPLOADS GO HERE',
                                style: TextStyle(fontSize: 9, letterSpacing: 0.4, color: tokens.accD, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        guide?.summary ?? row.description ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11.5, color: tokens.ink2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (_isStorage && !widget.isActiveStorage)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: OutlinedButton(
                      onPressed: _makeActive,
                      child: const Text('Use for new uploads', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                OutlinedButton.icon(
                  onPressed: _testing ? null : _test,
                  icon: _testing
                      ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(PhosphorIconsRegular.plugsConnected, size: 14),
                  label: const Text('Test connection', style: TextStyle(fontSize: 12)),
                ),
                PopupMenuButton<String>(
                  tooltip: 'More',
                  icon: Icon(PhosphorIconsBold.dotsThreeVertical, size: 16, color: tokens.ink2),
                  itemBuilder: (_) => const [PopupMenuItem(value: 'delete', child: Text('Delete integration'))],
                  onSelected: (_) => _delete(),
                ),
              ],
            ),
          ),
          if (_lastResult != null)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              color: (_lastResult!.ok ? tokens.ok : tokens.bad).withValues(alpha: 0.08),
              child: Row(
                children: [
                  Icon(
                    _lastResult!.ok ? PhosphorIconsRegular.checkCircle : PhosphorIconsRegular.warningCircle,
                    size: 14,
                    color: _lastResult!.ok ? tokens.ok : tokens.bad,
                  ),
                  const SizedBox(width: 6),
                  Expanded(child: Text(_lastResult!.message, style: const TextStyle(fontSize: 12))),
                ],
              ),
            ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: tokens.line)),
            ),
            child: Row(children: [tab(0, 'Settings', PhosphorIconsRegular.gearSix), if (_isStorage) tab(1, 'Browse', PhosphorIconsRegular.folderOpen)]),
          ),
          Expanded(
            child: _tab == 1 && _isStorage
                ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: StorageExplorer(integrationId: row.id, integrationName: row.name),
                  )
                : settings,
          ),
        ],
      ),
    );
  }
}

class _GuidePanel extends StatelessWidget {
  const _GuidePanel({required this.guide});

  final IntegrationGuide guide;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(PhosphorIconsRegular.info, size: 15, color: tokens.accD),
            const SizedBox(width: 6),
            const Text('Setup guide', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 6),
        Text(guide.summary, style: TextStyle(fontSize: 12, color: tokens.ink2)),
        const SizedBox(height: 10),
        for (var i = 0; i < guide.steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 18,
                  height: 18,
                  alignment: Alignment.center,
                  color: tokens.accT,
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: tokens.accD),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(guide.steps[i], style: const TextStyle(fontSize: 12, height: 1.35))),
              ],
            ),
          ),
        for (final tip in guide.tips)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: tokens.warn.withValues(alpha: 0.08),
              border: Border(left: BorderSide(color: tokens.warn, width: 3)),
            ),
            child: Text(tip, style: const TextStyle(fontSize: 11.5, height: 1.35)),
          ),
      ],
    );
  }
}

/// Local watched-folder agent credentials: the folder-watching piece that
/// runs on someone's own PC (see /local-agent at the repo root) can't hold
/// a normal login session, so it authenticates with one of these long-lived
/// keys instead (routes/agentUpload.routes.js). The raw key is shown once,
/// at creation, then never again — only its prefix is kept for reference.
class _ApiKeysCard extends ConsumerStatefulWidget {
  const _ApiKeysCard();

  @override
  ConsumerState<_ApiKeysCard> createState() => _ApiKeysCardState();
}

class _ApiKeysCardState extends ConsumerState<_ApiKeysCard> {
  bool _creating = false;

  Future<void> _generate() async {
    final nameController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Generate agent API key'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name (e.g. "Records office PC")'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(nameController.text.trim()), child: const Text('Generate')),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;

    setState(() => _creating = true);
    try {
      final rawKey = await ref.read(apiKeysApiProvider).create(name);
      ref.invalidate(apiKeysListProvider);
      if (mounted) await _showRawKey(rawKey);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _showRawKey(String rawKey) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Copy this key now'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('This is the only time the full key is shown. Paste it into the local agent\'s config file.'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(border: Border.all(color: context.tokens.line2)),
                child: SelectableText(rawKey, style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5)),
              ),
            ],
          ),
        ),
        actions: [ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Done'))],
      ),
    );
  }

  Future<void> _revoke(ApiKeyRow key) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Revoke "${key.name}"?',
      body: 'The local agent using this key will stop being able to upload until it\'s given a new one.',
      okLabel: 'Revoke',
      danger: true,
    );
    if (confirmed == null) return;

    try {
      await ref.read(apiKeysApiProvider).revoke(key.id);
      ref.invalidate(apiKeysListProvider);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final keysAsync = ref.watch(apiKeysListProvider);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: tokens.line),
        color: tokens.surf,
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Local watched-folder agent', style: Theme.of(context).textTheme.titleSmall)),
              OutlinedButton.icon(onPressed: _creating ? null : _generate, icon: const Icon(Icons.add, size: 16), label: const Text('Generate key')),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'A folder on someone\'s own PC can feed this deployment without the server needing filesystem access to it. '
            'Generate a key here, then set it in the local agent\'s config — see /local-agent in the project for the script and setup steps.',
            style: TextStyle(fontSize: 12, color: tokens.ink2),
          ),
          const SizedBox(height: 12),
          keysAsync.when(
            loading: () => const SizedBox(height: 30, child: LinearProgressIndicator()),
            error: (error, _) => Text(error is ApiException ? error.message : '$error', style: TextStyle(color: tokens.bad, fontSize: 12)),
            data: (keys) {
              if (keys.isEmpty) return Text('No keys generated yet.', style: TextStyle(fontSize: 12, color: tokens.ink3));
              return Column(
                children: [
                  for (final k in keys)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: tokens.line2)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${k.name} · ${k.keyPrefix}…', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                                Text(
                                  k.revokedAt != null
                                      ? 'Revoked'
                                      : k.lastUsedAt != null
                                      ? 'Last used ${k.lastUsedAt}'
                                      : 'Never used yet',
                                  style: TextStyle(fontSize: 11, color: tokens.ink3),
                                ),
                              ],
                            ),
                          ),
                          if (k.revokedAt == null)
                            OutlinedButton(
                              onPressed: () => _revoke(k),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: tokens.bad,
                                side: BorderSide(color: tokens.bad),
                              ),
                              child: const Text('Revoke', style: TextStyle(fontSize: 11.5)),
                            ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
