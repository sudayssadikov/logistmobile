import 'dart:async';
import '../../../../core/network/dio_client.dart';
import '../../domain/models/notification_model.dart';
import '../../domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements INotificationRepository {
  final DioClient? _dioClient;

  NotificationRepositoryImpl([this._dioClient]);

  @override
  Future<List<NotificationModel>> getNotifications() async {
    if (_dioClient == null) return [];
    try {
      final response = await _dioClient!.get('/notifications');
      if (response.statusCode == 200 && response.data != null) {
        final List raw = response.data['data'] ?? [];
        return raw.map((e) => NotificationModel.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

  @override
  Future<void> markAsRead(String id) async {
    if (_dioClient == null) return;
    try {
      await _dioClient!.patch('/notifications/$id/read');
    } catch (_) {}
  }

  @override
  Future<void> markAllAsRead() async {
    if (_dioClient == null) return;
    try {
      await _dioClient!.post('/notifications/read-all');
    } catch (_) {}
  }
}
