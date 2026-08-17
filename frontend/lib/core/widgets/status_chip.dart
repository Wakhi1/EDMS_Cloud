import 'package:flutter/material.dart';

import '../theme/pspf_tokens.dart';

enum StatusTone { ok, warn, bad, info, plain }

/// Flat, rectangular status pill matching the mockup's `c.ok/c.warn/c.bad/
/// c.info` table-cell treatment — a 1px border in the tone colour, no fill.
class StatusChip extends StatelessWidget {
  const StatusChip(this.label, {super.key, this.tone = StatusTone.plain});

  final String label;
  final StatusTone tone;

  /// Maps the backend's `documents.status` enum to a tone.
  factory StatusChip.forDocumentStatus(String status) {
    final tone = switch (status) {
      'approved' || 'declared_final' || 'archived' => StatusTone.ok,
      'pending_approval' => StatusTone.warn,
      'rejected' || 'disposed' => StatusTone.bad,
      'draft' => StatusTone.info,
      _ => StatusTone.plain,
    };
    return StatusChip(status.replaceAll('_', ' '), tone: tone);
  }

  /// Maps the backend's `integrations.status` enum to a tone.
  factory StatusChip.forIntegrationStatus(String status) {
    final tone = switch (status) {
      'connected' => StatusTone.ok,
      'error' => StatusTone.bad,
      'disconnected' => StatusTone.plain,
      _ => StatusTone.plain,
    };
    return StatusChip(status, tone: tone);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final color = switch (tone) {
      StatusTone.ok => tokens.ok,
      StatusTone.warn => tokens.warn,
      StatusTone.bad => tokens.bad,
      StatusTone.info => tokens.info,
      StatusTone.plain => tokens.ink2,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(border: Border.all(color: color)),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: color),
      ),
    );
  }
}
