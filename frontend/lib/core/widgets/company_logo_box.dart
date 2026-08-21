import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../branding/branding_provider.dart';
import '../models/company_branding.dart';
import '../theme/pspf_tokens.dart';

/// This deployment's company logo, read live from docsecure-platform-provider
/// (see core/branding/branding_provider.dart) — falls back to a plain
/// letter avatar (first letter of the company name) while branding is
/// loading, if the company has no logo uploaded, or if the image fails to
/// load, so this never renders as a broken image or a blank box.
class CompanyLogoBox extends ConsumerWidget {
  const CompanyLogoBox({super.key, this.size = 56});

  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branding = ref.watch(companyBrandingProvider).valueOrNull ?? CompanyBranding.fallback;
    final tokens = context.tokens;

    if (branding.hasLogo) {
      return Image.network(
        brandingLogoUrl(),
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _FallbackBox(branding: branding, tokens: tokens, size: size),
      );
    }
    return _FallbackBox(branding: branding, tokens: tokens, size: size);
  }
}

class _FallbackBox extends StatelessWidget {
  const _FallbackBox({required this.branding, required this.tokens, required this.size});

  final CompanyBranding branding;
  final PspfTokens tokens;
  final double size;

  @override
  Widget build(BuildContext context) {
    final letter = branding.name.trim().isNotEmpty ? branding.name.trim()[0].toUpperCase() : 'D';
    final bg = _parseColor(branding.primaryColor) ?? tokens.acc;
    return Container(
      width: size,
      height: size,
      color: bg,
      alignment: Alignment.center,
      child: Text(letter, style: TextStyle(color: Colors.white, fontSize: size * 0.43, fontWeight: FontWeight.w700)),
    );
  }

  Color? _parseColor(String? hex) {
    if (hex == null || !RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(hex)) return null;
    return Color(int.parse('FF${hex.substring(1)}', radix: 16));
  }
}
