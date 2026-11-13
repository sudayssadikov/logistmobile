import 'dart:math';

class DistanceCalculator {
  static const double earthRadiusKm = 6371.0;

  /// Ikki geografik koordinata orasidagi taxminiy masofa (Haversine formulasi)
  static double calculateDistanceKm({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return double.parse((earthRadiusKm * c).toStringAsFixed(1));
  }

  static double _degreesToRadians(double degrees) {
    return degrees * pi / 180.0;
  }
}

