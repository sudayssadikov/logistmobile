import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../bloc/admin_dashboard_bloc.dart';
import '../../widgets/admin_metric_card.dart';
import '../../widgets/audit_log_tile.dart';

class AdminAnalyticsView extends StatelessWidget {
  const AdminAnalyticsView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormatter = NumberFormat('#,###');

    return BlocBuilder<AdminDashboardBloc, AdminDashboardState>(
      builder: (context, state) {
        if (state.isLoading && state.kpis == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final kpis = state.kpis;
        if (kpis == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: NeuCard(
                borderRadius: 22,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.rose.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.cloud_off_rounded, color: AppColors.rose, size: 26),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Serverga ulanishda xatolik',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.3),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.errorMessage ?? 'Backend serverdan ma\'lumot olib bo\'lmadi.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 18),
                    NeuButton(
                      text: 'Qayta urinish',
                      icon: Icons.refresh_rounded,
                      width: 170,
                      height: 44,
                      onPressed: () {
                        context.read<AdminDashboardBloc>().add(AdminFetchDashboardDataEvent());
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            context.read<AdminDashboardBloc>().add(AdminRefreshKpiEvent());
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top GMV & Commission Summary Banner (Neumorphic)
                NeuCard(
                  padding: const EdgeInsets.all(20),
                  borderRadius: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.emerald,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'GLOBAL GMV & PLATFORM REVENUE',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                          NeuChip(
                            label: '${kpis.systemUptimePercent}% UPTIME',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${currencyFormatter.format(kpis.totalGmv)} UZS',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Platforma Komissiya Daromadi: ${currencyFormatter.format(kpis.totalRevenueCommission)} UZS',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Core 4 Metric Cards
                Row(
                  children: [
                    Expanded(
                      child: AdminMetricCard(
                        title: 'Eskrou Jamg\'armasi',
                        value: '${currencyFormatter.format(kpis.totalEscrowHeld)} UZS',
                        subtitle: '100% Bloklangan',
                        icon: Icons.shield_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AdminMetricCard(
                        title: 'Yo\'ldagi Furalar',
                        value: '${kpis.activeLoadsInTransit} ta reys',
                        subtitle: 'Jonli GPS oqimi',
                        icon: Icons.local_shipping_rounded,
                        color: AppColors.emerald,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AdminMetricCard(
                        title: 'Kutilayotgan KYC',
                        value: '${kpis.pendingKycCount} ta hujjat',
                        subtitle: 'Moderatsiya navbati',
                        icon: Icons.verified_user_rounded,
                        color: AppColors.amber,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AdminMetricCard(
                        title: 'Ochiq Nizolar',
                        value: '${kpis.openDisputesCount} ta da\'vo',
                        subtitle: 'Arbitraj kutilmoqda',
                        icon: Icons.gavel_rounded,
                        color: AppColors.rose,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // User Ecosystem KPIs
                Text(
                  'FOYDALANUVCHILAR EKOTIZIMI',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ),
                const SizedBox(height: 12),
                NeuCard(
                  padding: const EdgeInsets.all(16),
                  borderRadius: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMiniCounter('Yuk egalari', '${kpis.totalShippersCount}', AppColors.primary, isDark),
                      _buildMiniCounter('Tashuvchilar', '${kpis.totalCarriersCount}', AppColors.neutral, isDark),
                      _buildMiniCounter('Haydovchilar', '${kpis.activeDriversOnDuty}', AppColors.primary, isDark),
                      _buildMiniCounter('Bajarilgan', '${kpis.completedDeliveriesCount}', AppColors.neutral, isDark),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Live Security Audit Logs Preview
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'XAVFSIZLIK & AUDIT OQIMI',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                    ),
                    const Text(
                      'Jonli rejim',
                      style: TextStyle(fontSize: 11, color: AppColors.emerald, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Column(
                  children: state.recentAuditLogs.take(4).map((log) => AuditLogTile(log: log)).toList(),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMiniCounter(String label, String value, Color color, bool isDark) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          ),
        ),
      ],
    );
  }
}
