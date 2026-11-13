import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/neu_design_system.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../shipments/domain/models/load_status.dart';
import '../../../shipments/domain/models/shipment_model.dart';
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
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: NeuAppBar(
        title: user?.fullName ?? 'driver.workspace'.tr(),
        actions: [
          NeuIconButton(
            icon: Icons.notifications_outlined,
            onPressed: () => context.push('/notifications'),
          ),
          const SizedBox(width: 8),
          NeuIconButton(
            icon: Icons.sos_rounded,
            color: AppColors.rose,
            onPressed: () => context.push('/sos'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocBuilder<ShipmentBloc, ShipmentState>(
        builder: (context, state) {
          if (state.isLoading) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: const [
                  NeuSkeleton(width: double.infinity, height: 160, borderRadius: 18),
                  SizedBox(height: 16),
                  NeuSkeleton(width: double.infinity, height: 100, borderRadius: 16),
                ],
              ),
            );
          }

          if (state.errorMessage != null && state.shipments.isEmpty) {
            return NeuErrorState(
              message: state.errorMessage!,
              onRetry: () => context.read<ShipmentBloc>().add(const LoadShipmentsRequested()),
            );
          }

          if (state.shipments.isEmpty) {
            return NeuEmptyState(
              icon: Icons.drive_eta_outlined,
              title: 'driver.noActiveTrips'.tr(),
              subtitle: 'driver.noActiveTripsDesc'.tr(),
              actionText: 'common.refresh'.tr(),
              onAction: () => context.read<ShipmentBloc>().add(const LoadShipmentsRequested()),
            );
          }

          final activeTrip = state.shipments.cast<ShipmentModel?>().firstWhere(
            (e) => e != null && (e.status == LoadStatus.inTransit || e.status == LoadStatus.goingToPickup),
            orElse: () => state.shipments.first,
          )!;

          final nextStatus = activeTrip.status.nextStatus;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Active Trip Card (Driver HUD - Neumorphic)
                NeuCard(
                  padding: const EdgeInsets.all(20),
                  borderRadius: 18,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          NeuChip(
                            label: 'dashboard.driverHud'.tr(),
                          ),
                          NeuChip(
                            label: activeTrip.status.label,
                            color: activeTrip.status.isFinal
                                ? AppColors.success
                                : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
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
                        '${activeTrip.trackingCode} • ${activeTrip.weightTons} tn • ${activeTrip.cargoType.tr()}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Next Stop Indicator
                      NeuCard(
                        isFlat: true,
                        padding: const EdgeInsets.all(12),
                        borderRadius: 12,
                        child: Row(
                          children: [
                            NeuIconButton(
                              icon: Icons.navigation_rounded,
                              size: 38,
                              iconSize: 20,
                              onPressed: () => context.push('/tracking/${activeTrip.id}'),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'dashboard.nextDestination'.tr(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                  Text(
                                    activeTrip.destination.city.tr(),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                    ),
                                  ),
                                  Text(
                                    activeTrip.destination.address,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Quick Action Navigation & POD Buttons
                      Row(
                        children: [
                          Expanded(
                            child: NeuButton(
                              text: 'dashboard.navigationMap'.tr(),
                              icon: Icons.map_outlined,
                              variant: NeuButtonVariant.secondary,
                              height: 42,
                              onPressed: () => context.push('/tracking/${activeTrip.id}'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: NeuButton(
                              text: nextStatus != null
                                  ? nextStatus.nextActionText(UserRole.driver).tr()
                                  : 'dashboard.statusActive'.tr(),
                              variant: NeuButtonVariant.primary,
                              height: 42,
                              onPressed: nextStatus != null
                                  ? () {
                                      if (nextStatus == LoadStatus.deliveredPodUploaded) {
                                        context.push('/pod-submit/${activeTrip.id}');
                                      } else {
                                        context.read<ShipmentBloc>().add(
                                              UpdateShipmentStatusRequested(
                                                shipmentId: activeTrip.id,
                                                nextStatus: nextStatus,
                                                currentRole: UserRole.driver,
                                              ),
                                            );
                                      }
                                    }
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Driver Essential Modules
                Text(
                  'driver.quickTools'.tr(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _DriverSuiteCard(
                        icon: Icons.qr_code_scanner_rounded,
                        title: 'driver.cmrScanner'.tr(),
                        subtitle: 'driver.scanDocs'.tr(),
                        onTap: () => context.push('/documents'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DriverSuiteCard(
                        icon: Icons.chat_outlined,
                        title: 'roles.chat'.tr(),
                        subtitle: 'chat.support'.tr(),
                        onTap: () => context.push('/chat'),
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
  final VoidCallback onTap;

  const _DriverSuiteCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return NeuCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      borderRadius: 14,
      child: Row(
        children: [
          NeuIconButton(
            icon: icon,
            size: 36,
            iconSize: 18,
            onPressed: onTap,
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
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
