import 'package:equatable/equatable.dart';
import '../../domain/models/notification_model.dart';

enum NotificationStateStatus { initial, loading, success, failure }

class NotificationState extends Equatable {
  final NotificationStateStatus status;
  final List<NotificationModel> notifications;
  final NotificationCategory selectedCategory;
  final String? errorMessage;

  const NotificationState({
    this.status = NotificationStateStatus.initial,
    this.notifications = const [],
    this.selectedCategory = NotificationCategory.all,
    this.errorMessage,
  });

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  List<NotificationModel> get filteredNotifications {
    if (selectedCategory == NotificationCategory.all) return notifications;
    return notifications.where((n) => n.category == selectedCategory).toList();
  }

  NotificationState copyWith({
    NotificationStateStatus? status,
    List<NotificationModel>? notifications,
    NotificationCategory? selectedCategory,
    String? errorMessage,
  }) {
    return NotificationState(
      status: status ?? this.status,
      notifications: notifications ?? this.notifications,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, notifications, selectedCategory, errorMessage];
}
