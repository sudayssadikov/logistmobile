import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';

class DisputeEvidenceSplitView extends StatelessWidget {
  final String manifestUrl;
  final List<String> podPhotos;

  const DisputeEvidenceSplitView({
    super.key,
    required this.manifestUrl,
    required this.podPhotos,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DALILLARNI SOLISHTIRISH (SPLIT-VIEW EVIDENCE)',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Shipper Manifest
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Yuk egasi: Shartnoma & Nakladnoy',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        height: 110,
                        width: double.infinity,
                        color: Colors.grey.withValues(alpha: 0.2),
                        child: const Center(
                          child: Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary, size: 36),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Driver POD Photos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.emerald.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Haydovchi: POD Rasmlari',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.emerald),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        height: 110,
                        width: double.infinity,
                        color: Colors.grey.withValues(alpha: 0.2),
                        child: const Center(
                          child: Icon(Icons.camera_alt_rounded, color: AppColors.emerald, size: 36),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
