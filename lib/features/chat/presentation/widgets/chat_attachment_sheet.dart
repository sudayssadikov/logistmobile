import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../domain/models/chat_message_model.dart';

class ChatAttachmentSheet extends StatelessWidget {
  final Function({
    required String content,
    required MessageType type,
    MediaAttachment? mediaAttachment,
    LocationPinPayload? locationPayload,
  }) onAttachmentSelected;

  const ChatAttachmentSheet({
    super.key,
    required this.onAttachmentSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'chat.attachDoc'.tr(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 4 Core Attachment Action Grid
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _AttachmentTile(
                  icon: Icons.description_rounded,
                  label: 'Document',
                  color: AppColors.primary,
                  onTap: () {
                    Navigator.pop(context);
                    onAttachmentSelected(
                      content: 'CMR_Waybill_01842.pdf',
                      type: MessageType.document,
                      mediaAttachment: const MediaAttachment(
                        url: 'https://logiflow.uz/docs/cmr_01842.pdf',
                        fileName: 'CMR_International_Waybill_#01842.pdf',
                        fileSizeBytes: 2450000,
                        extension: 'PDF',
                        mimeType: 'application/pdf',
                      ),
                    );
                  },
                ),
                _AttachmentTile(
                  icon: Icons.photo_library_rounded,
                  label: 'Photo / Seal',
                  color: AppColors.cyan,
                  onTap: () {
                    Navigator.pop(context);
                    onAttachmentSelected(
                      content: 'Trailer Security Seals Intact Photo',
                      type: MessageType.image,
                      mediaAttachment: const MediaAttachment(
                        url: 'https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d?w=800',
                        fileName: 'trailer_seal_dock_inspection.jpg',
                        fileSizeBytes: 3800000,
                        extension: 'JPG',
                        mimeType: 'image/jpeg',
                      ),
                    );
                  },
                ),
                _AttachmentTile(
                  icon: Icons.location_on_rounded,
                  label: 'Live Location',
                  color: AppColors.emerald,
                  onTap: () {
                    Navigator.pop(context);
                    onAttachmentSelected(
                      content: 'Live GPS Pin (M39 Highway, Jizzax)',
                      type: MessageType.locationPin,
                      locationPayload: const LocationPinPayload(
                        latitude: 40.1158,
                        longitude: 67.8422,
                        title: 'M39 Highway Checkpoint',
                        address: 'Toshkent - Samarqand trassasi, 210-km',
                      ),
                    );
                  },
                ),
                _AttachmentTile(
                  icon: Icons.receipt_long_rounded,
                  label: 'Invoice / TTN',
                  color: AppColors.amber,
                  onTap: () {
                    Navigator.pop(context);
                    onAttachmentSelected(
                      content: 'TTN_Consignment_Invoice_#9920.pdf',
                      type: MessageType.document,
                      mediaAttachment: const MediaAttachment(
                        url: 'https://logiflow.uz/docs/ttn_9920.pdf',
                        fileName: 'TTN_Consignment_Invoice_#9920.pdf',
                        fileSizeBytes: 1420000,
                        extension: 'PDF',
                        mimeType: 'application/pdf',
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AttachmentTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
