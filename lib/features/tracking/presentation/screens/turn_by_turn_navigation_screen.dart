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
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Slate 900
      body: BlocConsumer<NavigationBloc, NavigationState>(
        listener: (context, state) {
          if (state.spokenAlert != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.volume_up_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text('🔊 "${state.spokenAlert}"')),
                  ],
                ),
                backgroundColor: AppColors.primary,
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
              // Simulated High-Contrast Night Highway Canvas
              Positioned.fill(
                child: CustomPaint(
                  painter: _NavigationRoutePainter(),
                ),
              ),

              // Top Turn Maneuver Direction Card
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B).withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white24, width: 1.2),
                          boxShadow: const [
                            BoxShadow(color: Colors.black54, blurRadius: 16, offset: Offset(0, 4)),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Direction Arrow Icon
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: AppColors.emerald.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(14),
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

              // Bottom Telemetry & Navigation Bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E293B),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(color: Colors.black54, blurRadius: 16),
                    ],
                  ),
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
                                const Text('ETA (Kutilayotgan vaqt)', style: TextStyle(color: Colors.white60, fontSize: 10)),
                                Text(
                                  '${state.remainingMinutes ~/ 60}h ${state.remainingMinutes % 60}m',
                                  style: const TextStyle(
                                    color: Colors.white,
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
                                const Text('Qolgan masofa', style: TextStyle(color: Colors.white60, fontSize: 10)),
                                Text(
                                  '${state.remainingDistanceKm.toStringAsFixed(1)} km',
                                  style: const TextStyle(
                                    color: AppColors.cyan,
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
                                const Text('Tezlik', style: TextStyle(color: Colors.white60, fontSize: 10)),
                                Text(
                                  '${state.currentSpeedKmh.toInt()} km/h',
                                  style: const TextStyle(
                                    color: AppColors.emerald,
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
                            backgroundColor: Colors.white12,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.emerald),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Exit / Close Navigation Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                            label: const Text('Navigatsiyani Yakunlash', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white12,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              context.read<NavigationBloc>().add(EndNavigation());
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      ],
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
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFF0B1120);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Highway Curve
    final highwayPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = 48
      ..style = PaintingStyle.stroke;

    final routeGlowPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.4)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke;

    final routeLinePaint = Paint()
      ..color = AppColors.cyan
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
    canvas.drawPath(path, routeGlowPaint);
    canvas.drawPath(path, routeLinePaint);

    // Truck Location Marker
    final truckPaint = Paint()..color = AppColors.emerald;
    canvas.drawCircle(Offset(size.width * 0.52, size.height * 0.75), 14, truckPaint);

    final truckBorder = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset(size.width * 0.52, size.height * 0.75), 14, truckBorder);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
