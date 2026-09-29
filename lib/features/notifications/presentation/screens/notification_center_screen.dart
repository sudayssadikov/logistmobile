import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../domain/models/notification_model.dart';
import '../bloc/notification_bloc.dart';
import '../bloc/notification_event.dart';
import '../bloc/notification_state.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  @override
  void initState() {
    super.initState();
    context.read<NotificationBloc>().add(LoadNotificationsRequested());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeFormat = DateFormat('MMM dd, HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: Text('notifications.title'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded),
            tooltip: 'notifications.markAllRead'.tr(),
            onPressed: () {
              context.read<NotificationBloc>().add(MarkAllNotificationsAsReadRequested());
            },
          ),
        ],
      ),
      body: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          if (state.status == NotificationStateStatus.loading && state.notifications.isEmpty) {
            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: 4,
              itemBuilder: (_, __) => const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: SkeletonLoader(width: double.infinity, height: 90),
              ),
            );
          }

          final list = state.filteredNotifications;

          return Column(
            children: [
              // Category filter chip bar
              Container(
                height: 52,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: NotificationCategory.values.map((cat) {
                    final isSelected = state.selectedCategory == cat;

                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: isSelected,
                        avatar: Icon(
                          cat.icon,
                          size: 16,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                        ),
                        label: Text(cat.labelKey.tr()),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                        ),
                        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                        selectedColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.primary
                                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          ),
                        ),
                        onSelected: (_) {
                          context.read<NotificationBloc>().add(FilterNotificationCategoryChanged(cat));
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Notifications List
              Expanded(
                child: list.isEmpty
                    ? EmptyStateView(
                        icon: Icons.notifications_off_outlined,
                        title: 'notifications.noNotifications'.tr(),
                        description: 'You are all caught up!',
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          context.read<NotificationBloc>().add(LoadNotificationsRequested());
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          itemCount: list.length,
                          itemBuilder: (context, index) {
                            final item = list[index];

                            return InkWell(
                              onTap: () {
                                context.read<NotificationBloc>().add(MarkNotificationAsReadRequested(item.id));
                                if (item.actionRoute != null) {
                                  context.push(item.actionRoute!);
                                }
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: !item.isRead
                                        ? AppColors.primary.withValues(alpha: 0.5)
                                        : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: item.category.color.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(item.category.icon, size: 20, color: item.category.color),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  item.title,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w800,
                                                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                                  ),
                                                ),
                                              ),
                                              if (!item.isRead)
                                                Container(
                                                  width: 8,
                                                  height: 8,
                                                  margin: const EdgeInsets.only(left: 6),
                                                  decoration: const BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: AppColors.primary,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            item.body,
                                            style: TextStyle(
                                              fontSize: 12,
                                              height: 1.4,
                                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            timeFormat.format(item.createdAt),
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
