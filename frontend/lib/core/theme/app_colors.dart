import 'package:flutter/material.dart';

import 'pspf_tokens.dart';

/// Builds Material [ColorScheme]s from [PspfTokens] so standard widgets
/// (buttons, chips, dialogs) pick sane defaults. Anything Material has no
/// slot for lives only on [PspfTokens] (see pspf_tokens.dart).
class AppColors {
  const AppColors._();

  static ColorScheme light() {
    const t = PspfTokens.light;
    return ColorScheme(
      brightness: Brightness.light,
      primary: t.acc,
      onPrimary: Colors.white,
      secondary: t.acc2,
      onSecondary: Colors.white,
      error: t.bad,
      onError: Colors.white,
      surface: t.surf,
      onSurface: t.ink,
      surfaceContainerHighest: t.surf2,
      surfaceContainer: t.surf2,
      surfaceDim: t.surf3,
      outline: t.line,
      outlineVariant: t.line2,
      onSurfaceVariant: t.ink2,
    );
  }

  static ColorScheme dark() {
    const t = PspfTokens.dark;
    return ColorScheme(
      brightness: Brightness.dark,
      primary: t.acc,
      onPrimary: Colors.black,
      secondary: t.acc2,
      onSecondary: Colors.black,
      error: t.bad,
      onError: Colors.black,
      surface: t.surf,
      onSurface: t.ink,
      surfaceContainerHighest: t.surf2,
      surfaceContainer: t.surf2,
      surfaceDim: t.surf3,
      outline: t.line,
      outlineVariant: t.line2,
      onSurfaceVariant: t.ink2,
    );
  }
}
