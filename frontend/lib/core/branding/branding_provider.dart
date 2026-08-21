import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_providers.dart';
import '../api/endpoints.dart';
import '../env/env.dart';
import '../models/company_branding.dart';

/// Fetched once per app session (not autoDispose) — the login screen, the
/// license activation screen, and the main shell's app bar all read the
/// same value rather than each re-fetching. Falls back to
/// [CompanyBranding.fallback] on any failure (provider unreachable, no
/// company configured yet, ...) instead of surfacing an error UI — a
/// missing logo/name is not something worth blocking the app over.
final companyBrandingProvider = FutureProvider<CompanyBranding>((ref) async {
  try {
    return await ref.watch(brandingApiProvider).get();
  } catch (_) {
    return CompanyBranding.fallback;
  }
});

/// Absolute URLs (not the bare `/api/branding/...` path Endpoints holds) —
/// these get handed straight to Image.network, which needs a full URL.
String brandingLogoUrl() => '${Env.apiBaseUrl}${Endpoints.brandingLogoUrl}';
String brandingFaviconUrl() => '${Env.apiBaseUrl}${Endpoints.brandingFaviconUrl}';
