import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_item.dart';

class NotificationNotifier extends StateNotifier<List<NotificationItem>> {
  NotificationNotifier() : super(mockNotifications);

  int get unreadCount => state.where((item) => !item.isRead).length;

  void markAsRead(String id) {
    state = [
      for (final item in state)
        if (item.id == id) item.copyWith(isRead: true) else item,
    ];
  }

  void markAllAsRead() {
    state = [
      for (final item in state) item.copyWith(isRead: true),
    ];
  }

  void clearAll() {
    state = [];
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, List<NotificationItem>>((ref) {
  return NotificationNotifier();
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationProvider);
  return notifications.where((n) => !n.isRead).length;
});
