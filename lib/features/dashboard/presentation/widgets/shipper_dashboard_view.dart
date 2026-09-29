import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/metric_card.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../shipments/domain/models/load_status.dart';
import '../../../shipments/presentation/bloc/shipment_bloc.dart';
import '../../../shipments/presentation/bloc/shipment_state.dart';
import '../../../shipments/presentation/widgets/shipment_card.dart';

class ShipperDashboardView extends StatelessWidget {
  const ShipperDashboardView({super.key});

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
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.inventory_2_rounded, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.companyName ?? 'Shipper Workspace',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                Text(
                  '${'roles.shipper'.tr()} • ${user?.fullName ?? "User"}',
                  style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
      body: BlocBuilder<ShipmentBloc, ShipmentState>(
        builder: (context, state) {
          final activeShipments = state.shipments.where((e) => e.status != LoadStatus.completedPayoutReleased).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Quick CTA Banner: Post Load & Escrow Guarantee
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'dashboard.bannerTitle'.tr(),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'dashboard.bannerDesc'.tr(),
                        style: const TextStyle(fontSize: 12, color: Colors.white70, height: 1.4),
                      ),
                      const SizedBox(height: 16),
                      AppButton(
                        text: 'dashboard.postLoadBtn'.tr(),
                        height: 38,
                        variant: AppButtonVariant.secondary,
                        prefixIcon: Icons.add_circle_outline_rounded,
                        onPressed: () => context.push('/create-load'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Shipper Key KPI Metrics
                Row(
                  children: [
                    Expanded(
                      child: MetricCard(
                        title: 'dashboard.activeInTransit'.tr(),
                        value: '${activeShipments.length}',
                        trendText: 'dashboard.loadsCount'.tr(),
                        icon: Icons.local_shipping_rounded,
                        iconColor: AppColors.primary,
                        onTap: () => context.go('/shipments'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: MetricCard(
                        title: 'dashboard.escrowProtected'.tr(),
                        value: '28.0M',
                        trendText: 'dashboard.safe100'.tr(),
                        icon: Icons.shield_rounded,
                        iconColor: AppColors.emerald,
                        onTap: () => context.go('/wallet'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Active Priority Shipments Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'dashboard.activeShipments'.tr(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/shipments'),
                      child: Text('dashboard.viewAll'.tr(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                ...activeShipments.take(3).map((shipment) {
                  return ShipmentCard(
                    shipment: shipment,
                    onTap: () => context.push('/shipments/${shipment.id}'),
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
