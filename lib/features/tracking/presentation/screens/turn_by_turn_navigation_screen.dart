import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../shipments/domain/models/shipment_model.dart';
import '../bloc/navigation_bloc.dart';
import '../bloc/navigation_event.dart';
import '../bloc/navigation_state.dart';

class TurnByTurnNavigationScreen extends StatefulWidget {
  final ShipmentModel shipment;

  const TurnByTurnNavigationScreen({super.key, required this.shipment});

  @override
  State<TurnByTurnNavigationScreen> createState() => _TurnByTurnNavigationScreenState();
}

class _TurnByTurnNavigationScreenState extends State<TurnByTurnNavigationScreen> {
  @override
  void initState() {
    super.initState();
    context.read<NavigationBloc>().add(StartNavigation(widget.shipment));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: BlocConsumer<NavigationBloc, NavigationState>(
        listener: (context, state) {
          if (state.spokenAlert != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.volume_up_rounded, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text('🔊 "${state.spokenAlert}"')),
                  ],
                ),
                backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                duration: const Duration(seconds: 3),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          final maneuver = state.currentManeuver ??
              const RouteManeuver(
                instructionUz: 'M39 trassasi bo\'ylab davom eting',
                instructionEn: 'Continue along M39 highway',
                instructionRu: 'Продолжайте движение по трассе М39',
                distanceText: '300 m',
                iconType: 'straight',
              );

          return Stack(
            children: [
              // High-Contrast Highway Canvas (Neumorphic map palette)
              Positioned.fill(
                child: CustomPaint(
                  painter: _NavigationRoutePainter(isDark: isDark),
                ),
              ),

              // Top Turn Maneuver Direction Card (Neumorphic)
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Column(
                    children: [
                      NeuCard(
                        padding: const EdgeInsets.all(16),
                        borderRadius: 20,
                        child: Row(
                          children: [
                            // Direction Arrow Icon
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkSurfacePressed : AppColors.lightSurfacePressed,
                                shape: BoxShape.circle,
                                boxShadow: NeuShadows.inset(isDark: isDark),
                              ),
                              child: Icon(
                                maneuver.iconType == 'turn_right'
                                    ? Icons.turn_right_rounded
                                    : (maneuver.iconType == 'roundabout'
                                        ? Icons.roundabout_right_rounded
                                        : (maneuver.iconType == 'destination'
                                            ? Icons.flag_rounded
                                            : Icons.straight_rounded)),
                                color: AppColors.emerald,
                                size: 36,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    maneuver.distanceText,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    maneuver.instructionUz,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Floating Controls (Voice guidance & Center lock)
              Positioned(
                right: 16,
                top: 130,
                child: Column(
                  children: [
                    // Voice Guidance Toggle Button
                    FloatingActionButton.small(
                      heroTag: 'voice_toggle',
                      backgroundColor: state.voiceGuidanceEnabled ? AppColors.primary : Colors.white24,
                      onPressed: () {
                        context.read<NavigationBloc>().add(
                              ToggleVoiceGuidance(!state.voiceGuidanceEnabled),
                            );
                      },
                      child: Icon(
                        state.voiceGuidanceEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // SOS Quick Trigger Button
                    FloatingActionButton.small(
                      heroTag: 'sos_quick',
                      backgroundColor: AppColors.rose,
                      onPressed: () => context.push('/sos'),
                      child: const Icon(Icons.emergency_rounded, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // Bottom Telemetry & Navigation Bar (Neumorphic)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: NeuCard(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    borderRadius: 24,
                    child: SafeArea(
                      top: false,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // ETA Time
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ETA (Kutilayotgan vaqt)',
                                    style: TextStyle(
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                      fontSize: 10,
                                    ),
                                  ),
                                  Text(
                                    '${state.remainingMinutes ~/ 60}h ${state.remainingMinutes % 60}m',
                                    style: TextStyle(
                                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),

                              // Remaining Distance
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    'Qolgan masofa',
                                    style: TextStyle(
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                      fontSize: 10,
                                    ),
                                  ),
                                  Text(
                                    '${state.remainingDistanceKm.toStringAsFixed(1)} km',
                                    style: TextStyle(
                                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),

                              // Current Speed
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Tezlik',
                                    style: TextStyle(
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                      fontSize: 10,
                                    ),
                                  ),
                                  Text(
                                    '${state.currentSpeedKmh.toInt()} km/h',
                                    style: TextStyle(
                                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Route Progress Line
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: (1.0 - (state.remainingDistanceKm / 310.0)).clamp(0.05, 1.0),
                              backgroundColor: isDark ? AppColors.darkSurfacePressed : AppColors.lightSurfacePressed,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isDark ? Colors.white : AppColors.primary,
                              ),
                              minHeight: 6,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Exit / Close Navigation Button
                          NeuButton(
                            text: 'Navigatsiyani Yakunlash',
                            icon: Icons.close_rounded,
                            variant: NeuButtonVariant.secondary,
                            height: 44,
                            onPressed: () {
                              context.read<NavigationBloc>().add(EndNavigation());
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NavigationRoutePainter extends CustomPainter {
  final bool isDark;

  const _NavigationRoutePainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Highway Curve
    final highwayPaint = Paint()
      ..color = isDark ? AppColors.darkSurfacePressed : AppColors.lightSurfacePressed
      ..strokeWidth = 48
      ..style = PaintingStyle.stroke;

    final routeLinePaint = Paint()
      ..color = isDark ? Colors.white : AppColors.primary
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(size.width * 0.5, size.height)
      ..cubicTo(
        size.width * 0.5,
        size.height * 0.6,
        size.width * 0.7,
        size.height * 0.4,
        size.width * 0.4,
        size.height * 0.1,
      );

    canvas.drawPath(path, highwayPaint);
    canvas.drawPath(path, routeLinePaint);

    // Truck Location Marker
    final truckPaint = Paint()
      ..color = isDark ? Colors.white : AppColors.primary;
    canvas.drawCircle(Offset(size.width * 0.52, size.height * 0.75), 12, truckPaint);

    final truckBorder = Paint()
      ..color = isDark ? AppColors.darkBackground : AppColors.lightBackground
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset(size.width * 0.52, size.height * 0.75), 12, truckBorder);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
