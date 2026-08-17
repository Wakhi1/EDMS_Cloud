import 'package:flutter/material.dart';

import '../../../../core/theme/pspf_tokens.dart';
import '../../../integrations/presentation/storage_browser_dialog.dart';

/// Lets the user override the batch's storage location: which configured
/// storage integration new uploads physically land in, and optionally a
/// specific/newly-created folder within it (reusing the same browse/create
/// machinery the Integrations screen uses for admin storage management —
/// here in `selectMode` so it returns a chosen prefix instead of just
/// browsing). Returns null on cancel; `(providerId: null, prefixOverride:
/// null)` means "reset to automatic" (global active provider, prefix
/// derived per-file from its repository folder).
class StorageLocationDialog extends StatefulWidget {
  const StorageLocationDialog({
    super.key,
    required this.storageIntegrations,
    required this.initialProviderId,
    this.initialPrefix,
  });

  final List<({String id, String name})> storageIntegrations;
  final String initialProviderId;
  final String? initialPrefix;

  static Future<({String? providerId, String? prefixOverride})?> show(
    BuildContext context, {
    required List<({String id, String name})> storageIntegrations,
    required String initialProviderId,
    String? initialPrefix,
  }) {
    return showDialog<({String? providerId, String? prefixOverride})>(
      context: context,
      builder: (_) => StorageLocationDialog(
        storageIntegrations: storageIntegrations,
        initialProviderId: initialProviderId,
        initialPrefix: initialPrefix,
      ),
    );
  }

  @override
  State<StorageLocationDialog> createState() => _StorageLocationDialogState();
}

class _StorageLocationDialogState extends State<StorageLocationDialog> {
  late String _providerId = widget.initialProviderId;
  late String? _prefix = widget.initialPrefix;

  Future<void> _browse() async {
    final integration = widget.storageIntegrations.firstWhere((i) => i.id == _providerId);
    final chosen = await showDialog<String>(
      context: context,
      builder: (_) => StorageBrowserDialog(
        integrationId: integration.id,
        integrationName: integration.name,
        selectMode: true,
        initialPrefix: _prefix ?? '',
      ),
    );
    if (chosen != null) setState(() => _prefix = chosen);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return AlertDialog(
      title: const Text('Storage location'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Where new uploads in this batch physically land. Applies to every file added.',
              style: TextStyle(fontSize: 12, color: tokens.ink2),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _providerId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Provider', isDense: true),
              items: [
                for (final i in widget.storageIntegrations) DropdownMenuItem(value: i.id, child: Text(i.name)),
              ],
              onChanged: (v) => setState(() {
                if (v != null) _providerId = v;
                _prefix = null; // a folder chosen for the old provider may not exist in the new one
              }),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _prefix == null || _prefix!.isEmpty ? 'Folder: derived automatically from each file\'s repository folder' : 'Folder: $_prefix',
                    style: TextStyle(fontSize: 12.5, color: tokens.ink2),
                  ),
                ),
                TextButton(onPressed: _browse, child: const Text('Browse / New folder')),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop((providerId: null, prefixOverride: null)),
          child: const Text('Reset to automatic'),
        ),
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.of(context).pop((providerId: _providerId, prefixOverride: _prefix)),
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
