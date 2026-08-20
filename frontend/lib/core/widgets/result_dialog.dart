import 'package:flutter/material.dart';

import '../theme/pspf_tokens.dart';

/// Modal (not auto-fading, dismiss-on-purpose) success/error feedback for
/// key actions — delete, CRUD, permission changes — so the outcome of
/// something consequential can't be missed the way a SnackBar can be by
/// glancing away for a moment. Routine/low-stakes feedback still uses
/// SnackBar as before; this is deliberately reserved for the actions that
/// follow a "danger: true" ConfirmDialog (or an equivalent permission
/// change) elsewhere in the app.
class ResultDialog {
  const ResultDialog._();

  static Future<void> showSuccess(BuildContext context, String message) {
    return _show(context, message: message, isError: false);
  }

  static Future<void> showError(BuildContext context, String message) {
    return _show(context, message: message, isError: true);
  }

  static Future<void> _show(BuildContext context, {required String message, required bool isError}) {
    final tokens = context.tokens;
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          isError ? Icons.error_outline : Icons.check_circle_outline,
          color: isError ? tokens.bad : tokens.ok,
          size: 32,
        ),
        content: Text(message, textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('OK')),
        ],
      ),
    );
  }
}
