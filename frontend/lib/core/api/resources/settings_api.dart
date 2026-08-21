import '../../models/system_setting_row.dart';
import '../../models/user_preferences.dart';
import '../api_client.dart';
import '../endpoints.dart';

/// Mirrors backend/routes/settings.routes.js.
class SettingsApi {
  SettingsApi(this._client);

  final ApiClient _client;

  Future<List<SystemSettingRow>> list() async {
    final response = await _client.get(Endpoints.settings);
    return _client.unwrapList(response, SystemSettingRow.fromJson);
  }

  /// PUT /api/settings/:key — System Administrator only server-side, no
  /// client-side pre-check (matches IntegrationsApi.update).
  Future<void> update(String key, String value) async {
    final response = await _client.put(Endpoints.settingByKey(key), data: {'value': value});
    _client.unwrap(response, (_) => null);
  }

  Future<UserPreferences> getMyPreferences() async {
    final response = await _client.get(Endpoints.settingsMyPreferences);
    return _client.unwrap(response, (data) => UserPreferences.fromJson(data as Map<String, dynamic>));
  }

  Future<void> updateMyPreferences({String? themeMode, String? density}) async {
    final response = await _client.put(
      Endpoints.settingsMyPreferences,
      data: {'themeMode': ?themeMode, 'density': ?density},
    );
    _client.unwrap(response, (_) => null);
  }

  /// PUT /api/settings/theme — pushes this company's brand colors up to
  /// docsecure-platform-provider (System Administrator only server-side).
  /// Each color is "#RRGGBB" or null to leave it unchanged.
  Future<void> updateTheme({String? primaryColor, String? secondaryColor, String? accentColor}) async {
    final response = await _client.put(
      Endpoints.settingsTheme,
      data: {'primaryColor': ?primaryColor, 'secondaryColor': ?secondaryColor, 'accentColor': ?accentColor},
    );
    _client.unwrap(response, (_) => null);
  }
}
