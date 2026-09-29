import 'dart:async';
import '../../../../core/network/dio_client.dart';
import '../../domain/models/notification_model.dart';
import '../../domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements INotificationRepository {
  final DioClient? _dioClient;

  final List<NotificationModel> _notifications = [
    NotificationModel(
      id: 'NOTIF-01',
      title: 'POD Tasdiqlandi va Imzolandi',
      body: 'LF-UZ-1001 yuki bo\'yicha elektron qabul akti imzolandi. Eskrou to\'lovi chiqarishga tayyor.',
      category: NotificationCategory.shipments,
      createdAt: DateTime.now().subtract(const Duration(minutes: 25)),
      isRead: false,
      actionRoute: '/shipments/SHP-1001',
    ),
    NotificationModel(
      id: 'NOTIF-02',
      title: 'Eskrou Hisobi To\'ldirildi (15,000,000 UZS)',
      body: 'Yuk egasi Agro Export Holding eskrou depozitini to\'liq kafolatladi. Tashishga ruxsat berildi.',
      category: NotificationCategory.payments,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: false,
      actionRoute: '/wallet',
    ),
    NotificationModel(
      id: 'NOTIF-03',
      title: 'Transport Hujjatining Muddati Tugamoqda',
      body: 'Volvo FH16 (01 842 TAA) texnik pasport muddati 25 kundan keyin tugaydi.',
      category: NotificationCategory.alerts,
      createdAt: DateTime.now().subtract(const Duration(hours: 8)),
      isRead: false,
      actionRoute: '/documents',
    ),
  ];

  NotificationRepositoryImpl([this._dioClient]);

  @override
  Future<List<NotificationModel>> getNotifications() async {
    if (_dioClient != null) {
      try {
        final response = await _dioClient!.get('/notifications');
        if (response.statusCode == 200 && response.data != null) {
          final List raw = response.data['data'] ?? [];
          if (raw.isNotEmpty) {
            return raw.map((e) => NotificationModel.fromJson(e)).toList();
          }
        }
      } catch (_) {
        // Fallback
      }
    }

    await Future.delayed(const Duration(milliseconds: 150));
    return List.from(_notifications);
  }

  @override
  Future<void> markAsRead(String id) async {
    if (_dioClient != null) {
      try {
        await _dioClient!.patch('/notifications/$id/read');
      } catch (_) {
        // Fallback
      }
    }

    await Future.delayed(const Duration(milliseconds: 100));
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
    }
  }

  @override
  Future<void> markAllAsRead() async {
    if (_dioClient != null) {
      try {
        await _dioClient!.post('/notifications/read-all');
      } catch (_) {
        // Fallback
      }
    }

    await Future.delayed(const Duration(milliseconds: 150));
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
  }
}
