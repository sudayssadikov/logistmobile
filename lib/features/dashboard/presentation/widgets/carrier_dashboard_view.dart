import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/neu_design_system.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../fleet/presentation/bloc/fleet_bloc.dart';
import '../../../fleet/presentation/bloc/fleet_event.dart';
import '../../../shipments/domain/models/load_status.dart';
import '../../../shipments/presentation/bloc/shipment_bloc.dart';
import '../../../shipments/presentation/bloc/shipment_event.dart';
import '../../../shipments/presentation/bloc/shipment_state.dart';
import '../../../shipments/presentation/widgets/shipment_card.dart';

class CarrierDashboardView extends StatelessWidget {
  const CarrierDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = context.watch<AuthBloc>().state.user;
    final fleetState = context.watch<FleetBloc>().state;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: NeuAppBar(
        title: user?.companyName ?? 'carrier.portal'.tr(),
        actions: [
          NeuIconButton(
            icon: Icons.notifications_outlined,
            onPressed: () => context.push('/notifications'),
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
                  NeuSkeleton(width: double.infinity, height: 120, borderRadius: 16),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: NeuSkeleton(width: double.infinity, height: 90, borderRadius: 16)),
                      SizedBox(width: 12),
                      Expanded(child: NeuSkeleton(width: double.infinity, height: 90, borderRadius: 16)),
                    ],
                  ),
                  SizedBox(height: 20),
                  NeuSkeleton(width: double.infinity, height: 110, borderRadius: 16),
                ],
              ),
            );
          }

          if (state.errorMessage != null && state.shipments.isEmpty) {
            return NeuErrorState(
              message: state.errorMessage!,
              onRetry: () {
                context.read<ShipmentBloc>().add(const LoadShipmentsRequested());
                context.read<FleetBloc>().add(LoadFleetRequested());
              },
            );
          }

          final openBids = state.shipments
              .where((e) => e.status == LoadStatus.pendingBid)
              .toList();

          final activeOrders = state.shipments
              .where((e) =>
                  e.status != LoadStatus.pendingBid &&
                  e.status != LoadStatus.completedPayoutReleased)
              .toList();

          final totalTrucks = fleetState.trucks.length;
          final assignedTrucks = fleetState.trucks.where((t) => t.isAssigned).length;
          final availableTrucks = totalTrucks - assignedTrucks;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Carrier Fleet Status Card (Pure Neumorphism, Real Data)
                NeuCard(
                  padding: const EdgeInsets.all(18),
                  borderRadius: 18,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'fleet.readiness'.tr(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                          NeuChip(
                            label: '$totalTrucks ${'fleet.unitsTotal'.tr()}',
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _FleetCounter(
                            label: 'fleet.onRoad'.tr(),
                            count: '$assignedTrucks',
                            isDark: isDark,
                          ),
                          _FleetCounter(
                            label: 'fleet.available'.tr(),
                            count: '$availableTrucks',
                            isDark: isDark,
                          ),
                          _FleetCounter(
                            label: 'fleet.totalDrivers'.tr(),
                            count: '${fleetState.drivers.length}',
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // KPI Metric Cards
                Row(
                  children: [
                    Expanded(
                      child: NeuCard(
                        onTap: () => context.go('/shipments'),
                        padding: const EdgeInsets.all(16),
                        borderRadius: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            NeuIconButton(
                              icon: Icons.alt_route_rounded,
                              size: 38,
                              iconSize: 20,
                              onPressed: () => context.go('/shipments'),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '${activeOrders.length}',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'dashboard.activeOrders'.tr(),
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: NeuCard(
                        onTap: () => context.go('/shipments'),
                        padding: const EdgeInsets.all(16),
                        borderRadius: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            NeuIconButton(
                              icon: Icons.gavel_outlined,
                              size: 38,
                              iconSize: 20,
                              onPressed: () => context.go('/shipments'),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '${openBids.length}',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'dashboard.availableLoads'.tr(),
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Available Loads on Market
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'dashboard.availableLoadsToBid'.tr(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    if (openBids.isNotEmpty)
                      GestureDetector(
                        onTap: () => context.go('/shipments'),
                        child: Text(
                          'dashboard.viewAll'.tr(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                if (openBids.isEmpty)
                  NeuEmptyState(
                    icon: Icons.local_shipping_outlined,
                    title: 'shipments.noAvailableLoads'.tr(),
                    subtitle: 'shipments.noAvailableLoadsDesc'.tr(),
                    actionText: 'common.refresh'.tr(),
                    onAction: () => context.read<ShipmentBloc>().add(const LoadShipmentsRequested()),
                  )
                else
                  ...openBids.take(4).map((shipment) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ShipmentCard(
                        shipment: shipment,
                        onTap: () => context.push('/shipments/${shipment.id}'),
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FleetCounter extends StatelessWidget {
  final String label;
  final String count;
  final bool isDark;

  const _FleetCounter({
    required this.label,
    required this.count,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
      ],
    );
  }
}
