import 'dart:typed_data';

import 'package:dio/dio.dart';
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

/// Logo bytes fetched through the app's own [apiClientProvider] Dio
/// instance — deliberately NOT Image.network (which builds its own
/// separate dart:io HttpClient). That client needs the same SSL.com trust
/// anchor as every other API call (see core/api/dio_trust_anchor_io.dart's
/// doc comment); duplicating that fix via a global HttpOverrides caused a
/// startup ANR (every HttpClient() call anywhere, including ones Flutter's
/// own engine creates internally, rebuilding a full SecurityContext
/// synchronously), so this reuses the one Dio client that already has it
/// wired up once, correctly, instead of a second parallel mechanism. Null
/// on any failure — CompanyLogoBox falls back to a plain letter avatar.
final companyLogoBytesProvider = FutureProvider<Uint8List?>((ref) async {
  final branding = await ref.watch(companyBrandingProvider.future);
  if (!branding.hasLogo) return null;
  try {
    final response = await ref.watch(apiClientProvider).get(
          Endpoints.brandingLogoUrl,
          options: Options(responseType: ResponseType.bytes),
        );
    return Uint8List.fromList(List<int>.from(response.data as List));
  } catch (_) {
    return null;
  }
});

/// Absolute URL for contexts that need one directly (e.g. web <link
/// rel="icon">) rather than going through Dio — Endpoints only holds the
/// bare `/api/branding/...` path.
String brandingFaviconUrl() => '${Env.apiBaseUrl}${Endpoints.brandingFaviconUrl}';
