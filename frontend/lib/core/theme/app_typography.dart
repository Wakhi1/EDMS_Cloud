import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Text scale matching the mockup's dense sizing (11-17px body, larger only
/// for the login hero and panel headers) on top of "Source Serif 4" (serif,
/// not sans — the mockup's chosen typeface throughout).
class AppTypography {
  const AppTypography._();

  static TextTheme textTheme(Color ink, Color ink2) {
    final base = GoogleFonts.sourceSerif4TextTheme();
    return base
        .copyWith(
          displaySmall: base.displaySmall?.copyWith(fontSize: 34, fontWeight: FontWeight.w700, color: ink, height: 1.1),
          headlineSmall: base.headlineSmall?.copyWith(fontSize: 26, fontWeight: FontWeight.w700, color: ink),
          titleLarge: base.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.w700, color: ink),
          titleMedium: base.titleMedium?.copyWith(fontSize: 17, fontWeight: FontWeight.w700, color: ink),
          titleSmall: base.titleSmall?.copyWith(fontSize: 14.5, fontWeight: FontWeight.w600, color: ink),
          bodyLarge: base.bodyLarge?.copyWith(fontSize: 15, color: ink),
          bodyMedium: base.bodyMedium?.copyWith(fontSize: 13, color: ink),
          bodySmall: base.bodySmall?.copyWith(fontSize: 11.5, color: ink2),
          labelLarge: base.labelLarge?.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600, letterSpacing: 0.06, color: ink),
          labelMedium: base.labelMedium?.copyWith(fontSize: 11, letterSpacing: 0.1, color: ink2),
          labelSmall: base.labelSmall?.copyWith(fontSize: 10.5, letterSpacing: 0.08, color: ink2),
        )
        .apply(bodyColor: ink, displayColor: ink);
  }
}
