import 'package:flutter/material.dart';

const kCaptureSources = <String>['network_scanner', 'watched_folder', 'email_intake', 'device_upload'];

/// Records a completed capture batch. Returns the entered values on Save,
/// null on cancel — the actual `recordCaptureBatch()` call happens in the
/// caller (capture_screen.dart), same "pure form, caller mutates" shape as
/// EditRetentionClassDialog.
class RecordCaptureBatchDialog extends StatefulWidget {
  const RecordCaptureBatchDialog({super.key});

  @override
  State<RecordCaptureBatchDialog> createState() => _RecordCaptureBatchDialogState();
}

class _RecordCaptureBatchDialogState extends State<RecordCaptureBatchDialog> {
  final _batchNoController = TextEditingController();
  final _pagesController = TextEditingController(text: '0');
  final _documentsController = TextEditingController(text: '0');
  final _successRateController = TextEditingController(text: '100');
  String _source = kCaptureSources.first;

  @override
  void dispose() {
    _batchNoController.dispose();
    _pagesController.dispose();
    _documentsController.dispose();
    _successRateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Record capture batch'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(controller: _batchNoController, decoration: const InputDecoration(labelText: 'Batch no.')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _source,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Source'),
              items: [for (final s in kCaptureSources) DropdownMenuItem(value: s, child: Text(s.replaceAll('_', ' ')))],
              onChanged: (v) => setState(() => _source = v ?? _source),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _pagesController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Pages'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _documentsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Documents'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _successRateController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Success rate (%)'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            final batchNo = _batchNoController.text.trim();
            if (batchNo.isEmpty) return;
            Navigator.of(context).pop((
              batchNo: batchNo,
              source: _source,
              pages: int.tryParse(_pagesController.text) ?? 0,
              documents: int.tryParse(_documentsController.text) ?? 0,
              successRate: double.tryParse(_successRateController.text) ?? 0,
            ));
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
