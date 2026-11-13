import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'map_provider.dart';
import 'uzbekistan_regions.dart';

class OsmMapProvider implements IMapProvider {
  final Dio _dio;
  DateTime _lastRequestTime = DateTime.fromMillisecondsSinceEpoch(0);

  OsmMapProvider({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                headers: {
                  'User-Agent': 'LogiFlow-Logistics-Platform/1.0 (contact: info@logiflow.uz)',
                  'Accept-Language': 'uz,ru,en',
                },
                connectTimeout: const Duration(seconds: 6),
                receiveTimeout: const Duration(seconds: 6),
              ),
            );

  Future<void> _rateLimit() async {
    final now = DateTime.now();
    final elapsed = now.difference(_lastRequestTime);
    if (elapsed.inMilliseconds < 1000) {
      await Future.delayed(Duration(milliseconds: 1000 - elapsed.inMilliseconds));
    }
    _lastRequestTime = DateTime.now();
  }

  @override
  Widget buildMap({
    required GeoPoint initialCenter,
    required double initialZoom,
    required ValueChanged<GeoPoint> onPositionChanged,
    ValueChanged<GeoPoint>? onTap,
    required bool isDark,
    Widget? overlayChild,
    Key? key,
  }) {
    return _OsmMapWidget(
      key: key,
      initialCenter: initialCenter,
      initialZoom: initialZoom,
      onPositionChanged: onPositionChanged,
      onTap: onTap,
      isDark: isDark,
      overlayChild: overlayChild,
    );
  }

  @override
  Future<List<MapSearchResult>> searchAddress(String query) async {
    if (query.trim().length < 2) return [];
    await _rateLimit();

    try {
      final response = await _dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': query.trim(),
          'format': 'json',
          'addressdetails': 1,
          'limit': 6,
          'countrycodes': 'uz', // O'zbekiston chegarasida qidirish
        },
      );

      if (response.statusCode == 200 && response.data is List) {
        final list = response.data as List;
        return list.map((item) {
          final lat = double.tryParse(item['lat']?.toString() ?? '') ?? 0.0;
          final lon = double.tryParse(item['lon']?.toString() ?? '') ?? 0.0;
          final displayName = item['display_name'] as String? ?? '';
          final addr = item['address'] as Map<String, dynamic>? ?? {};

          final state = addr['state'] as String? ?? addr['county'] as String?;
          final city = addr['city'] as String? ?? addr['town'] as String? ?? addr['district'] as String? ?? '';

          return MapSearchResult(
            displayName: displayName,
            lat: lat,
            lng: lon,
            region: UzbekistanRegions.normalizeRegion(state),
            city: city.isNotEmpty ? city : 'Shahar',
          );
        }).toList();
      }
    } catch (_) {
      // Offline fallback yoki tarmoq xatosi
    }
    return [];
  }

  @override
  Future<LocationResult> reverseGeocode(double lat, double lng) async {
    await _rateLimit();

    try {
      final response = await _dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'lat': lat,
          'lon': lng,
          'format': 'json',
          'addressdetails': 1,
        },
      );

      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        final displayName = data['display_name'] as String? ?? '';
        final addr = data['address'] as Map<String, dynamic>? ?? {};

        final stateRaw = addr['state'] as String? ?? addr['region'] as String? ?? addr['county'] as String?;
        final cityRaw = addr['city'] as String? ??
            addr['town'] as String? ??
            addr['district'] as String? ??
            addr['village'] as String? ??
            addr['suburb'] as String? ??
            'Shahar/Tuman';

        final normalizedRegion = UzbekistanRegions.normalizeRegion(stateRaw);

        // Qisqartirilgan aniq manzil (ko'cha, uy yoki qisqa manzil)
        final road = addr['road'] as String?;
        final house = addr['house_number'] as String?;
        String shortAddress;
        if (road != null && road.isNotEmpty) {
          shortAddress = house != null ? '$road, $house' : road;
        } else {
          final parts = displayName.split(',');
          shortAddress = parts.take(3).join(', ').trim();
        }

        return LocationResult(
          lat: lat,
          lng: lng,
          address: shortAddress.isNotEmpty ? shortAddress : displayName,
          region: normalizedRegion,
          city: cityRaw,
        );
      }
    } catch (_) {
      // Tarmoq xatosi bo'lsa fallback
    }

    return LocationResult(
      lat: lat,
      lng: lng,
      address: 'Tanlangan koordinata: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
      region: UzbekistanRegions.toshkentShahar,
      city: 'Toshkent',
    );
  }

  @override
  Future<GeoPoint?> currentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 5),
      );

      return GeoPoint(position.latitude, position.longitude);
    } catch (_) {
      return null;
    }
  }
}

class _OsmMapWidget extends StatefulWidget {
  final GeoPoint initialCenter;
  final double initialZoom;
  final ValueChanged<GeoPoint> onPositionChanged;
  final ValueChanged<GeoPoint>? onTap;
  final bool isDark;
  final Widget? overlayChild;

  const _OsmMapWidget({
    super.key,
    required this.initialCenter,
    required this.initialZoom,
    required this.onPositionChanged,
    this.onTap,
    required this.isDark,
    this.overlayChild,
  });

  @override
  State<_OsmMapWidget> createState() => _OsmMapWidgetState();
}

class _OsmMapWidgetState extends State<_OsmMapWidget> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // OpenStreetMap tile URLs
    final tileUrl = widget.isDark
        ? 'https://cartodb-basemaps-a.global.ssl.fastly.net/dark_all/{z}/{x}/{y}.png'
        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: ll.LatLng(widget.initialCenter.latitude, widget.initialCenter.longitude),
            initialZoom: widget.initialZoom,
            minZoom: 4,
            maxZoom: 18,
            onPositionChanged: (position, hasGesture) {
              if (position.center != null) {
                widget.onPositionChanged(
                  GeoPoint(position.center!.latitude, position.center!.longitude),
                );
              }
            },
            onTap: (_, point) {
              if (widget.onTap != null) {
                widget.onTap!(GeoPoint(point.latitude, point.longitude));
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: tileUrl,
              userAgentPackageName: 'uz.logiflow.app',
            ),
          ],
        ),
        if (widget.overlayChild != null) widget.overlayChild!,
      ],
    );
  }
}

