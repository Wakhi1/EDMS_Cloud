import 'package:flutter/material.dart';

import '../models/company_branding.dart';
import '../utils/hex_color.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'pspf_tokens.dart';

/// The mockup is sharp-cornered everywhere (`border-radius:0 !important`)
/// and uses flat hover-color swaps instead of Material ripples — every
/// component shape is overridden here rather than per-widget.
class AppTheme {
  const AppTheme._();

  static const _zero = RoundedRectangleBorder(borderRadius: BorderRadius.zero);

  static ThemeData light({CompanyBranding? branding}) => _build(AppColors.light(), _brandedTokens(PspfTokens.light, branding));
  static ThemeData dark({CompanyBranding? branding}) => _build(AppColors.dark(), _brandedTokens(PspfTokens.dark, branding));

  /// Re-tints the accent-family tokens (buttons, focus rings, the app
  /// bar's bottom line, selected states, the info color) from this
  /// deployment's own company branding, read live from
  /// docsecure-platform-provider — everything else (paper/surf/ink and
  /// the light/dark structural colors) stays as designed, so a bad or
  /// low-contrast brand color can't wreck legibility, only the accent.
  static PspfTokens _brandedTokens(PspfTokens base, CompanyBranding? branding) {
    final primary = parseHexColor(branding?.primaryColor);
    final secondary = parseHexColor(branding?.secondaryColor);
    final accent = parseHexColor(branding?.accentColor);
    if (primary == null && secondary == null && accent == null) return base;

    return base.copyWith(
      acc: primary ?? base.acc,
      accD: primary != null ? _shiftLightness(primary, -0.12) : base.accD,
      accT: primary != null ? _shiftLightness(primary, 0.35) : base.accT,
      barLine: primary ?? base.barLine,
      acc2: secondary ?? base.acc2,
      info: accent ?? base.info,
    );
  }

  static Color _shiftLightness(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
  }

  static ThemeData _build(ColorScheme scheme, PspfTokens tokens) {
    final textTheme = AppTypography.textTheme(tokens.ink, tokens.ink2);

    return ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: tokens.paper,
      canvasColor: tokens.surf,
      dividerColor: tokens.line,
      textTheme: textTheme,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      visualDensity: VisualDensity.compact,
      extensions: [tokens],
      appBarTheme: AppBarTheme(
        backgroundColor: tokens.bar,
        foregroundColor: tokens.barInk,
        elevation: 0,
        titleTextStyle: textTheme.titleMedium?.copyWith(color: tokens.barInk, fontWeight: FontWeight.w700, fontSize: 17),
        iconTheme: IconThemeData(color: tokens.barInk),
        shape: Border(bottom: BorderSide(color: tokens.barLine, width: 2)),
      ),
      cardTheme: CardThemeData(
        color: tokens.surf,
        shape: _zero.copyWith(side: BorderSide(color: tokens.line)),
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: tokens.surf,
        shape: _zero.copyWith(side: BorderSide(color: tokens.line2)),
        elevation: 8,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: tokens.surf,
        surfaceTintColor: Colors.transparent,
        shape: _zero.copyWith(side: BorderSide(color: tokens.line2)),
        elevation: 8,
        headerBackgroundColor: tokens.acc,
        headerForegroundColor: Colors.white,
        headerHeadlineStyle: textTheme.headlineSmall?.copyWith(color: Colors.white),
        weekdayStyle: textTheme.labelMedium?.copyWith(color: tokens.ink2),
        dayStyle: textTheme.bodyMedium,
        dayForegroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? Colors.white : tokens.ink,
        ),
        dayBackgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? tokens.acc : Colors.transparent,
        ),
        dayShape: const WidgetStatePropertyAll(_zero),
        todayForegroundColor: WidgetStatePropertyAll(tokens.acc),
        todayBackgroundColor: const WidgetStatePropertyAll(Colors.transparent),
        todayBorder: BorderSide(color: tokens.acc),
        yearForegroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? Colors.white : tokens.ink,
        ),
        yearBackgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? tokens.acc : Colors.transparent,
        ),
        yearShape: const WidgetStatePropertyAll(_zero),
        rangePickerBackgroundColor: tokens.surf,
        rangePickerHeaderBackgroundColor: tokens.acc,
        rangePickerHeaderForegroundColor: Colors.white,
        rangeSelectionBackgroundColor: tokens.sel,
        rangePickerShape: _zero,
        dividerColor: tokens.line,
        cancelButtonStyle: ButtonStyle(foregroundColor: WidgetStatePropertyAll(tokens.ink2)),
        confirmButtonStyle: ButtonStyle(foregroundColor: WidgetStatePropertyAll(tokens.accD)),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: tokens.surf,
        shape: _zero,
        elevation: 8,
      ),
      chipTheme: ChipThemeData(
        shape: _zero.copyWith(side: BorderSide(color: tokens.line)),
        backgroundColor: tokens.surf,
        labelStyle: textTheme.labelMedium,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.surf,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
        border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: tokens.line2)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: tokens.line2)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: tokens.acc, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: tokens.bad)),
        labelStyle: textTheme.labelMedium,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          shape: const WidgetStatePropertyAll(_zero),
          elevation: const WidgetStatePropertyAll(0),
          backgroundColor: WidgetStatePropertyAll(tokens.acc),
          foregroundColor: const WidgetStatePropertyAll(Colors.white),
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16, vertical: 11)),
          textStyle: WidgetStatePropertyAll(textTheme.labelLarge?.copyWith(color: Colors.white, letterSpacing: 0.06)),
          overlayColor: WidgetStatePropertyAll(tokens.accD.withValues(alpha: 0.15)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          shape: const WidgetStatePropertyAll(_zero),
          side: WidgetStatePropertyAll(BorderSide(color: tokens.line2)),
          foregroundColor: WidgetStatePropertyAll(tokens.ink),
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 14, vertical: 9)),
          overlayColor: WidgetStatePropertyAll(tokens.surf2),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          shape: const WidgetStatePropertyAll(_zero),
          foregroundColor: WidgetStatePropertyAll(tokens.accD),
          overlayColor: WidgetStatePropertyAll(tokens.surf2),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: tokens.surf,
        shape: _zero.copyWith(side: BorderSide(color: tokens.line)),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStatePropertyAll(tokens.surf2),
        dataRowColor: WidgetStatePropertyAll(tokens.surf),
        dividerThickness: 1,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: tokens.surf,
        selectedIconTheme: IconThemeData(color: tokens.ink),
        unselectedIconTheme: IconThemeData(color: tokens.ink2),
        indicatorColor: tokens.sel,
        indicatorShape: _zero,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: tokens.surf,
        selectedItemColor: tokens.accD,
        unselectedItemColor: tokens.ink2,
        type: BottomNavigationBarType.fixed,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: tokens.ink,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: tokens.paper),
        shape: _zero,
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: DividerThemeData(color: tokens.line, thickness: 1, space: 1),
    );
  }
}
