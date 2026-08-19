import '../../models/workflow_row.dart';
import '../api_client.dart';

/// Mirrors backend/routes/workflow.routes.js.
class WorkflowApi {
  WorkflowApi(this._client);

  final ApiClient _client;

  Future<List<WorkflowRow>> list() async {
    final response = await _client.get('/api/workflow');
    return _client.unwrapList(response, WorkflowRow.fromJson);
  }

  Future<int> create({
    required String name,
    int? triggerDocTypeId,
    int? triggerFolderId,
    required List<({String stepName, int roleId, int slaDays, int? escalationRoleId, int? subWorkflowId})> steps,
  }) async {
    final response = await _client.post(
      '/api/workflow',
      data: {
        'name': name,
        'triggerDocTypeId': ?triggerDocTypeId,
        'triggerFolderId': ?triggerFolderId,
        'steps': [
          for (final s in steps)
            {
              'stepName': s.stepName,
              'roleId': s.roleId,
              'slaDays': s.slaDays,
              'escalationRoleId': ?s.escalationRoleId,
              'subWorkflowId': ?s.subWorkflowId,
            },
        ],
      },
    );
    return _client.unwrap(response, (data) => (data as Map<String, dynamic>)['id'] as int);
  }

  /// PUT /api/workflow/:id — trigger doc-type/folder aren't editable here
  /// (backend only accepts name/isActive/steps); passing [steps] replaces
  /// the whole step list (drop-and-reinsert server-side).
  Future<void> update(
    int id, {
    String? name,
    bool? isActive,
    List<({String stepName, int roleId, int slaDays, int? escalationRoleId, int? subWorkflowId})>? steps,
  }) async {
    final response = await _client.put(
      '/api/workflow/$id',
      data: {
        'name': ?name,
        'isActive': ?isActive,
        if (steps != null)
          'steps': [
            for (final s in steps)
              {
                'stepName': s.stepName,
                'roleId': s.roleId,
                'slaDays': s.slaDays,
                'escalationRoleId': ?s.escalationRoleId,
                'subWorkflowId': ?s.subWorkflowId,
              },
          ],
      },
    );
    _client.unwrap(response, (_) => null);
  }

  Future<void> delete(int id) async {
    final response = await _client.delete('/api/workflow/$id');
    _client.unwrap(response, (_) => null);
  }

  Future<int> startInstance({required int workflowId, required int documentId}) async {
    final response = await _client.post('/api/workflow/$workflowId/start/$documentId');
    return _client.unwrap(response, (data) => (data as Map<String, dynamic>)['instanceId'] as int);
  }
}
