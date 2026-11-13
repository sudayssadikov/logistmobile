import 'package:flutter/widgets.dart';

class GeoPoint {
  final double latitude;
  final double longitude;

  const GeoPoint(this.latitude, this.longitude);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GeoPoint &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;

  @override
  String toString() => 'GeoPoint($latitude, $longitude)';
}

class LocationResult {
  final double lat;
  final double lng;
  final String address;
  final String region;
  final String city;

  const LocationResult({
    required this.lat,
    required this.lng,
    required this.address,
    required this.region,
    required this.city,
  });

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lng': lng,
        'address': address,
        'region': region,
        'city': city,
      };

  factory LocationResult.fromJson(Map<String, dynamic> json) => LocationResult(
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        address: json['address'] as String? ?? '',
        region: json['region'] as String? ?? '',
        city: json['city'] as String? ?? '',
      );

  @override
  String toString() => 'LocationResult($address, $region, $city, $lat, $lng)';
}

class MapSearchResult {
  final String displayName;
  final double lat;
  final double lng;
  final String? region;
  final String? city;

  const MapSearchResult({
    required this.displayName,
    required this.lat,
    required this.lng,
    this.region,
    this.city,
  });
}

abstract class IMapProvider {
  /// Xarita vidjetini qurish (interfeys orqali abstraktsiya)
  Widget buildMap({
    required GeoPoint initialCenter,
    required double initialZoom,
    required ValueChanged<GeoPoint> onPositionChanged,
    ValueChanged<GeoPoint>? onTap,
    required bool isDark,
    Widget? overlayChild,
    Key? key,
  });

  /// Qidiruv so'rovi bo'yicha manzillarni topish
  Future<List<MapSearchResult>> searchAddress(String query);

  /// Koordinatani manzilga aylantirish (Reverse geocoding)
  Future<LocationResult> reverseGeocode(double lat, double lng);

  /// Qurilmaning joriy GPS joylashuvini olish
  Future<GeoPoint?> currentLocation();
}

