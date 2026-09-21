import '../../models/report_template_row.dart';
import '../api_client.dart';
import '../endpoints.dart';

/// Mirrors backend/routes/report-templates.routes.js.
class ReportTemplatesApi {
  ReportTemplatesApi(this._client);

  final ApiClient _client;

  Future<List<ReportTemplateRow>> list() async {
    final response = await _client.get(Endpoints.reportTemplates);
    return _client.unwrapList(response, ReportTemplateRow.fromJson);
  }

  Future<int> create({required String name, required List<String> sections}) async {
    final response = await _client.post(Endpoints.reportTemplates, data: {'name': name, 'sections': sections});
    return _client.unwrap(response, (data) => (data as Map<String, dynamic>)['id'] as int);
  }

  Future<void> update(int id, {String? name, List<String>? sections}) async {
    final response = await _client.put(Endpoints.reportTemplateById('$id'), data: {'name': ?name, 'sections': ?sections});
    _client.unwrap(response, (_) => null);
  }

  Future<void> delete(int id) async {
    final response = await _client.delete(Endpoints.reportTemplateById('$id'));
    _client.unwrap(response, (_) => null);
  }
}
