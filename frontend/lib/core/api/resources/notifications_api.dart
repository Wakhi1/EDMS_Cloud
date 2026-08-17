import '../../models/notification_item.dart';
import '../api_client.dart';
import '../endpoints.dart';

/// Mirrors backend/routes/notifications.routes.js. No module gate — any
/// authenticated user.
class NotificationsApi {
  NotificationsApi(this._client);

  final ApiClient _client;

  Future<List<NotificationItem>> list() async {
    final response = await _client.get(Endpoints.notifications);
    return _client.unwrapList(response, NotificationItem.fromJson);
  }

  Future<void> markRead(int id) async {
    final response = await _client.put(Endpoints.notificationRead('$id'));
    _client.unwrap(response, (_) => null);
  }

  Future<void> markAllRead() async {
    final response = await _client.put(Endpoints.notificationsReadAll);
    _client.unwrap(response, (_) => null);
  }
}
