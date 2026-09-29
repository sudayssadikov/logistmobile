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
            child: Text(state.errorMessage ?? 'Ma\'lumot yuklanmadi'),
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
                // Top GMV & Commission Summary Banner
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF090D16), Color(0xFF1E293B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF334155)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.emerald,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'GLOBAL GMV & PLATFORM REVENUE',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.emerald,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${kpis.systemUptimePercent}% UPTIME',
                              style: const TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${currencyFormatter.format(kpis.totalGmv)} UZS',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Platforma Komissiya Daromadi (1.5%): ${currencyFormatter.format(kpis.totalRevenueCommission)} UZS',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
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
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMiniCounter('Yuk egalari', '${kpis.totalShippersCount}', AppColors.primary, isDark),
                      _buildMiniCounter('Tashuvchilar', '${kpis.totalCarriersCount}', AppColors.indigo, isDark),
                      _buildMiniCounter('Haydovchilar', '${kpis.activeDriversOnDuty}', AppColors.emerald, isDark),
                      _buildMiniCounter('Bajarilgan', '${kpis.completedDeliveriesCount}', Colors.purpleAccent, isDark),
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
