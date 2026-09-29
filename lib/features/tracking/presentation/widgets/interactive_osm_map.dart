import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../app/theme/app_colors.dart';
import '../../data/services/device_location_service.dart';
import '../../data/services/osrm_routing_service.dart';
import '../../domain/models/tracking_data_model.dart';

class InteractiveOsmMap extends StatefulWidget {
  final List<LatLngPoint> route;
  final TelemetryUpdate telemetry;
  final LatLngPoint origin;
  final LatLngPoint destination;

  const InteractiveOsmMap({
    super.key,
    required this.route,
    required this.telemetry,
    required this.origin,
    required this.destination,
  });

  @override
  State<InteractiveOsmMap> createState() => _InteractiveOsmMapState();
}

class _InteractiveOsmMapState extends State<InteractiveOsmMap> {
  final MapController _mapController = MapController();
  final OsrmRoutingService _routingService = OsrmRoutingService();
  final DeviceLocationService _locationService = DeviceLocationService();
  
  List<LatLng> _osrmRoutePoints = [];
  bool _isLoadingRoute = false;
  bool _isLocatingUser = false;
  bool _autoFollow = true;
  LatLng? _deviceUserLocation;

  @override
  void initState() {
    super.initState();
    _fetchRoadGeometry();
  }

  @override
  void didUpdateWidget(covariant InteractiveOsmMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.origin != widget.origin || oldWidget.destination != widget.destination) {
      _fetchRoadGeometry();
    }

