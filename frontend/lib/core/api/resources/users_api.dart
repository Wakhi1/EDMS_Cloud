import '../../models/group_row.dart';
import '../../models/user_row.dart';
import '../api_client.dart';
import '../endpoints.dart';

/// Mirrors backend/routes/users.routes.js. `list()`/`listGroups()`/
/// `addGroupMember()` allow System Administrator OR Records Manager
/// server-side; `updateRole()`/`updateLock()` are System Administrator
/// only — this class does no client-side pre-check, a 403 on the mutating
/// calls surfaces to the caller as an [ApiException] like anywhere else.
class UsersApi {
  UsersApi(this._client);

  final ApiClient _client;

  Future<List<UserRow>> list({String? role, int? departmentId, String? status}) async {
    final response = await _client.get(
      Endpoints.users,
      queryParameters: {'role': ?role, 'departmentId': ?departmentId, 'status': ?status},
    );
    return _client.unwrapList(response, UserRow.fromJson);
  }

  Future<void> updateRole(int userId, int roleId) async {
    final response = await _client.put(Endpoints.userRole('$userId'), data: {'roleId': roleId});
    _client.unwrap(response, (_) => null);
  }

  Future<void> updateLock(int userId, bool locked) async {
    final response = await _client.put(Endpoints.userLock('$userId'), data: {'locked': locked});
    _client.unwrap(response, (_) => null);
  }

  /// Admin department reassignment for an existing account — distinct from
  /// the department chosen at creation time in [create], which has no
  /// update path of its own.
  Future<void> updateDepartment(int userId, int? departmentId) async {
    final response = await _client.put(Endpoints.userDepartment('$userId'), data: {'departmentId': departmentId});
    _client.unwrap(response, (_) => null);
  }

  /// Admin-set password reset for another user — distinct from
  /// [updatePassword] (self-service, requires the current password).
  Future<void> resetPassword(int userId, String newPassword) async {
    final response = await _client.put(Endpoints.userPassword('$userId'), data: {'newPassword': newPassword});
    _client.unwrap(response, (_) => null);
  }

  /// Force-enable/disable MFA for a role that doesn't already mandate it.
  Future<void> updateMfaEnabled(int userId, bool enabled) async {
    final response = await _client.put(Endpoints.userMfa('$userId'), data: {'enabled': enabled});
    _client.unwrap(response, (_) => null);
  }

  /// Wipes every enrolled MFA factor so a user who lost their device/codes
  /// can re-enroll from scratch — does not affect whether MFA is required.
  Future<void> resetMfaEnrollment(int userId) async {
    final response = await _client.post(Endpoints.userMfaReset('$userId'));
    _client.unwrap(response, (_) => null);
  }

  Future<List<GroupRow>> listGroups() async {
    final response = await _client.get(Endpoints.userGroups);
    return _client.unwrapList(response, GroupRow.fromJson);
  }

  Future<void> addGroupMember(int groupId, int userId) async {
    final response = await _client.post(Endpoints.groupMembers('$groupId'), data: {'userId': userId});
    _client.unwrap(response, (_) => null);
  }

  /// POST /api/users — in-app account creation (distinct from the public
  /// self-service /api/auth/register). Assigning the System Administrator
  /// role is itself re-checked server-side regardless of caller role.
  Future<int> create({
    required String fullName,
    required String email,
    required String password,
    required int roleId,
    int? departmentId,
    String? phoneNumber,
  }) async {
    final response = await _client.post(
      Endpoints.users,
      data: {
        'fullName': fullName,
        'email': email,
        'password': password,
        'roleId': roleId,
        'departmentId': ?departmentId,
        'phoneNumber': ?phoneNumber,
      },
    );
    return _client.unwrap(response, (data) => (data as Map<String, dynamic>)['id'] as int);
  }

  /// DELETE /api/users/:id — deactivates (never hard-deletes).
  Future<void> deactivate(int userId) async {
    final response = await _client.delete(Endpoints.userById('$userId'));
    _client.unwrap(response, (_) => null);
  }

  /// PUT /api/users/me — self-service profile update (name, phone).
  Future<void> updateProfile({String? fullName, String? phoneNumber}) async {
    final response = await _client.put(Endpoints.usersMe, data: {'fullName': ?fullName, 'phoneNumber': ?phoneNumber});
    _client.unwrap(response, (_) => null);
  }

  /// PUT /api/users/me/password — throws [ApiException] with a 401 message
  /// ("Current password is incorrect") if [currentPassword] doesn't match.
  Future<void> updatePassword({required String currentPassword, required String newPassword}) async {
    final response = await _client.put(
      Endpoints.usersMePassword,
      data: {'currentPassword': currentPassword, 'newPassword': newPassword},
    );
    _client.unwrap(response, (_) => null);
  }
}
