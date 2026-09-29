import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/status_badge.dart';
import '../../bloc/admin_disputes_bloc.dart';
import '../../../domain/models/admin_dispute_model.dart';
import '../../widgets/dispute_evidence_split_view.dart';

class AdminDisputeArbitrationView extends StatelessWidget {
  const AdminDisputeArbitrationView({super.key});

  void _showVerdictDialog(BuildContext context, AdminDisputeCaseModel dispute) {
    DisputeVerdict selectedVerdict = DisputeVerdict.splitEqual;
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Yakuniy Arbitraj Qarori', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Qaror turini tanlang:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                DropdownButtonFormField<DisputeVerdict>(
                  initialValue: selectedVerdict,
                  items: DisputeVerdict.values.map((v) {
                    return DropdownMenuItem(value: v, child: Text(v.label, style: const TextStyle(fontSize: 12)));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedVerdict = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'Qaror asosi va dalillar izohi...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Bekor qilish')),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  context.read<AdminDisputesBloc>().add(
                        SettleDisputeEvent(
                          disputeId: dispute.id,
                          verdict: selectedVerdict,
                          notes: notesController.text.trim(),
                        ),
                      );
                },
                child: const Text('Qarorni Ijro Etish'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormatter = NumberFormat('#,###');

    return BlocConsumer<AdminDisputesBloc, AdminDisputesState>(
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
        if (state.isLoading && state.disputes.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final disputes = state.disputes;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Disputes Header
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.rose.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.gavel_rounded, color: AppColors.rose, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ARBITRAJ VA NIZOLAR MARKAZI',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                          ),
                          Text(
                            'Eskrou kafolatlari ostidagi nizolarni ko\'rib chiqish va adolatli xulosa chiqarish.',
                            style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Disputes List
              Column(
                children: disputes.map((dispute) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
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
                            Text(
                              '${dispute.trackingCode} • ${dispute.category.label}',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                            ),
                            StatusBadge(label: dispute.status, color: dispute.status == 'RESOLVED' ? AppColors.emerald : AppColors.rose),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Da\'vogar: ${dispute.complainantName} ➔ Javobgar: ${dispute.respondentName}',
                          style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Da\'vo summasi: ${currencyFormatter.format(dispute.disputedAmount)} UZS',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          dispute.description,
                          style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                        ),
                        const SizedBox(height: 12),
                        DisputeEvidenceSplitView(
                          manifestUrl: dispute.shipperManifestUrl,
                          podPhotos: dispute.podEvidencePhotos,
                        ),
                        if (dispute.status != 'RESOLVED') ...[
                          const SizedBox(height: 14),
                          AppButton(
                            text: 'Arbitraj Qarorini Chiqarish',
                            prefixIcon: Icons.gavel_rounded,
                            height: 38,
                            onPressed: () => _showVerdictDialog(context, dispute),
                          ),
                        ] else if (dispute.finalVerdict != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.emerald.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Qaror: ${dispute.finalVerdict!.label}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.emerald),
                            ),
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
