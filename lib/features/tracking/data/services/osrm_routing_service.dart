import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';
import '../../domain/models/tracking_data_model.dart';

class OsrmRoutingService {
  final Dio _dio;

  OsrmRoutingService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
              ),
            );

  /// Fetches true road geometry via free OSRM public API (Zero API keys needed)
  Future<List<LatLng>> fetchRoadRoute({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    try {
      final url =
          'https://router.project-osrm.org/route/v1/driving/$originLng,$originLat;$destLng,$destLat?overview=full&geometries=geojson';

      final response = await _dio.get(url);

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final routes = data['routes'] as List<dynamic>?;

        if (routes != null && routes.isNotEmpty) {
          final firstRoute = routes[0] as Map<String, dynamic>;
          final geometry = firstRoute['geometry'] as Map<String, dynamic>?;
          final coordinates = geometry?['coordinates'] as List<dynamic>?;

          if (coordinates != null) {
            return coordinates.map((coord) {
              final pair = coord as List<dynamic>;
              final lng = (pair[0] as num).toDouble();
              final lat = (pair[1] as num).toDouble();
              return LatLng(lat, lng);
            }).toList();
          }
        }
      }
    } catch (_) {
      // Fallback to direct interpolation if public OSM server is rate-limited or offline
    }

    // Fallback interpolated road points
    return [
      LatLng(originLat, originLng),
      LatLng((originLat * 2 + destLat) / 3, (originLng * 2 + destLng) / 3),
      LatLng((originLat + destLat * 2) / 3, (originLng + destLng * 2) / 3),
      LatLng(destLat, destLng),
    ];
  }

  /// Helper converting LatLngPoint list to LatLng list
  List<LatLng> convertPoints(List<LatLngPoint> points) {
    return points.map((p) => LatLng(p.latitude, p.longitude)).toList();
  }
}
