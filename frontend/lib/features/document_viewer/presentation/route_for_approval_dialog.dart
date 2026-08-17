import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/theme/pspf_tokens.dart';
import '../../workflow_designer/providers/workflow_providers.dart';

/// Picks one of the existing workflows and returns its id, or null if
/// cancelled. The actual `startInstance` call happens in the caller
/// (viewer_screen.dart) so this dialog stays a pure picker.
class RouteForApprovalDialog extends ConsumerWidget {
  const RouteForApprovalDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final workflowsAsync = ref.watch(workflowsProvider);

    return AlertDialog(
      title: const Text('Route for approval'),
      content: SizedBox(
        width: 380,
        child: workflowsAsync.when(
          loading: () => const SizedBox(height: 60, child: Center(child: CircularProgressIndicator())),
          error: (e, _) => Text(e is ApiException ? e.message : '$e', style: TextStyle(color: tokens.bad)),
          data: (workflows) {
            if (workflows.isEmpty) {
              return const Text('No workflows have been defined yet. Create one in Workflow Designer first.');
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('The record is locked to its first step until authorised.'),
                const SizedBox(height: 12),
                for (final w in workflows)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(w.name),
                    subtitle: Text(
                      w.steps.isEmpty ? 'No steps configured' : '${w.steps.length} step(s), starting with ${w.steps.first.stepName}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    onTap: w.steps.isEmpty ? null : () => Navigator.of(context).pop(w.id),
                  ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
      ],
    );
  }
}
