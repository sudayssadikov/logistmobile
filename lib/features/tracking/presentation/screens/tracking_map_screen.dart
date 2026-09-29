import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/models/tracking_data_model.dart';
import '../bloc/tracking_bloc.dart';
import '../bloc/tracking_event.dart';
import '../bloc/tracking_state.dart';
import '../widgets/interactive_osm_map.dart';

class TrackingMapScreen extends StatefulWidget {
  final String shipmentId;

  const TrackingMapScreen({super.key, required this.shipmentId});

  @override
  State<TrackingMapScreen> createState() => _TrackingMapScreenState();
}

class _TrackingMapScreenState extends State<TrackingMapScreen> {
  @override
  void initState() {
    super.initState();
    context.read<TrackingBloc>().add(StartTrackingSessionRequested(widget.shipmentId));
  }

  void _openExternalNavigator(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('tracking.openInApp'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.navigation_rounded, color: AppColors.primary),
                title: const Text('Yandex Maps / Navigator'),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Launching route in Yandex Maps...')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.map_rounded, color: AppColors.emerald),
                title: const Text('Google Maps'),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Launching route in Google Maps...')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<TrackingBloc, TrackingState>(
      builder: (context, state) {
        final trackingData = state.trackingData;
        final telemetry = trackingData?.currentTelemetry ??
            TelemetryUpdate(
              latitude: 40.8719,
              longitude: 68.7561,
              speedKmh: 78.4,
              headingDegrees: 224.0,
              altitudeMeters: 312.0,
              batteryPercent: 94,
              distanceRemainingKm: 138.0,
              eta: '2h 15m',
              nextWaypointName: 'Gulistan Junction',
              timestamp: DateTime.now(),
            );

        return Scaffold(
          body: Stack(
            children: [
              // 100% Free OpenStreetMap + OSRM Road Polyline Map
              Positioned.fill(
                child: InteractiveOsmMap(
                  route: trackingData?.routePolyline ?? const [
                    LatLngPoint(latitude: 41.22, longitude: 69.21),
                    LatLngPoint(latitude: 39.65, longitude: 66.95),
                  ],
                  telemetry: telemetry,
                  origin: trackingData?.origin ?? const LatLngPoint(latitude: 41.22, longitude: 69.21),
                  destination: trackingData?.destination ?? const LatLngPoint(latitude: 39.65, longitude: 66.95),
                ),
              ),

              // Top Floating App Bar with Highway Tag
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: (isDark ? AppColors.darkSurface : Colors.white).withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            ),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_rounded, size: 20),
                            onPressed: () {
                              context.read<TrackingBloc>().add(StopTrackingSessionRequested());
                              context.pop();
                            },
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: (isDark ? AppColors.darkSurface : Colors.white).withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.emerald,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${'tracking.liveGps'.tr()} • ${trackingData?.trackingCode ?? "LF-UZ-8921"}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: (isDark ? AppColors.darkSurface : Colors.white).withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            ),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.navigation_rounded, size: 20, color: AppColors.primary),
                            tooltip: 'tracking.externalNavigator'.tr(),
                            onPressed: () => _openExternalNavigator(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom Telemetry Dashboard Card
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: (isDark ? AppColors.darkSurface : Colors.white).withValues(alpha: 0.95),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    border: Border(
                      top: BorderSide(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 24,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Driver and Vehicle Header
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.directions_car_filled_rounded, color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    trackingData?.driverName ?? 'Rustam Karimov',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${trackingData?.vehiclePlate ?? "01 842 TAA"} • Volvo FH16',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            StatusBadge(
                              label: telemetry.eta,
                              color: AppColors.primary,
                              icon: Icons.timer_outlined,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 12),

                        // Telemetry Grid: Speed, Distance, Heading
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _TelemetryMetric(
                              label: 'tracking.speed'.tr(),
                              value: '${telemetry.speedKmh.toStringAsFixed(0)} km/h',
                              color: AppColors.primary,
                              icon: Icons.speed_rounded,
                            ),
                            _TelemetryMetric(
                              label: 'tracking.distanceLeft'.tr(),
                              value: '${telemetry.distanceRemainingKm.toStringAsFixed(0)} km',
                              color: AppColors.emerald,
                              icon: Icons.route_rounded,
                            ),
                            _TelemetryMetric(
                              label: 'tracking.heading'.tr(),
                              value: '${telemetry.headingDegrees.toStringAsFixed(0)}° SW',
                              color: AppColors.amber,
                              icon: Icons.explore_rounded,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Action Buttons: Open Nav & Chat
                        Row(
                          children: [
                            Expanded(
                              child: AppButton(
                                text: 'tracking.externalNavigator'.tr(),
                                variant: AppButtonVariant.outline,
                                prefixIcon: Icons.directions_outlined,
                                height: 42,
                                onPressed: () => _openExternalNavigator(context),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: AppButton(
                                text: 'shipments.directChat'.tr(),
                                prefixIcon: Icons.chat_bubble_outline_rounded,
                                height: 42,
                                onPressed: () => context.push('/chat/${widget.shipmentId}'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TelemetryMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _TelemetryMetric({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          ),
        ),
      ],
    );
  }
}
