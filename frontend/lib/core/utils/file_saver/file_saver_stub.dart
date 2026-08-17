/// Non-web fallback — desktop file-save (native save dialog) is a Phase 2+
/// follow-up once the Windows target is validated (see the approved plan's
/// run/test section). Web is Phase 1's primary target.
Future<void> saveBytes({required List<int> bytes, required String fileName, String? mimeType}) async {
  throw UnsupportedError('Download to disk is not yet implemented on this platform.');
}
