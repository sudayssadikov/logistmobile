import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../bloc/user_moderation_bloc.dart';
import '../../../domain/models/verification_request_model.dart';
import '../../widgets/kyc_moderation_card.dart';

class AdminKycModerationView extends StatefulWidget {
  const AdminKycModerationView({super.key});

  @override
  State<AdminKycModerationView> createState() => _AdminKycModerationViewState();
}

class _AdminKycModerationViewState extends State<AdminKycModerationView> {
  VerificationStatus _filter = VerificationStatus.pending;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<UserModerationBloc, UserModerationState>(
      listener: (context, state) {
        if (state.actionSuccessMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.actionSuccessMessage!),
              backgroundColor: AppColors.emerald,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state.isLoading && state.pendingVerifications.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final filtered = state.pendingVerifications.where((v) => v.status == _filter).toList();

        return Column(
          children: [
            // Status Filter Chips
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('Kutilmoqda (${state.pendingVerifications.where((v) => v.status == VerificationStatus.pending).length})', VerificationStatus.pending),
                    const SizedBox(width: 8),
                    _buildFilterChip('Tasdiqlangan', VerificationStatus.approved),
                    const SizedBox(width: 8),
                    _buildFilterChip('Rad etilgan', VerificationStatus.rejected),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),

            // Moderation Cards List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_outline_rounded, size: 48, color: AppColors.emerald.withValues(alpha: 0.5)),
                          const SizedBox(height: 12),
                          Text(
                            'Ushbu bo\'limda arizalar mavjud emas',
                            style: TextStyle(color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final req = filtered[index];
                        return KycModerationCard(
                          request: req,
                          onApprove: () {
                            context.read<UserModerationBloc>().add(
                                  ModerateKycDocumentEvent(
                                    requestId: req.id,
                                    status: VerificationStatus.approved,
                                  ),
                                );
                          },
                          onReject: (reason) {
                            context.read<UserModerationBloc>().add(
                                  ModerateKycDocumentEvent(
                                    requestId: req.id,
                                    status: VerificationStatus.rejected,
                                    reason: reason,
                                  ),
                                );
                          },
                          onRequestReupload: () {
                            context.read<UserModerationBloc>().add(
                                  ModerateKycDocumentEvent(
                                    requestId: req.id,
                                    status: VerificationStatus.reuploadRequested,
                                    reason: 'Hujjat rasmi xira olingan, qayta yuklang',
                                  ),
                                );
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterChip(String label, VerificationStatus status) {
    final isSelected = _filter == status;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _filter = status),
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? Colors.white : null,
      ),
    );
  }
}
