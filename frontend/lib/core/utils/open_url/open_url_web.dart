import 'package:web/web.dart' as web;

/// Opens [url] in a new browser tab — used by the public share-view page's
/// Download button, a plain GET the browser handles itself (no bytes pass
/// through Dio, unlike the rest of the app's downloads).
void openUrlInNewTab(String url) {
  web.window.open(url, '_blank');
}
