import '../../models/watermark_template_row.dart';
import '../api_client.dart';
import '../endpoints.dart';

/// Mirrors backend/routes/watermark-templates.routes.js.
class WatermarkTemplatesApi {
  WatermarkTemplatesApi(this._client);

  final ApiClient _client;

  Future<List<WatermarkTemplateRow>> list() async {
    final response = await _client.get(Endpoints.watermarkTemplates);
    return _client.unwrapList(response, WatermarkTemplateRow.fromJson);
  }

  /// GET /active — the template every new watermark uses right now, or null if none configured.
  Future<WatermarkTemplateRow?> active() async {
    final response = await _client.get(Endpoints.watermarkTemplatesActive);
    return _client.unwrap(response, (data) => data == null ? null : WatermarkTemplateRow.fromJson(data as Map<String, dynamic>));
  }

  Future<void> setActive(int templateId) async {
    final response = await _client.put(Endpoints.watermarkTemplatesActive, data: {'templateId': templateId});
    _client.unwrap(response, (_) => null);
  }

  Future<int> create({required String label, required String text}) async {
    final response = await _client.post(Endpoints.watermarkTemplates, data: {'label': label, 'text': text});
    return _client.unwrap(response, (data) => (data as Map<String, dynamic>)['id'] as int);
  }

  Future<void> update(int id, {String? label, String? text}) async {
    final response = await _client.put(Endpoints.watermarkTemplateById('$id'), data: {'label': ?label, 'text': ?text});
    _client.unwrap(response, (_) => null);
  }

  Future<void> delete(int id) async {
    final response = await _client.delete(Endpoints.watermarkTemplateById('$id'));
    _client.unwrap(response, (_) => null);
  }
}
