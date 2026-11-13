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

  factory LatLngPoint.fromJson(Map<String, dynamic> json) => LatLngPoint(
        latitude: (json['latitude'] as num?)?.toDouble() ?? 41.2995,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 69.2401,
        label: json['label'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        if (label != null) 'label': label,
      };

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

  factory TelemetryUpdate.fromJson(Map<String, dynamic> json) => TelemetryUpdate(
        latitude: (json['latitude'] as num?)?.toDouble() ?? 41.2995,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 69.2401,
        speedKmh: (json['speedKmh'] as num?)?.toDouble() ?? (json['speed_kmh'] as num?)?.toDouble() ?? 0.0,
        headingDegrees: (json['headingDegrees'] as num?)?.toDouble() ?? (json['heading_degrees'] as num?)?.toDouble() ?? 0.0,
        altitudeMeters: (json['altitudeMeters'] as num?)?.toDouble() ?? (json['altitude_meters'] as num?)?.toDouble() ?? 450.0,
        batteryPercent: json['batteryPercent'] as int? ?? json['battery_percent'] as int? ?? 100,
        distanceRemainingKm: (json['distanceRemainingKm'] as num?)?.toDouble() ?? (json['distance_remaining_km'] as num?)?.toDouble() ?? 0.0,
        eta: json['eta'] as String? ?? 'Reys bo\'yicha',
        nextWaypointName: json['nextWaypointName'] as String? ?? json['next_waypoint_name'] as String? ?? 'Manzil',
        timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'speedKmh': speedKmh,
        'headingDegrees': headingDegrees,
        'altitudeMeters': altitudeMeters,
        'batteryPercent': batteryPercent,
        'distanceRemainingKm': distanceRemainingKm,
        'eta': eta,
        'nextWaypointName': nextWaypointName,
        'timestamp': timestamp.toIso8601String(),
      };

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

  factory TrackingDataModel.fromJson(Map<String, dynamic> json) {
    final polyRaw = json['routePolyline'] as List? ?? json['route_polyline'] as List? ?? [];
    return TrackingDataModel(
      shipmentId: json['shipmentId'] as String? ?? json['shipment_id'] as String? ?? '',
      trackingCode: json['trackingCode'] as String? ?? json['tracking_code'] as String? ?? '',
      vehiclePlate: json['vehiclePlate'] as String? ?? json['vehicle_plate'] as String? ?? '',
      driverName: json['driverName'] as String? ?? json['driver_name'] as String? ?? 'Haydovchi',
      driverPhone: json['driverPhone'] as String? ?? json['driver_phone'] as String? ?? '',
      origin: json['origin'] != null
          ? LatLngPoint.fromJson(json['origin'] as Map<String, dynamic>)
          : const LatLngPoint(latitude: 41.2995, longitude: 69.2401, label: 'Toshkent'),
      destination: json['destination'] != null
          ? LatLngPoint.fromJson(json['destination'] as Map<String, dynamic>)
          : const LatLngPoint(latitude: 39.6542, longitude: 66.9597, label: 'Samarqand'),
      routePolyline: polyRaw.map((e) => LatLngPoint.fromJson(e as Map<String, dynamic>)).toList(),
      currentTelemetry: json['currentTelemetry'] != null
          ? TelemetryUpdate.fromJson(json['currentTelemetry'] as Map<String, dynamic>)
          : (json['current_telemetry'] != null
              ? TelemetryUpdate.fromJson(json['current_telemetry'] as Map<String, dynamic>)
              : TelemetryUpdate(
                  latitude: 41.2995,
                  longitude: 69.2401,
                  speedKmh: 0,
                  headingDegrees: 0,
                  altitudeMeters: 450,
                  batteryPercent: 100,
                  distanceRemainingKm: 0,
                  eta: 'Joylashuv kutilmoqda',
                  nextWaypointName: 'Marshrut',
                  timestamp: DateTime.now(),
                )),
    );
  }

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
