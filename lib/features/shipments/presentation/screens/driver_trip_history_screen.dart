import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../domain/models/load_status.dart';
import '../bloc/shipment_bloc.dart';
import '../bloc/shipment_state.dart';

class DriverTripHistoryScreen extends StatelessWidget {
  const DriverTripHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivered Trips & POD History 📦'),
      ),
      body: BlocBuilder<ShipmentBloc, ShipmentState>(
        builder: (context, state) {
          final completed = state.shipments.where((s) => s.status == LoadStatus.delivered).toList();

          // If none delivered yet, show state shipments as completed sample archive
          final trips = completed.isNotEmpty ? completed : state.shipments;

          if (trips.isEmpty) {
            return const EmptyStateView(
              icon: Icons.history_rounded,
              title: 'No delivered trips yet',
              description: 'Completed freight loads with signed POD and escrow payouts will appear here.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            itemCount: trips.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final trip = trips[index];

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Tracking Code & Payout Status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.emerald.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.check_circle_rounded, color: AppColors.emerald, size: 14),
                                  SizedBox(width: 4),
                                  Text(
                                    'POD Signed & Delivered',
                                    style: TextStyle(
                                      color: AppColors.emerald,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              trip.trackingCode,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          trip.formattedPrice,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.emerald,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Cargo Title
                    Text(
                      trip.cargoTitle.tr(),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Route Summary
                    Row(
                      children: [
                        const Icon(Icons.trip_origin_rounded, color: AppColors.emerald, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          trip.origin.city.tr(),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.grey),
                        ),
                        const Icon(Icons.location_on_rounded, color: AppColors.rose, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          trip.destination.city.tr(),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        Text(
                          '310 km • 4h 12m',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),

                    // Bottom POD Meta & Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.draw_rounded, size: 16, color: AppColors.primary),
                            SizedBox(width: 6),
                            Text(
                              'Consignee: Anvar T. (Confirmed)',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.visibility_outlined, size: 16),
                          label: const Text('View POD'),
                          onPressed: () => context.push('/pod/${trip.id}'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
