import 'dart:async';
import '../../../../core/network/api_result.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/models/tracking_data_model.dart';
import '../../domain/repositories/tracking_repository.dart';

class TrackingRepositoryImpl implements ITrackingRepository {
  final DioClient? _dioClient;
  Timer? _telemetryTimer;
  StreamController<TelemetryUpdate>? _streamController;
  int _currentWaypointIndex = 0;

  // Tashkent -> Yangiyul -> Chinaz -> Gulistan -> Jizzakh -> Bulungur -> Samarkand
  final List<LatLngPoint> _route = const [
    LatLngPoint(latitude: 41.2214, longitude: 69.2198, label: 'Tashkent (Sergeli Hub)'),
    LatLngPoint(latitude: 41.1158, longitude: 69.0494, label: 'Yangiyul Highway Checkpoint'),
    LatLngPoint(latitude: 40.8719, longitude: 68.7561, label: 'Chinaz Syrdarya River Bridge'),
    LatLngPoint(latitude: 40.5017, longitude: 68.7844, label: 'Gulistan Junction (M39)'),
    LatLngPoint(latitude: 40.1250, longitude: 67.8422, label: 'Jizzakh Pass Toll Station'),
    LatLngPoint(latitude: 39.8144, longitude: 67.2711, label: 'Bulungur Oasis Entry'),
    LatLngPoint(latitude: 39.6542, longitude: 66.9597, label: 'Samarkand Logistics Park'),
  ];

  TrackingRepositoryImpl([this._dioClient]);

  @override
  Future<ApiResult<TrackingDataModel>> getTrackingSession(String shipmentId) async {
    if (_dioClient != null) {
      try {
        final response = await _dioClient!.get('/tracking/$shipmentId');
        if (response.statusCode == 200 && response.data != null) {
          // Parse telemetry
        }
      } catch (_) {
        // Fallback
      }
    }

    await Future.delayed(const Duration(milliseconds: 150));
    final initial = TrackingDataModel(
      shipmentId: shipmentId,
      trackingCode: 'LF-UZ-8921',
      vehiclePlate: '01 842 TAA',
      driverName: 'Rustam Karimov',
      driverPhone: '+998 97 765 43 21',
      origin: _route.first,
      destination: _route.last,
      routePolyline: _route,
      currentTelemetry: TelemetryUpdate(
        latitude: _route[2].latitude,
        longitude: _route[2].longitude,
        speedKmh: 78.4,
        headingDegrees: 224.0,
        altitudeMeters: 312.0,
        batteryPercent: 94,
        distanceRemainingKm: 138.0,
        eta: '2h 15m',
        nextWaypointName: _route[3].label ?? 'Gulistan Junction',
        timestamp: DateTime.now(),
      ),
    );
    return ApiSuccess(initial);
  }

  @override
  Stream<TelemetryUpdate> startTelemetrySimulation(String shipmentId) {
    _stop();
    _streamController = StreamController<TelemetryUpdate>.broadcast();
    _currentWaypointIndex = 2;

    _telemetryTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_streamController == null || _streamController!.isClosed) {
        timer.cancel();
        return;
      }

      _currentWaypointIndex = (_currentWaypointIndex + 1) % _route.length;
      final pt = _route[_currentWaypointIndex];
      final speed = 70.0 + (_currentWaypointIndex % 3) * 6.5;
      final heading = 210.0 + (_currentWaypointIndex * 4.0);
      final remainingKm = (310.0 * (1 - (_currentWaypointIndex / _route.length))).clamp(10.0, 310.0);
      final minutesLeft = (remainingKm / (speed / 60)).round();

      final update = TelemetryUpdate(
        latitude: pt.latitude,
        longitude: pt.longitude,
        speedKmh: speed,
        headingDegrees: heading,
        altitudeMeters: 320.0 + (_currentWaypointIndex * 15),
        batteryPercent: 92,
        distanceRemainingKm: remainingKm,
        eta: '${minutesLeft ~/ 60}h ${minutesLeft % 60}m',
        nextWaypointName: _route[(_currentWaypointIndex + 1) % _route.length].label ?? 'Next Hub',
        timestamp: DateTime.now(),
      );

      _streamController?.add(update);
    });

    return _streamController!.stream;
  }

  void _stop() {
    _telemetryTimer?.cancel();
    _telemetryTimer = null;
    _streamController?.close();
    _streamController = null;
  }

  @override
  void stopTelemetrySimulation() {
    _stop();
  }
}
