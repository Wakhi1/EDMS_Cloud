import 'package:flutter/material.dart';

import '../theme/pspf_tokens.dart';

/// Generic confirm dialog matching the mockup's pervasive pattern: title +
/// optional body + optional key/value rows table + optional text field +
/// optional note + danger-styled confirm button. Covers the vast majority
/// of mutating-action confirmations across the app (approve/reject,
/// delete, disable user, revoke share, ...).
///
/// Returns the text field's value (or '' if there's no field) when
/// confirmed, `null` if cancelled/dismissed.
class ConfirmDialog extends StatefulWidget {
  const ConfirmDialog({
    super.key,
    required this.title,
    this.body,
    this.rows,
    this.fieldLabel,
    this.initialFieldValue = '',
    this.note,
    this.danger = false,
    this.okLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
  });

  final String title;
  final String? body;
  final List<(String, String)>? rows;
  final String? fieldLabel;
  final String initialFieldValue;
  final String? note;
  final bool danger;
  final String okLabel;
  final String cancelLabel;

  static Future<String?> show(
    BuildContext context, {
    required String title,
    String? body,
    List<(String, String)>? rows,
    String? fieldLabel,
    String initialFieldValue = '',
    String? note,
    bool danger = false,
    String okLabel = 'Confirm',
    String cancelLabel = 'Cancel',
  }) {
    return showDialog<String>(
      context: context,
      builder: (_) => ConfirmDialog(
        title: title,
        body: body,
        rows: rows,
        fieldLabel: fieldLabel,
        initialFieldValue: initialFieldValue,
        note: note,
        danger: danger,
        okLabel: okLabel,
        cancelLabel: cancelLabel,
      ),
    );
  }

  @override
  State<ConfirmDialog> createState() => _ConfirmDialogState();
}

class _ConfirmDialogState extends State<ConfirmDialog> {
  late final _controller = TextEditingController(text: widget.initialFieldValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      title: Text(widget.title, style: textTheme.titleMedium),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.body != null) Text(widget.body!, style: textTheme.bodyMedium?.copyWith(color: tokens.ink2)),
              if (widget.rows != null) ...[
                const SizedBox(height: 10),
                for (final (k, v) in widget.rows!)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 130, child: Text(k.toUpperCase(), style: textTheme.labelSmall)),
                        Expanded(child: Text(v, style: textTheme.bodyMedium)),
                      ],
                    ),
                  ),
              ],
              if (widget.fieldLabel != null) ...[
                const SizedBox(height: 12),
                Text(widget.fieldLabel!.toUpperCase(), style: textTheme.labelMedium),
                const SizedBox(height: 4),
                TextField(controller: _controller, autofocus: true),
              ],
              if (widget.note != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: tokens.surf2,
                    border: Border(left: BorderSide(color: tokens.warn, width: 3)),
                  ),
                  child: Text(widget.note!, style: textTheme.bodySmall?.copyWith(color: tokens.ink2)),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(widget.cancelLabel)),
        widget.danger
            ? ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: tokens.bad),
                onPressed: () => Navigator.of(context).pop(_controller.text),
                child: Text(widget.okLabel),
              )
            : ElevatedButton(
                onPressed: () => Navigator.of(context).pop(_controller.text),
                child: Text(widget.okLabel),
              ),
      ],
    );
  }
}
