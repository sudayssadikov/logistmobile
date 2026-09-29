import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';

class EscrowVisualizerWidget extends StatelessWidget {
  final double inEscrowAmount;

  const EscrowVisualizerWidget({
    super.key,
    required this.inEscrowAmount,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
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
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.emerald.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.shield_rounded, color: AppColors.emerald, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'wallet.pipelineTitle'.tr(),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.emerald.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'wallet.protected100'.tr(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.emerald,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 3 Steps
          _PipelineStep(
            stepNumber: '1',
            title: 'wallet.step1Title'.tr(),
            subtitle: 'wallet.step1Desc'.tr(),
            isCompleted: true,
            isLast: false,
          ),
          _PipelineStep(
            stepNumber: '2',
            title: 'wallet.step2Title'.tr(),
            subtitle: 'wallet.step2Desc'.tr(),
            isCompleted: true,
            isLast: false,
          ),
          _PipelineStep(
            stepNumber: '3',
            title: 'wallet.step3Title'.tr(),
            subtitle: 'wallet.step3Desc'.tr(),
            isCompleted: false,
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _PipelineStep extends StatelessWidget {
  final String stepNumber;
  final String title;
  final String subtitle;
  final bool isCompleted;
  final bool isLast;

  const _PipelineStep({
    required this.stepNumber,
    required this.title,
    required this.subtitle,
    required this.isCompleted,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted ? AppColors.emerald : (isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated),
                  border: Border.all(
                    color: isCompleted ? AppColors.emerald : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                      : Text(
                          stepNumber,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isCompleted ? AppColors.emerald.withValues(alpha: 0.4) : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
