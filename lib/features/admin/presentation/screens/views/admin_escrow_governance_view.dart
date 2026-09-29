import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/status_badge.dart';
import '../../bloc/admin_finance_bloc.dart';
import '../../../domain/models/escrow_ledger_item_model.dart';

class AdminEscrowGovernanceView extends StatelessWidget {
  const AdminEscrowGovernanceView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormatter = NumberFormat('#,###');

    return BlocConsumer<AdminFinanceBloc, AdminFinanceState>(
      listener: (context, state) {
        if (state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage!),
              backgroundColor: AppColors.emerald,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state.isLoading && state.ledgerItems.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = state.ledgerItems;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Escrow Vault Header
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'ESKROU G\'AZNASI VA NAZORAT',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'KOMISSIYA: ${state.commissionRate}%',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '540,000,000 UZS',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Barcha faol yuklar bo\'yicha bloklangan va kafolatlangan mablag\'lar.',
                      style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Ledger Transactions List
              Text(
                'TRANZAKSIYALAR VA KAFOLATLAR JURNALI',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
              ),
              const SizedBox(height: 12),
              Column(
                children: items.map((item) {
                  Color statusColor = AppColors.primary;
                  if (item.status == 'RELEASED') statusColor = AppColors.emerald;
                  if (item.status == 'FROZEN') statusColor = AppColors.rose;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: item.isFlaggedSuspicious ? AppColors.rose.withValues(alpha: 0.5) : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item.trackingCode,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                            ),
                            StatusBadge(label: item.status, color: statusColor),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Yuk egasi: ${item.shipperName} ➔ Tashuvchi: ${item.carrierName}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Summa: ${currencyFormatter.format(item.amount)} UZS',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary),
                            ),
                            Text(
                              'Komissiya: ${currencyFormatter.format(item.platformFee)} UZS',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                              ),
                            ),
                          ],
                        ),
                        if (item.status == 'HOLD') ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: AppButton(
                                  text: 'Muzlatish (Freeze)',
                                  variant: AppButtonVariant.outline,
                                  height: 34,
                                  onPressed: () {
                                    context.read<AdminFinanceBloc>().add(
                                          ExecuteEscrowInterventionEvent(
                                            escrowId: item.id,
                                            action: EscrowInterventionAction.freezeHold,
                                          ),
                                        );
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: AppButton(
                                  text: 'Majburiy chiqarish',
                                  height: 34,
                                  onPressed: () {
                                    context.read<AdminFinanceBloc>().add(
                                          ExecuteEscrowInterventionEvent(
                                            escrowId: item.id,
                                            action: EscrowInterventionAction.forceRelease,
                                          ),
                                        );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}
