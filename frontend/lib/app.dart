import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/branding/branding_provider.dart';
import 'core/models/company_branding.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_provider.dart';
import 'core/utils/page_meta/page_meta.dart';

class PspfEdmsApp extends ConsumerWidget {
  const PspfEdmsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    final branding = ref.watch(companyBrandingProvider).valueOrNull ?? CompanyBranding.fallback;

    // Browser tab title/favicon — MaterialApp.title below only covers
    // Flutter's own Title widget; the actual <title>/<link rel="icon">
    // elements in web/index.html need updating directly once branding
    // loads (no-op on non-web platforms, see page_meta_stub.dart).
    ref.listen(companyBrandingProvider, (_, next) {
      final b = next.valueOrNull;
      if (b == null) return;
      updatePageMeta(title: b.shortLabel, faviconUrl: b.hasFavicon ? brandingFaviconUrl() : null);
    });

    return MaterialApp.router(
      title: branding.shortLabel,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(branding: branding),
      darkTheme: AppTheme.dark(branding: branding),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
