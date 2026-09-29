import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../../core/widgets/status_badge.dart';
import '../bloc/dispute_bloc.dart';
import '../bloc/dispute_event.dart';
import '../bloc/dispute_state.dart';

class DisputeListScreen extends StatefulWidget {
  const DisputeListScreen({super.key});

  @override
  State<DisputeListScreen> createState() => _DisputeListScreenState();
}

class _DisputeListScreenState extends State<DisputeListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DisputeBloc>().add(LoadDisputesRequested());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormatter = NumberFormat('#,###', 'en_US');
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text('disputes.title'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.rose),
            tooltip: 'disputes.openDispute'.tr(),
            onPressed: () => context.push('/disputes/create'),
          ),
        ],
      ),
      body: BlocBuilder<DisputeBloc, DisputeState>(
        builder: (context, state) {
          if (state.status == DisputeStateStatus.loading && state.disputes.isEmpty) {
            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: 3,
              itemBuilder: (_, __) => const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: SkeletonLoader(width: double.infinity, height: 130),
              ),
            );
          }

          if (state.disputes.isEmpty) {
            return EmptyStateView(
              icon: Icons.gavel_outlined,
              title: 'common.noData'.tr(),
              description: 'No active or resolved dispute claims found.',
              actionText: 'disputes.openDispute'.tr(),
              onAction: () => context.push('/disputes/create'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<DisputeBloc>().add(LoadDisputesRequested());
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              itemCount: state.disputes.length,
              itemBuilder: (context, index) {
                final dispute = state.disputes[index];

                return InkWell(
                  onTap: () => context.push('/disputes/${dispute.id}'),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row: ID + Status
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(dispute.reason.icon, size: 18, color: AppColors.rose),
                                const SizedBox(width: 8),
                                Text(
                                  dispute.id,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            StatusBadge(
                              label: dispute.status.labelKey.tr(),
                              color: dispute.status.color,
                              fontSize: 10,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Reason Title & Tracking
                        Text(
                          dispute.reason.labelKey.tr(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Load: ${dispute.trackingCode} • ${dispute.claimantName}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          dispute.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 10),

                        // Bottom row: Claim Amount & Date
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${'disputes.claimAmount'.tr()}: ${currencyFormatter.format(dispute.claimAmount)} UZS',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.rose,
                              ),
                            ),
                            Text(
                              dateFormat.format(dispute.createdAt),
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/disputes/create'),
        icon: const Icon(Icons.add_circle_outline_rounded),
        label: Text('disputes.openDispute'.tr()),
        backgroundColor: AppColors.rose,
        foregroundColor: Colors.white,
      ),
    );
  }
}
