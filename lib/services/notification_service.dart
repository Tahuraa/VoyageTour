import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_notification.dart';
import 'trips_service.dart';

/// Read/unread state lives locally (SharedPreferences) since notifications
/// themselves are computed, not stored server-side.
class NotificationService {
  static const _readIdsKey = 'read_notification_ids';
  static const _enabledKey = 'notifications_enabled';

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? true;
  }

  static Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
  }

  static Future<List<AppNotification>> load(String token) async {
    if (!await isEnabled()) return const [];
    final trips = await TripsService.loadMine(token);
    return notificationsForTrips(trips);
  }

  static Future<Set<String>> readIds() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_readIdsKey) ?? const []).toSet();
  }

  static Future<void> markRead(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = (prefs.getStringList(_readIdsKey) ?? const []).toSet()..add(id);
    await prefs.setStringList(_readIdsKey, ids.toList());
  }

  static Future<void> markAllRead(Iterable<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = (prefs.getStringList(_readIdsKey) ?? const []).toSet()..addAll(ids);
    await prefs.setStringList(_readIdsKey, existing.toList());
  }

  static Future<int> unreadCount(String token) async {
    final notifications = await load(token);
    final read = await readIds();
    return notifications.where((n) => !read.contains(n.id)).length;
  }
}