    // Auto-follow truck if enabled
    if (_autoFollow && (oldWidget.telemetry.latitude != widget.telemetry.latitude ||
        oldWidget.telemetry.longitude != widget.telemetry.longitude)) {
      final truckLatLng = LatLng(widget.telemetry.latitude, widget.telemetry.longitude);
      try {
        _mapController.move(truckLatLng, _mapController.camera.zoom);
      } catch (_) {}
    }
  }

  Future<void> _fetchRoadGeometry() async {
    setState(() => _isLoadingRoute = true);

    final points = await _routingService.fetchRoadRoute(
      originLat: widget.origin.latitude,
      originLng: widget.origin.longitude,
      destLat: widget.destination.latitude,
      destLng: widget.destination.longitude,
    );

    if (mounted) {
      setState(() {
        _osrmRoutePoints = points;
        _isLoadingRoute = false;
      });
    }
  }

  Future<void> _locateDeviceUser() async {
    setState(() => _isLocatingUser = true);
    
    try {
      final position = await _locationService.getCurrentPosition();
      if (position != null && mounted) {
        final userLatLng = LatLng(position.latitude, position.longitude);
        setState(() {
          _deviceUserLocation = userLatLng;
          _autoFollow = false;
          _isLocatingUser = false;
        });
        _mapController.move(userLatLng, 15.0);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Qurilma GPS joylashuvi aniqlandi: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}'),
            backgroundColor: AppColors.emerald,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (mounted) {
        setState(() => _isLocatingUser = false);
        final truckLatLng = LatLng(widget.telemetry.latitude, widget.telemetry.longitude);
        _mapController.move(truckLatLng, 13.0);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Brauzer / Qurilma GPS ruxsati berilmadi. Yuk joylashuvi ko\'rsatilmoqda.'),
            backgroundColor: AppColors.amber,
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLocatingUser = false);
        final truckLatLng = LatLng(widget.telemetry.latitude, widget.telemetry.longitude);
        _mapController.move(truckLatLng, 13.0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final truckLatLng = LatLng(widget.telemetry.latitude, widget.telemetry.longitude);
    final originLatLng = LatLng(widget.origin.latitude, widget.origin.longitude);
    final destLatLng = LatLng(widget.destination.latitude, widget.destination.longitude);

    final routeToDraw = _osrmRoutePoints.isNotEmpty
        ? _osrmRoutePoints
        : _routingService.convertPoints(widget.route);

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: truckLatLng,
            initialZoom: 7.5,
            minZoom: 4,
            maxZoom: 18,
            onPositionChanged: (pos, hasGesture) {
              if (hasGesture && _autoFollow) {
                setState(() => _autoFollow = false);
              }
            },
          ),
          children: [
            // OpenStreetMap Free Tile Layer
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'uz.logiflow.mobile',
              maxZoom: 19,
            ),

            // Route Polyline Layer
            if (routeToDraw.isNotEmpty)
              PolylineLayer(
                polylines: [
                  // Outline / Glow
                  Polyline(
                    points: routeToDraw,
                    strokeWidth: 7.0,
                    color: AppColors.primary.withValues(alpha: 0.4),
                  ),
                  // Core Route
                  Polyline(
                    points: routeToDraw,
                    strokeWidth: 4.5,
                    color: AppColors.primary,
                  ),
                ],
              ),

            // Origin, Destination, Live Vehicle & Device User Markers Layer
            MarkerLayer(
              markers: [
                // Origin Warehouse Pin
                Marker(
                  point: originLatLng,
                  width: 40,
                  height: 40,
                  child: _buildLocationPin(
                    color: AppColors.emerald,
                    icon: Icons.inventory_2_rounded,
                    label: widget.origin.label ?? 'A',
                  ),
                ),

                // Destination Terminal Pin
                Marker(
                  point: destLatLng,
                  width: 40,
                  height: 40,
                  child: _buildLocationPin(
                    color: AppColors.rose,
                    icon: Icons.flag_rounded,
                    label: widget.destination.label ?? 'B',
                  ),
                ),

                // Real Device User Location Pin if available
                if (_deviceUserLocation != null)
                  Marker(
                    point: _deviceUserLocation!,
                    width: 44,
                    height: 44,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue.withValues(alpha: 0.25),
                      ),
                      child: Center(
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blueAccent,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blueAccent.withValues(alpha: 0.6),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // Moving Truck with Live Heading Rotation
                Marker(
                  point: truckLatLng,
                  width: 52,
                  height: 52,
                  child: Transform.rotate(
                    angle: (widget.telemetry.headingDegrees * (math.pi / 180.0)),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.5),
                            blurRadius: 16,
                            spreadRadius: 3,
                          ),
                        ],
                        border: Border.all(color: Colors.white, width: 2.5),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.navigation_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),

        // Quick Recenter Map FABs
        Positioned(
          right: 16,
          bottom: 220,
          child: Column(
            children: [
              // Real Device GPS Finder
              FloatingActionButton.small(
                heroTag: 'my_real_gps',
                backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
                foregroundColor: AppColors.emerald,
                tooltip: 'Mening jonli GPS joylashuvim',
                onPressed: _locateDeviceUser,
                child: _isLocatingUser
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.emerald),
                      )
                    : const Icon(Icons.my_location_rounded, size: 20),
              ),
              const SizedBox(height: 8),

              // Auto-Follow / Center Truck FAB
              FloatingActionButton.small(
                heroTag: 'recenter_truck',
                backgroundColor: _autoFollow ? AppColors.primary : (isDark ? AppColors.darkSurface : Colors.white),
                foregroundColor: _autoFollow ? Colors.white : AppColors.primary,
                tooltip: _autoFollow ? 'Kuzatuv faol' : 'Yukni markazlashtirish',
                onPressed: () {
                  setState(() => _autoFollow = true);
                  _mapController.move(truckLatLng, 12.0);
                },
                child: const Icon(Icons.directions_car_rounded, size: 20),
              ),
              const SizedBox(height: 8),

              // Full Route Zoom FAB
              FloatingActionButton.small(
                heroTag: 'zoom_route',
                backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
                foregroundColor: AppColors.primary,
                tooltip: 'Butun marshrut',
                onPressed: () {
                  setState(() => _autoFollow = false);
                  _mapController.move(truckLatLng, 7.5);
                },
                child: const Icon(Icons.alt_route_rounded, size: 20),
              ),
            ],
          ),
        ),

        // Route calculation indicator
        if (_isLoadingRoute)
          Positioned(
            top: 70,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.darkSurface : Colors.white).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('OSRM Highway Routing...', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLocationPin({required Color color, required IconData icon, required String label}) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}
