import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/models/shipment_model.dart';

class ShipmentCard extends StatelessWidget {
  final ShipmentModel shipment;
  final VoidCallback onTap;

  const ShipmentCard({
    super.key,
    required this.shipment,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormatter = NumberFormat('#,###', 'en_US');

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: NeuCard(
        onTap: onTap,
        padding: const EdgeInsets.all(18.0),
        borderRadius: 22,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Code + Status Badge + Escrow Lock
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      shipment.trackingCode,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        fontFamily: 'monospace',
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    if (shipment.isEscrowFunded) ...[
                      const SizedBox(width: 8),
                      const StatusBadge(
                        label: 'Escrow',
                        color: AppColors.emerald,
                        icon: Icons.lock_outline_rounded,
                        fontSize: 10,
                      ),
                    ],
                  ],
                ),
                StatusBadge(
                  label: shipment.status.label,
                  color: shipment.status.color,
                  fontSize: 11,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Cargo Title & Specs
            Text(
              shipment.cargoTitle.tr(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${shipment.cargoType.tr()} • ${shipment.weightTons} ${'shipments.tons'.tr()} • ${shipment.volumeM3} m³',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 14),

            // Route Segment: Origin -> Destination (Subtle Hairline Bento Container)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfacePressed : AppColors.lightSurfacePressed,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  Column(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(
                        width: 1.5,
                        height: 20,
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppColors.emerald,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              shipment.origin.city.tr(),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.2,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                            ),
                            Text(
                              '${shipment.distanceKm.toStringAsFixed(0)} km',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.cyan,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          shipment.destination.city.tr(),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Bottom Row: Price & Carrier info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'shipments.offerRate'.tr().toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${currencyFormatter.format(shipment.price)} UZS',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.primary,
                      ),
                    ),
                  ],
                ),
                if (shipment.driverName != null)
                  Row(
                    children: [
                      Icon(Icons.person_pin_circle_outlined,
                          size: 16, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                      const SizedBox(width: 4),
                      Text(
                        shipment.driverName!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  )
                else if (shipment.bids.isNotEmpty)
                  StatusBadge(
                    label: '${shipment.bids.length} ${'shipments.bidsSuffix'.tr()}',
                    color: AppColors.indigo,
                    fontSize: 11,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

