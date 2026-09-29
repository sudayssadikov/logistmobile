import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/notification_repository.dart';
import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final INotificationRepository _repository;

  NotificationBloc({required INotificationRepository repository})
      : _repository = repository,
        super(const NotificationState()) {
    on<LoadNotificationsRequested>(_onLoadNotifications);
    on<FilterNotificationCategoryChanged>(_onCategoryChanged);
    on<MarkNotificationAsReadRequested>(_onMarkAsRead);
    on<MarkAllNotificationsAsReadRequested>(_onMarkAllAsRead);
  }

  Future<void> _onLoadNotifications(
    LoadNotificationsRequested event,
    Emitter<NotificationState> emit,
  ) async {
    emit(state.copyWith(status: NotificationStateStatus.loading));
    try {
      final list = await _repository.getNotifications();
      emit(state.copyWith(
        status: NotificationStateStatus.success,
        notifications: list,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: NotificationStateStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  void _onCategoryChanged(
    FilterNotificationCategoryChanged event,
    Emitter<NotificationState> emit,
  ) {
    emit(state.copyWith(selectedCategory: event.category));
  }

  Future<void> _onMarkAsRead(
    MarkNotificationAsReadRequested event,
    Emitter<NotificationState> emit,
  ) async {
    await _repository.markAsRead(event.notificationId);
    final updated = state.notifications.map((n) {
      if (n.id == event.notificationId) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();
    emit(state.copyWith(notifications: updated));
  }

  Future<void> _onMarkAllAsRead(
    MarkAllNotificationsAsReadRequested event,
    Emitter<NotificationState> emit,
  ) async {
    await _repository.markAllAsRead();
    final updated = state.notifications.map((n) => n.copyWith(isRead: true)).toList();
    emit(state.copyWith(notifications: updated));
  }
}
