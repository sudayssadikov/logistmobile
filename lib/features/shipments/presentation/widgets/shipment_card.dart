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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
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
                            letterSpacing: -0.2,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        if (shipment.isEscrowFunded) ...[
                          const SizedBox(width: 8),
                          const StatusBadge(
                            label: 'Escrow Locked',
                            color: AppColors.emerald,
                            icon: Icons.lock_outline_rounded,
                            fontSize: 9,
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    letterSpacing: -0.2,
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

                // Route Segment: Origin -> Destination
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(
                            width: 1.5,
                            height: 22,
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                          Container(
                            width: 8,
                            height: 8,
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
                            const SizedBox(height: 8),
                            Text(
                              shipment.destination.city.tr(),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Bottom Row: Price & Carrier info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'shipments.offerRate'.tr(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                        Text(
                          '${currencyFormatter.format(shipment.price)} UZS',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                            color: AppColors.primaryLight,
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
        ),
      ),
    );
  }
}
