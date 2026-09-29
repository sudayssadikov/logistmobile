import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/models/document_model.dart';

class DocumentCard extends StatelessWidget {
  final DocumentModel document;
  final VoidCallback? onDelete;
  final VoidCallback? onView;

  const DocumentCard({
    super.key,
    required this.document,
    this.onDelete,
    this.onView,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final expStatus = document.expirationStatus;
    final verStatus = document.verificationStatus;
    final dateFormat = DateFormat('yyyy-MM-dd');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: expStatus == ExpirationStatus.expired || verStatus == DocumentVerificationStatus.rejected
              ? AppColors.rose.withValues(alpha: 0.4)
              : expStatus == ExpirationStatus.expiringSoon
                  ? AppColors.amber.withValues(alpha: 0.4)
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Icon + Type + Expiration Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: document.docType.targetRole.name == 'driver'
                        ? AppColors.indigo.withValues(alpha: 0.12)
                        : document.docType.targetRole.name == 'carrier'
                            ? AppColors.primary.withValues(alpha: 0.12)
                            : AppColors.cyan.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    document.docType.icon,
                    size: 22,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        document.docType.labelKey.tr(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${'documents.docNumber'.tr()}: ${document.docNumber}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusBadge(
                  label: expStatus.labelKey.tr(),
                  color: expStatus.color,
                  fontSize: 10,
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Date info & Verification status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'documents.expiresOn'.tr(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateFormat.format(document.expiryDate),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: expStatus == ExpirationStatus.expired
                            ? AppColors.rose
                            : expStatus == ExpirationStatus.expiringSoon
                                ? AppColors.amber
                                : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                      ),
                    ),
                  ],
                ),
                StatusBadge(
                  label: verStatus.labelKey.tr(),
                  color: verStatus.color,
                  icon: verStatus == DocumentVerificationStatus.verified
                      ? Icons.check_circle_outline_rounded
                      : verStatus == DocumentVerificationStatus.rejected
                          ? Icons.cancel_outlined
                          : Icons.hourglass_top_rounded,
                  fontSize: 11,
                ),
              ],
            ),

            if (document.rejectionReason != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.rose.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.rose),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        document.rejectionReason!,
                        style: const TextStyle(fontSize: 11, color: AppColors.rose),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (document.fileName != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.attach_file_rounded, size: 14, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      document.fileName!,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  if (onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.rose),
                      visualDensity: VisualDensity.compact,
                      onPressed: onDelete,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
