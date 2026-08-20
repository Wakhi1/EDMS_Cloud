import '../../models/access_request_row.dart';
import '../api_client.dart';
import '../endpoints.dart';

/// Mirrors backend/routes/access-requests.routes.js.
class AccessRequestsApi {
  AccessRequestsApi(this._client);

  final ApiClient _client;

  /// POST /api/access-requests — any authenticated user; no module gate
  /// (the whole point is self-service for someone who doesn't already have
  /// access to the module that would otherwise get them there).
  Future<int> create({
    required String targetType,
    required int targetId,
    String requestedLevel = 'view',
    String? reason,
  }) async {
    final response = await _client.post(
      Endpoints.accessRequests,
      data: {'targetType': targetType, 'targetId': targetId, 'requestedLevel': requestedLevel, 'reason': ?reason},
    );
    return _client.unwrap(response, (data) => (data as Map<String, dynamic>)['id'] as int);
  }

  Future<List<AccessRequestRow>> listMine() async {
    final response = await _client.get(Endpoints.accessRequestsMine);
    return _client.unwrapList(response, AccessRequestRow.fromJson);
  }

  /// GET /api/access-requests — the review queue. Requires 'permissions'
  /// edit access (same as granting/revoking ACL directly); [silent403] so a
  /// non-approver landing on the shared /permissions screen isn't bounced
  /// to /access-denied just because this one section is gated.
  Future<List<AccessRequestRow>> listQueue({String status = 'pending', bool silent403 = false}) async {
    final response = await _client.get(Endpoints.accessRequests, queryParameters: {'status': status}, silent403: silent403);
    return _client.unwrapList(response, AccessRequestRow.fromJson);
  }

  Future<void> approve(int id, {String? note}) async {
    final response = await _client.post(Endpoints.accessRequestApprove('$id'), data: {'note': ?note});
    _client.unwrap(response, (_) => null);
  }

  Future<void> deny(int id, {String? note}) async {
    final response = await _client.post(Endpoints.accessRequestDeny('$id'), data: {'note': ?note});
    _client.unwrap(response, (_) => null);
  }
}
