import '../../models/approval_item.dart';
import '../api_client.dart';
import '../endpoints.dart';

/// Mirrors backend/routes/approvals.routes.js. Phase 1 only previews the
/// inbox on the dashboard (list); approve/reject actions belong to the
/// Phase 2 Approvals module but are cheap to include now.
class ApprovalsApi {
  ApprovalsApi(this._client);

  final ApiClient _client;

  Future<List<ApprovalItem>> inbox({bool silent403 = false}) async {
    final response = await _client.get(Endpoints.approvals, silent403: silent403);
    return _client.unwrapList(response, ApprovalItem.fromJson);
  }

  Future<void> approve(int approvalId, {String? comment}) async {
    final response = await _client.post(
      '${Endpoints.approvals}/$approvalId/approve',
      data: {if (comment != null && comment.isNotEmpty) 'comment': comment},
    );
    _client.unwrap(response, (_) => null);
  }

  Future<void> reject(int approvalId, {String? comment}) async {
    final response = await _client.post(
      '${Endpoints.approvals}/$approvalId/reject',
      data: {if (comment != null && comment.isNotEmpty) 'comment': comment},
    );
    _client.unwrap(response, (_) => null);
  }
}
