/// Simple binary-prefix formatter (KB/MB/GB, 1024-based). Shared by the
/// Dashboard's storage-capacity KPI and Reports' capacity card — the only
/// other size formatter in the app (backup_screen.dart's `_formatSize`)
/// tops out at MB, which doesn't suit a capacity figure that defaults to
/// 100 GB.
String formatBytes(int bytes) {
  if (bytes >= 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  if (bytes >= 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  return '$bytes B';
}
