import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';

enum NotificationCategory {
  all(labelKey: 'notifications.all', icon: Icons.notifications_outlined),
  shipments(labelKey: 'notifications.shipments', icon: Icons.local_shipping_outlined),
  payments(labelKey: 'notifications.payments', icon: Icons.account_balance_wallet_outlined),
  alerts(labelKey: 'notifications.alerts', icon: Icons.warning_amber_rounded);

  final String labelKey;
  final IconData icon;

  const NotificationCategory({
    required this.labelKey,
    required this.icon,
  });

  Color get color {
    switch (this) {
      case NotificationCategory.shipments:
        return AppColors.primary;
      case NotificationCategory.payments:
        return AppColors.emerald;
      case NotificationCategory.alerts:
        return AppColors.amber;
      case NotificationCategory.all:
        return AppColors.indigo;
    }
  }
}

class NotificationModel extends Equatable {
  final String id;
  final String title;
  final String body;
  final NotificationCategory category;
  final DateTime createdAt;
  final bool isRead;
  final String? actionRoute;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.createdAt,
    this.isRead = false,
    this.actionRoute,
  });

  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    NotificationCategory? category,
    DateTime? createdAt,
    bool? isRead,
    String? actionRoute,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      actionRoute: actionRoute ?? this.actionRoute,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'category': category.name,
        'created_at': createdAt.toIso8601String(),
        'is_read': isRead,
        'action_route': actionRoute,
      };

  factory NotificationModel.fromJson(Map<String, dynamic> json) => NotificationModel(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        category: NotificationCategory.values.firstWhere(
          (e) => e.name == json['category'],
          orElse: () => NotificationCategory.shipments,
        ),
        createdAt: DateTime.parse(json['created_at'] as String),
        isRead: json['is_read'] as bool? ?? false,
        actionRoute: json['action_route'] as String?,
      );

  @override
  List<Object?> get props => [id, title, body, category, createdAt, isRead, actionRoute];
}
