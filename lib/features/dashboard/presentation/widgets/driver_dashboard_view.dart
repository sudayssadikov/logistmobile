import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../shipments/domain/models/load_status.dart';
import '../../../shipments/presentation/bloc/shipment_bloc.dart';
import '../../../shipments/presentation/bloc/shipment_event.dart';
import '../../../shipments/presentation/bloc/shipment_state.dart';

class DriverDashboardView extends StatelessWidget {
  const DriverDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = context.watch<AuthBloc>().state.user;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.cyan,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.drive_eta_rounded, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    user?.fullName ?? 'Driver Workspace',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '${'roles.driver'.tr()} • ${user?.companyName ?? "Volvo FH16"}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.sos_rounded, color: AppColors.rose),
            tooltip: 'Emergency SOS Radar',
            onPressed: () => context.push('/sos'),
          ),
        ],
      ),
      body: BlocBuilder<ShipmentBloc, ShipmentState>(
        builder: (context, state) {
          final activeTrip = state.shipments.firstWhere(
            (e) => e.status == LoadStatus.inTransit || e.status == LoadStatus.goingToPickup,
            orElse: () => state.shipments.first,
          );

          final nextStatus = activeTrip.status.nextStatus;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Active Trip Card (Driver HUD)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          StatusBadge(
                            label: 'dashboard.driverHud'.tr(),
                            color: AppColors.cyan,
                            fontSize: 10,
                          ),
                          StatusBadge(
                            label: activeTrip.status.label,
                            color: activeTrip.status.color,
                            fontSize: 11,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        activeTrip.cargoTitle.tr(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${activeTrip.trackingCode} • ${activeTrip.weightTons} tons • ${activeTrip.cargoType.tr()}',
                        style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                      ),
                      const SizedBox(height: 16),

                      // Next Stop Indicator
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.navigation_rounded, color: AppColors.cyan, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('dashboard.nextDestination'.tr(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey)),
                                  Text(
                                    activeTrip.destination.city.tr(),
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                                  ),
                                  Text(
                                    activeTrip.destination.address,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Quick Action Buttons (Start Nav, Advance Status, Sign POD)
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              text: 'dashboard.openMap'.tr(),
                              prefixIcon: Icons.map_rounded,
                              onPressed: () => context.push('/tracking/${activeTrip.id}'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: AppButton(
                              text: 'dashboard.chatWithShipper'.tr(),
                              variant: AppButtonVariant.secondary,
                              prefixIcon: Icons.chat_bubble_outline_rounded,
                              onPressed: () => context.push('/chat/${activeTrip.id}'),
                            ),
                          ),
                        ],
                      ),
                      if (nextStatus != null) ...[
                        const SizedBox(height: 12),
                        AppButton(
                          text: activeTrip.status.getActionTitle(UserRole.driver),
                          variant: AppButtonVariant.outline,
                          suffixIcon: Icons.check_circle_outline_rounded,
                          onPressed: () {
                            context.read<ShipmentBloc>().add(
                                  AdvanceShipmentStatusSubmitted(
                                    shipmentId: activeTrip.id,
                                    nextStatus: nextStatus,
                                    currentRole: UserRole.driver,
                                  ),
                                );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Driver Essential Suite Tools
                Text(
                  'HAYDOVCHI VA REYS QUROLLARI (AI & SOS)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: _DriverSuiteCard(
                        icon: Icons.auto_awesome_rounded,
                        title: 'AI Smart Match',
                        subtitle: 'Mos yuklarni topish',
                        color: AppColors.primary,
                        onTap: () => context.push('/shipments/ai-match'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _DriverSuiteCard(
                        icon: Icons.navigation_rounded,
                        title: 'Ovozli Navigator',
                        subtitle: 'Turn-by-turn audio',
                        color: AppColors.cyan,
                        onTap: () => context.push('/navigation/${activeTrip.id}'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _DriverSuiteCard(
                        icon: Icons.emergency_rounded,
                        title: 'SOS Yo\'lda Yordam',
                        subtitle: 'Evakuator & Servis',
                        color: AppColors.rose,
                        onTap: () => context.push('/sos'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _DriverSuiteCard(
                        icon: Icons.history_rounded,
                        title: 'Yetkazilgan Yuklar',
                        subtitle: 'POD va reyslar tarixi',
                        color: AppColors.emerald,
                        onTap: () => context.push('/shipments/history'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Driver Shift Stats
                Text(
                  'dashboard.shiftTelemetry'.tr(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('dashboard.drivingTime'.tr(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text('dashboard.drivingTimeVal'.tr(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary)),
                            Text('dashboard.drivingTimeSub'.tr(), style: const TextStyle(fontSize: 10, color: AppColors.emerald)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('dashboard.distanceToday'.tr(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text('dashboard.distanceVal'.tr(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.cyan)),
                            Text('dashboard.distanceSub'.tr(), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DriverSuiteCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _DriverSuiteCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
