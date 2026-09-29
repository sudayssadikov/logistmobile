import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/models/dispute_model.dart';
import '../bloc/dispute_bloc.dart';
import '../bloc/dispute_event.dart';
import '../bloc/dispute_state.dart';

class DisputeDetailScreen extends StatefulWidget {
  final String disputeId;

  const DisputeDetailScreen({super.key, required this.disputeId});

  @override
  State<DisputeDetailScreen> createState() => _DisputeDetailScreenState();
}

class _DisputeDetailScreenState extends State<DisputeDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DisputeBloc>().add(LoadDisputeDetailRequested(widget.disputeId));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormatter = NumberFormat('#,###', 'en_US');
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.disputeId),
      ),
      body: BlocBuilder<DisputeBloc, DisputeState>(
        builder: (context, state) {
          final dispute = state.disputes.firstWhere(
            (d) => d.id == widget.disputeId,
            orElse: () =>
                state.selectedDispute ??
                DisputeModel(
                  id: widget.disputeId,
                  shipmentId: 'SHP-1001',
                  trackingCode: 'LF-UZ-8492',
                  claimantName: 'Agro Export Holding',
                  reason: DisputeReason.damagedCargo,
                  description: 'Cargo damage investigation.',
                  claimAmount: 2500000.0,
                  status: DisputeStatus.underReview,
                  timeline: const [],
                  createdAt: DateTime.now(),
                ),
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Claim Header
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
                          Row(
                            children: [
                              Icon(dispute.reason.icon, size: 20, color: AppColors.rose),
                              const SizedBox(width: 8),
                              Text(
                                dispute.reason.labelKey.tr(),
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          StatusBadge(
                            label: dispute.status.labelKey.tr(),
                            color: dispute.status.color,
                            fontSize: 11,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${'disputes.claimAmount'.tr()}: ${currencyFormatter.format(dispute.claimAmount)} UZS',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.rose,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Shipment: ${dispute.trackingCode} • Filed by ${dispute.claimantName}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Mediation Status Pipeline (4 Steps)
                _buildMediationTimeline(context, dispute.status),
                const SizedBox(height: 24),

                // Description
                _SectionTitle(title: 'disputes.description'.tr().toUpperCase()),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  child: Text(
                    dispute.description,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Audit History
                _SectionTitle(title: 'disputes.statusTimeline'.tr()),
                const SizedBox(height: 10),
                ...dispute.timeline.map((item) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.lightSurfaceElevated,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item.status.labelKey.tr(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: item.status.color,
                              ),
                            ),
                            Text(
                              dateFormat.format(item.timestamp),
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.message,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
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

  Widget _buildMediationTimeline(BuildContext context, DisputeStatus currentStatus) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalSteps = DisputeStatus.values.length;
    final currentIndex = currentStatus.stepIndex;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'MEDIATION PROTOCOL',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: AppColors.darkTextMuted,
                ),
              ),
              Text(
                'Step $currentIndex of $totalSteps',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: currentIndex / totalSteps,
              backgroundColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              valueColor: AlwaysStoppedAnimation<Color>(currentStatus.color),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            currentStatus.labelKey.tr(),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Text(
      title,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
      ),
    );
  }
}
