import 'package:equatable/equatable.dart';

class LatLngPoint extends Equatable {
  final double latitude;
  final double longitude;
  final String? label;

  const LatLngPoint({
    required this.latitude,
    required this.longitude,
    this.label,
  });

  @override
  List<Object?> get props => [latitude, longitude, label];
}

class TelemetryUpdate extends Equatable {
  final double latitude;
  final double longitude;
  final double speedKmh;
  final double headingDegrees;
  final double altitudeMeters;
  final int batteryPercent;
  final double distanceRemainingKm;
  final String eta;
  final String nextWaypointName;
  final DateTime timestamp;

  const TelemetryUpdate({
    required this.latitude,
    required this.longitude,
    required this.speedKmh,
    required this.headingDegrees,
    required this.altitudeMeters,
    required this.batteryPercent,
    required this.distanceRemainingKm,
    required this.eta,
    required this.nextWaypointName,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [
        latitude,
        longitude,
        speedKmh,
        headingDegrees,
        altitudeMeters,
        batteryPercent,
        distanceRemainingKm,
        eta,
        nextWaypointName,
        timestamp,
      ];
}

class TrackingDataModel extends Equatable {
  final String shipmentId;
  final String trackingCode;
  final String vehiclePlate;
  final String driverName;
  final String driverPhone;
  final LatLngPoint origin;
  final LatLngPoint destination;
  final List<LatLngPoint> routePolyline;
  final TelemetryUpdate currentTelemetry;

  const TrackingDataModel({
    required this.shipmentId,
    required this.trackingCode,
    required this.vehiclePlate,
    required this.driverName,
    required this.driverPhone,
    required this.origin,
    required this.destination,
    required this.routePolyline,
    required this.currentTelemetry,
  });

  TrackingDataModel copyWith({
    String? shipmentId,
    String? trackingCode,
    String? vehiclePlate,
    String? driverName,
    String? driverPhone,
    LatLngPoint? origin,
    LatLngPoint? destination,
    List<LatLngPoint>? routePolyline,
    TelemetryUpdate? currentTelemetry,
  }) {
    return TrackingDataModel(
      shipmentId: shipmentId ?? this.shipmentId,
      trackingCode: trackingCode ?? this.trackingCode,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      routePolyline: routePolyline ?? this.routePolyline,
      currentTelemetry: currentTelemetry ?? this.currentTelemetry,
    );
  }

  @override
  List<Object?> get props => [
        shipmentId,
        trackingCode,
        vehiclePlate,
        driverName,
        driverPhone,
        origin,
        destination,
        routePolyline,
        currentTelemetry,
      ];
}
