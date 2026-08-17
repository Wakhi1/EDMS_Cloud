/// Best-effort mimetype guess from a file extension — used wherever a
/// picked file's bytes need a Content-Type for multipart upload (file_picker
/// v12's PlatformFile no longer exposes mimetype directly, only a name).
String? extensionOf(String fileName) {
  final dot = fileName.lastIndexOf('.');
  if (dot < 0 || dot == fileName.length - 1) return null;
  return fileName.substring(dot + 1);
}

String mimeTypeForExtension(String? ext) {
  switch ((ext ?? '').toLowerCase()) {
    case 'pdf':
      return 'application/pdf';
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'png':
      return 'image/png';
    case 'tif':
    case 'tiff':
      return 'image/tiff';
    case 'docx':
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    case 'xlsx':
      return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    case 'xls':
      return 'application/vnd.ms-excel';
    case 'txt':
      return 'text/plain';
    default:
      return 'application/octet-stream';
  }
}
