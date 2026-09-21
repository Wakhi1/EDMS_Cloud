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

  /// [signaturePlacement]: only meaningful for a requires_signature step —
  /// where on the document to stamp the approver's signature, if the admin
  /// has turned that on in Settings (system_settings.embed_approval_signatures).
  /// Harmless to send when that setting is off: the server just ignores it.
  Future<void> approve(int approvalId, {String? comment, ({String page, String position})? signaturePlacement}) async {
    final response = await _client.post(
      '${Endpoints.approvals}/$approvalId/approve',
      data: {
        if (comment != null && comment.isNotEmpty) 'comment': comment,
        if (signaturePlacement != null) 'signaturePlacement': {'page': signaturePlacement.page, 'position': signaturePlacement.position},
      },
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
