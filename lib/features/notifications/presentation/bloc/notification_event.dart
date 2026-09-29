import 'package:equatable/equatable.dart';
import '../../domain/models/notification_model.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();
  @override
  List<Object?> get props => [];
}

class LoadNotificationsRequested extends NotificationEvent {}

class FilterNotificationCategoryChanged extends NotificationEvent {
  final NotificationCategory category;
  const FilterNotificationCategoryChanged(this.category);
  @override
  List<Object?> get props => [category];
}

class MarkNotificationAsReadRequested extends NotificationEvent {
  final String notificationId;
  const MarkNotificationAsReadRequested(this.notificationId);
  @override
  List<Object?> get props => [notificationId];
}

class MarkAllNotificationsAsReadRequested extends NotificationEvent {}
