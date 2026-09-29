import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../../domain/models/tracking_data_model.dart';

class DeviceLocationService {
  StreamSubscription<Position>? _positionStreamSub;
  final _telemetryStreamController = StreamController<TelemetryUpdate>.broadcast();

  Stream<TelemetryUpdate> get telemetryStream => _telemetryStreamController.stream;

  Future<bool> checkAndRequestPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await checkAndRequestPermission();
      if (!hasPermission) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (_) {
      return null;
    }
  }

  void startLiveStreaming({
    required double destLat,
    required double destLng,
  }) {
    stopStreaming();

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 10, // Update every 10 meters
    );

    _positionStreamSub = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) {
        final distanceRemainingMeters = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          destLat,
          destLng,
        );

        final distanceRemainingKm = distanceRemainingMeters / 1000.0;
        final speedKmh = position.speed * 3.6; // convert m/s to km/h
        final etaMinutes = speedKmh > 5 ? (distanceRemainingKm / speedKmh * 60).round() : 120;
        final etaHours = etaMinutes ~/ 60;
        final etaMins = etaMinutes % 60;
        final etaString = etaHours > 0 ? '${etaHours}h ${etaMins}m' : '${etaMins}m';

        final update = TelemetryUpdate(
          latitude: position.latitude,
          longitude: position.longitude,
          speedKmh: speedKmh > 0 ? speedKmh : 0.0,
          headingDegrees: position.heading,
          altitudeMeters: position.altitude,
          batteryPercent: 92,
          distanceRemainingKm: distanceRemainingKm,
          eta: etaString,
          nextWaypointName: 'Highway M39 Corridor',
          timestamp: DateTime.now(),
        );

        _telemetryStreamController.add(update);
      },
      onError: (_) {},
    );
  }

  void stopStreaming() {
    _positionStreamSub?.cancel();
    _positionStreamSub = null;
  }

  void dispose() {
    stopStreaming();
    _telemetryStreamController.close();
  }
}
