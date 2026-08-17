import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_providers.dart';
import '../auth/auth_providers.dart';

/// Persists appearance via GET/PUT /api/settings/me/preferences (previously
/// an in-memory-only StateProvider, reset on every reload). Rebuilds (and
/// re-fetches) whenever [currentUserProvider] changes — i.e. resets to the
/// default on logout, loads the signed-in user's saved preference on login.
class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final user = ref.watch(currentUserProvider);
    if (user != null) _loadPersisted();
    return ThemeMode.system;
  }

  Future<void> _loadPersisted() async {
    try {
      final prefs = await ref.read(settingsApiProvider).getMyPreferences();
      state = _parse(prefs.themeMode);
    } catch (_) {
      // Best-effort — keep the default rather than surfacing a load error
      // for a cosmetic preference.
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    try {
      await ref.read(settingsApiProvider).updateMyPreferences(themeMode: _serialize(mode));
    } catch (_) {
      // Best-effort persistence — the UI already reflects the choice
      // locally even if the write fails.
    }
  }

  ThemeMode _parse(String value) => switch (value) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  String _serialize(ThemeMode mode) => switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);
