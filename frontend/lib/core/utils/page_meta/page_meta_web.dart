import 'package:web/web.dart' as web;

/// Updates the browser tab title and (if [faviconUrl] is given) the
/// favicon `<link>` element — called from app.dart whenever branding
/// loads/changes, so a licensed company's own name/icon replaces the
/// static build-time defaults in web/index.html without needing a
/// separate build per client.
void updatePageMeta({required String title, String? faviconUrl}) {
  web.document.title = title;
  if (faviconUrl == null) return;

  final existing = web.document.querySelector('link[rel="icon"]');
  if (existing != null) {
    (existing as web.HTMLLinkElement).href = faviconUrl;
    return;
  }
  final link = web.HTMLLinkElement()
    ..rel = 'icon'
    ..href = faviconUrl;
  web.document.head?.append(link);
}
