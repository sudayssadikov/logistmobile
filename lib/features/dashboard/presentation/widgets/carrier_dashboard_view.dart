import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/metric_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../shipments/domain/models/load_status.dart';
import '../../../shipments/presentation/bloc/shipment_bloc.dart';
import '../../../shipments/presentation/bloc/shipment_state.dart';
import '../../../shipments/presentation/widgets/shipment_card.dart';

class CarrierDashboardView extends StatelessWidget {
  const CarrierDashboardView({super.key});

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
                color: AppColors.indigo,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.local_shipping_rounded, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.companyName ?? 'Carrier Fleet HQ',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                Text(
                  'Carrier Portal • Rating: ${user?.rating ?? 4.9} ★',
                  style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: BlocBuilder<ShipmentBloc, ShipmentState>(
        builder: (context, state) {
          final openBids = state.shipments.where((e) => e.status == LoadStatus.pendingBid).toList();
          final activeOrders = state.shipments.where((e) => e.status != LoadStatus.pendingBid && e.status != LoadStatus.completedPayoutReleased).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Carrier Fleet Status Radar
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'FLEET READINESS',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8),
                          ),
                          StatusBadge(
                            label: '8 Units Active',
                            color: AppColors.emerald,
                            fontSize: 10,
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _FleetCounter(label: 'On Road', count: '5', color: AppColors.primary),
                          _FleetCounter(label: 'Loading', count: '2', color: AppColors.amber),
                          _FleetCounter(label: 'Idle / Available', count: '3', color: AppColors.emerald),
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
                      child: MetricCard(
                        title: 'Active Tripped Orders',
                        value: '${activeOrders.length}',
                        trendText: '+18.4%',
                        icon: Icons.alt_route_rounded,
                        iconColor: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: MetricCard(
                        title: 'Available Loads',
                        value: '${openBids.length}',
                        trendText: 'Ready to bid',
                        icon: Icons.gavel_rounded,
                        iconColor: AppColors.indigo,
                        onTap: () => context.go('/shipments'),
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
                      'AVAILABLE LOADS TO BID',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/shipments'),
                      child: const Text('Load Board', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                ...openBids.map((shipment) {
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

class _FleetCounter extends StatelessWidget {
  final String label;
  final String count;
  final Color color;

  const _FleetCounter({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(count, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}
