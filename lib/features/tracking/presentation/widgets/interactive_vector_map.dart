import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../domain/models/tracking_data_model.dart';

class InteractiveVectorMap extends StatefulWidget {
  final List<LatLngPoint> route;
  final TelemetryUpdate telemetry;
  final LatLngPoint origin;
  final LatLngPoint destination;

  const InteractiveVectorMap({
    super.key,
    required this.route,
    required this.telemetry,
    required this.origin,
    required this.destination,
  });

  @override
  State<InteractiveVectorMap> createState() => _InteractiveVectorMapState();
}

class _InteractiveVectorMapState extends State<InteractiveVectorMap> {
  final TransformationController _transformController = TransformationController();

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? const Color(0xFF0C0E17) : const Color(0xFFE2E8F0),
      child: Stack(
        children: [
          // Interactive Pan & Zoom Map Canvas
          InteractiveViewer(
            transformationController: _transformController,
            boundaryMargin: const EdgeInsets.all(200),
            minScale: 0.6,
            maxScale: 3.5,
            child: SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: CustomPaint(
                painter: _MapCanvasPainter(
                  route: widget.route,
                  telemetry: widget.telemetry,
                  origin: widget.origin,
                  destination: widget.destination,
                  isDark: isDark,
                ),
              ),
            ),
          ),

          // Map Control Overlays (Recenter, Zoom In, Zoom Out)
          Positioned(
            right: 16,
            top: 70,
            child: Column(
              children: [
                _MapControlButton(
                  icon: Icons.my_location_rounded,
                  tooltip: 'Recenter Truck',
                  onTap: () {
                    _transformController.value = Matrix4.identity();
                  },
                ),
                const SizedBox(height: 8),
                _MapControlButton(
                  icon: Icons.add_rounded,
                  tooltip: 'Zoom In',
                  onTap: () {
                    _transformController.value = _transformController.value.scaledByDouble(1.25, 1.25, 1.0, 1.0);
                  },
                ),
                const SizedBox(height: 8),
                _MapControlButton(
                  icon: Icons.remove_rounded,
                  tooltip: 'Zoom Out',
                  onTap: () {
                    _transformController.value = _transformController.value.scaledByDouble(0.8, 0.8, 1.0, 1.0);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapControlButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _MapControlButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? AppColors.darkSurface.withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.9),
      shape: const CircleBorder(),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(
            icon,
            size: 20,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
      ),
    );
  }
}

class _MapCanvasPainter extends CustomPainter {
  final List<LatLngPoint> route;
  final TelemetryUpdate telemetry;
  final LatLngPoint origin;
  final LatLngPoint destination;
  final bool isDark;

  _MapCanvasPainter({
    required this.route,
    required this.telemetry,
    required this.origin,
    required this.destination,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw subtle background coordinate grid
    final gridPaint = Paint()
      ..color = (isDark ? const Color(0xFF161926) : const Color(0xFFCBD5E1))
      ..strokeWidth = 0.8;

    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (route.isEmpty) return;

    // Normalize route coordinates into canvas pixel points
    final minLat = route.map((e) => e.latitude).reduce(math.min);
    final maxLat = route.map((e) => e.latitude).reduce(math.max);
    final minLng = route.map((e) => e.longitude).reduce(math.min);
    final maxLng = route.map((e) => e.longitude).reduce(math.max);

    final latRange = (maxLat - minLat).clamp(0.001, 10.0);
    final lngRange = (maxLng - minLng).clamp(0.001, 10.0);

    const padding = 60.0;
    final drawWidth = size.width - (padding * 2);
    final drawHeight = size.height - (padding * 2);

    Offset toPixel(double lat, double lng) {
      final x = padding + ((lng - minLng) / lngRange) * drawWidth;
      final y = padding + ((maxLat - lat) / latRange) * drawHeight;
      return Offset(x, y);
    }

    final points = route.map((p) => toPixel(p.latitude, p.longitude)).toList();

    // 2. Draw Highway Route Polyline with Neon Glow
    final glowPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.35)
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final linePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, linePaint);

    // 3. Draw Waypoint Nodes
    for (final pt in points) {
      canvas.drawCircle(pt, 4.0, Paint()..color = isDark ? AppColors.darkBackground : Colors.white);
      canvas.drawCircle(pt, 2.5, Paint()..color = AppColors.primary);
    }

    // 4. Draw Origin Pin (Green)
    final originPt = toPixel(origin.latitude, origin.longitude);
    canvas.drawCircle(originPt, 10.0, Paint()..color = AppColors.emerald.withValues(alpha: 0.25));
    canvas.drawCircle(originPt, 6.0, Paint()..color = AppColors.emerald);

    // 5. Draw Destination Pin (Cyan)
    final destPt = toPixel(destination.latitude, destination.longitude);
    canvas.drawCircle(destPt, 10.0, Paint()..color = AppColors.cyan.withValues(alpha: 0.25));
    canvas.drawCircle(destPt, 6.0, Paint()..color = AppColors.cyan);

    // 6. Draw Moving Vehicle Marker with Live Heading Indicator
    final vehiclePt = toPixel(telemetry.latitude, telemetry.longitude);

    // Outer pulsating halo
    canvas.drawCircle(
      vehiclePt,
      20.0,
      Paint()..color = AppColors.primary.withValues(alpha: 0.2),
    );
    canvas.drawCircle(
      vehiclePt,
      12.0,
      Paint()..color = AppColors.primary,
    );
    canvas.drawCircle(
      vehiclePt,
      5.0,
      Paint()..color = Colors.white,
    );

    // Heading Arrow
    final headingRad = (telemetry.headingDegrees - 90) * (math.pi / 180.0);
    final arrowTip = Offset(
      vehiclePt.dx + math.cos(headingRad) * 16.0,
      vehiclePt.dy + math.sin(headingRad) * 16.0,
    );

    canvas.drawLine(
      vehiclePt,
      arrowTip,
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _MapCanvasPainter oldDelegate) {
    return oldDelegate.telemetry != telemetry || oldDelegate.isDark != isDark;
  }
}
