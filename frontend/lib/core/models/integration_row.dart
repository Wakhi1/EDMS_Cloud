// ignore_for_file: invalid_annotation_target
import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'integration_row.freezed.dart';
part 'integration_row.g.dart';

/// mysql2 returns JSON columns as raw strings, not pre-parsed objects
/// (confirmed backend-side this session — see services/capture/scheduler.js's
/// parseConfig) — GET /api/integrations' config_json needs the same
/// defensive handling as any other JSON column from this driver.
Map<String, dynamic>? _configJsonFromJson(dynamic value) {
  if (value == null) return null;
  if (value is Map<String, dynamic>) return value;
  if (value is String && value.isNotEmpty) {
    try {
      return jsonDecode(value) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
  return null;
}

/// A row from GET /api/integrations.
@freezed
abstract class IntegrationRow with _$IntegrationRow {
  const factory IntegrationRow({
    required String id,
    required String name,
    String? description,
    String? endpoint,
    required String status,
    @JsonKey(name: 'last_sync_at') String? lastSyncAt,
    @JsonKey(name: 'updated_at') String? updatedAt,
    @JsonKey(name: 'config_json', fromJson: _configJsonFromJson) Map<String, dynamic>? configJson,
  }) = _IntegrationRow;

  factory IntegrationRow.fromJson(Map<String, dynamic> json) => _$IntegrationRowFromJson(json);
}
