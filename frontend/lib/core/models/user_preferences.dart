/// GET/PUT /api/settings/me/preferences — hand-rolled, simple fetch/edit
/// shape (same convention as SystemSettingRow).
class UserPreferences {
  const UserPreferences({required this.themeMode, required this.density});

  final String themeMode; // 'system' | 'light' | 'dark'
  final String density; // 'comfortable' | 'compact'

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      themeMode: json['theme_mode'] as String? ?? 'system',
      density: json['density'] as String? ?? 'comfortable',
    );
  }
}
