import 'package:flutter/material.dart';

/// Matches document_storage_objects.provider's enum
/// (database/pspf_edms_schema.sql) — aws_s3/azure_blob/gcp_storage/local.
(IconData, String) storageProviderIconAndLabel(String provider) {
  return switch (provider) {
    'aws_s3' => (Icons.cloud_outlined, 'Amazon S3'),
    'azure_blob' => (Icons.cloud_queue_outlined, 'Azure Blob Storage'),
    'gcp_storage' => (Icons.cloud_circle_outlined, 'Google Cloud Storage'),
    'local' => (Icons.dns_outlined, 'Local storage'),
    _ => (Icons.help_outline, provider),
  };
}

/// Small badge indicating where a document's bytes (or, for a folder, its
/// direct documents' bytes) physically live. A folder can aggregate more
/// than one provider — see folders.routes.js's storage_providers subquery
/// — in which case this shows a "mixed" icon instead of picking one.
class StorageLocationIcon extends StatelessWidget {
  const StorageLocationIcon({super.key, required this.provider, this.size = 14, this.color});

  /// A single provider key, or a comma-separated list. Null/empty renders nothing.
  final String? provider;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final raw = provider;
    if (raw == null || raw.trim().isEmpty) return const SizedBox.shrink();
    final providers = raw.split(',').map((p) => p.trim()).where((p) => p.isNotEmpty).toSet();
    if (providers.length > 1) {
      final labels = providers.map((p) => storageProviderIconAndLabel(p).$2).join(', ');
      return Tooltip(message: 'Mixed storage: $labels', child: Icon(Icons.layers_outlined, size: size, color: color));
    }
    final (icon, label) = storageProviderIconAndLabel(providers.first);
    return Tooltip(message: label, child: Icon(icon, size: size, color: color));
  }
}
