import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/neu_design_system.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../shipments/domain/models/load_status.dart';
import '../../../shipments/presentation/bloc/shipment_bloc.dart';
import '../../../shipments/presentation/bloc/shipment_event.dart';
import '../../../shipments/presentation/bloc/shipment_state.dart';
import '../../../shipments/presentation/widgets/shipment_card.dart';
import '../../../wallet_escrow/presentation/bloc/wallet_bloc.dart';
import '../../../wallet_escrow/presentation/bloc/wallet_event.dart';

class ShipperDashboardView extends StatelessWidget {
  const ShipperDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = context.watch<AuthBloc>().state.user;
    final walletState = context.watch<WalletBloc>().state;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: NeuAppBar(
        title: user?.companyName ?? 'Shipper Workspace',
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
            return const SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  NeuSkeleton(width: double.infinity, height: 140, borderRadius: 16),
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
                  SizedBox(height: 12),
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
                context.read<WalletBloc>().add(LoadWalletRequested());
              },
            );
          }

          final activeShipments = state.shipments
              .where((e) => e.status != LoadStatus.completedPayoutReleased)
              .toList();

          final escrowHoldText = walletState.wallet?.escrowHoldFormatted ?? '0 UZS';

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Neumorphic CTA Banner (Clean light/dark surface, no gradient)
                NeuCard(
                  padding: const EdgeInsets.all(20),
                  borderRadius: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'dashboard.bannerTitle'.tr(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'dashboard.bannerDesc'.tr(),
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      NeuButton(
                        text: 'dashboard.postLoadBtn'.tr(),
                        icon: Icons.add_circle_outline_rounded,
                        variant: NeuButtonVariant.primary,
                        height: 44,
                        onPressed: () => context.push('/create-load'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Key KPI Metrics (Strict Neumorphism, real backend values, no fake labels)
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
                              icon: Icons.local_shipping_outlined,
                              size: 38,
                              iconSize: 20,
                              onPressed: () => context.go('/shipments'),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '${activeShipments.length}',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'dashboard.activeInTransit'.tr(),
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
                        onTap: () => context.go('/wallet'),
                        padding: const EdgeInsets.all(16),
                        borderRadius: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            NeuIconButton(
                              icon: Icons.shield_outlined,
                              size: 38,
                              iconSize: 20,
                              onPressed: () => context.go('/wallet'),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              escrowHoldText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'dashboard.escrowProtected'.tr(),
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

                // Active Shipments Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'dashboard.activeShipments'.tr(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    if (activeShipments.isNotEmpty)
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

                // Active Shipments List or NeuEmptyState
                if (activeShipments.isEmpty)
                  NeuEmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'shipments.emptyActiveTitle'.tr(),
                    subtitle: 'shipments.emptyActiveDesc'.tr(),
                    actionText: 'dashboard.postLoadBtn'.tr(),
                    onAction: () => context.push('/create-load'),
                  )
                else
                  ...activeShipments.take(4).map((shipment) {
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
