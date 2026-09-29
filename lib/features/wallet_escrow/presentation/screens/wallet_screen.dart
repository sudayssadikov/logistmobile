import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/metric_card.dart';
import '../../domain/models/wallet_model.dart';
import '../bloc/wallet_bloc.dart';
import '../bloc/wallet_event.dart';
import '../bloc/wallet_state.dart';
import '../widgets/escrow_visualizer_widget.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  @override
  void initState() {
    super.initState();
    context.read<WalletBloc>().add(FetchWalletSummaryRequested());
  }

  void _showDepositModal(BuildContext context) {
    final amountController = TextEditingController(text: '10000000');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          top: 24,
          left: 20,
          right: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'wallet.depositModalTitle'.tr(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'wallet.depositModalDesc'.tr(),
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 20),
            AppTextField(
              label: '${'wallet.deposit'.tr()} (UZS)',
              controller: amountController,
              keyboardType: TextInputType.number,
              suffixIcon: const Padding(
                padding: EdgeInsets.all(14.0),
                child: Text('UZS', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              text: 'common.confirm'.tr(),
              onPressed: () {
                final amount = double.tryParse(amountController.text) ?? 10000000.0;
                Navigator.of(ctx).pop();
                context.read<WalletBloc>().add(DepositFundsSubmitted(amount));
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showWithdrawModal(BuildContext context) {
    final amountController = TextEditingController(text: '5000000');
    final cardController = TextEditingController(text: '8600 •••• •••• 9921');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          top: 24,
          left: 20,
          right: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'wallet.withdrawModalTitle'.tr(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'wallet.withdrawModalDesc'.tr(),
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: '${'wallet.withdraw'.tr()} (UZS)',
              controller: amountController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Destination Card / Account',
              controller: cardController,
            ),
            const SizedBox(height: 24),
            AppButton(
              text: 'common.submit'.tr(),
              onPressed: () {
                final amount = double.tryParse(amountController.text) ?? 5000000.0;
                Navigator.of(ctx).pop();
                context.read<WalletBloc>().add(
                      WithdrawFundsSubmitted(
                        amount: amount,
                        cardNumber: cardController.text,
                      ),
                    );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormatter = NumberFormat('#,###', 'en_US');

    return Scaffold(
      appBar: AppBar(
        title: Text('nav.escrow'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => context.read<WalletBloc>().add(FetchWalletSummaryRequested()),
          ),
        ],
      ),
      body: BlocConsumer<WalletBloc, WalletState>(
        listener: (context, state) {
          if (state.status == WalletStateStatus.actionSuccess && state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.successMessage!),
                backgroundColor: AppColors.emerald,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          final wallet = state.wallet ??
              const WalletModel(
                availableBalance: 42500000.0,
                inEscrowHoldBalance: 28000000.0,
                pendingPayouts: 16500000.0,
                totalLifetimeEarnings: 312000000.0,
              );

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Primary Total Balance Banner
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'wallet.availableBalance'.tr(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: Colors.white70,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'wallet.instantAccess'.tr(),
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${currencyFormatter.format(wallet.availableBalance)} UZS',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              text: 'wallet.deposit'.tr(),
                              height: 38,
                              variant: AppButtonVariant.secondary,
                              prefixIcon: Icons.add_rounded,
                              onPressed: () => _showDepositModal(context),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: AppButton(
                              text: 'wallet.withdraw'.tr(),
                              height: 38,
                              variant: AppButtonVariant.secondary,
                              prefixIcon: Icons.arrow_outward_rounded,
                              onPressed: () => _showWithdrawModal(context),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Financial KPI Metrics Grid
                Row(
                  children: [
                    Expanded(
                      child: MetricCard(
                        title: 'wallet.lockedInEscrow'.tr(),
                        value: '${(wallet.inEscrowHoldBalance / 1000000).toStringAsFixed(1)}M',
                        subtitle: 'wallet.safeInVault'.tr(),
                        icon: Icons.lock_clock_rounded,
                        iconColor: AppColors.amber,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: MetricCard(
                        title: 'wallet.pendingPayouts'.tr(),
                        value: '${(wallet.pendingPayouts / 1000000).toStringAsFixed(1)}M',
                        subtitle: 'wallet.uponPodSign'.tr(),
                        icon: Icons.hourglass_top_rounded,
                        iconColor: AppColors.emerald,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Escrow Pipeline Visualizer
                EscrowVisualizerWidget(inEscrowAmount: wallet.inEscrowHoldBalance),
                const SizedBox(height: 24),

                // Transaction History Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'wallet.transactionHistory'.tr(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Transactions List
                if (wallet.transactions.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('common.noData'.tr()),
                    ),
                  )
                else
                  ...wallet.transactions.map((txn) {
                    final isPositive = txn.type == TransactionType.deposit ||
                        txn.type == TransactionType.escrowRelease;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isPositive
                                  ? AppColors.emerald.withValues(alpha: 0.12)
                                  : AppColors.rose.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              isPositive ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                              color: isPositive ? AppColors.emerald : AppColors.rose,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  txn.title.tr(),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${txn.id} • ${DateFormat('dd MMM, HH:mm').format(txn.timestamp)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${isPositive ? '+' : '-'}${currencyFormatter.format(txn.amount)}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isPositive ? AppColors.emerald : AppColors.rose,
                            ),
                          ),
                        ],
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
