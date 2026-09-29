import 'package:equatable/equatable.dart';
import 'shipment_model.dart';

class DriverPreferences extends Equatable {
  final String currentCity;
  final double maxRadiusKm;
  final String truckType;
  final double maxWeightTons;
  final double minRatePerKm;
  final bool hasRefrigeration;

  const DriverPreferences({
    this.currentCity = 'Toshkent',
    this.maxRadiusKm = 50.0,
    this.truckType = 'Refrigerated',
    this.maxWeightTons = 24.0,
    this.minRatePerKm = 14000.0,
    this.hasRefrigeration = true,
  });

  DriverPreferences copyWith({
    String? currentCity,
    double? maxRadiusKm,
    String? truckType,
    double? maxWeightTons,
    double? minRatePerKm,
    bool? hasRefrigeration,
  }) {
    return DriverPreferences(
      currentCity: currentCity ?? this.currentCity,
      maxRadiusKm: maxRadiusKm ?? this.maxRadiusKm,
      truckType: truckType ?? this.truckType,
      maxWeightTons: maxWeightTons ?? this.maxWeightTons,
      minRatePerKm: minRatePerKm ?? this.minRatePerKm,
      hasRefrigeration: hasRefrigeration ?? this.hasRefrigeration,
    );
  }

  @override
  List<Object?> get props => [
        currentCity,
        maxRadiusKm,
        truckType,
        maxWeightTons,
        minRatePerKm,
        hasRefrigeration,
      ];
}

class MatchedShipment extends Equatable {
  final ShipmentModel shipment;
  final int matchPercentage; // e.g. 98%
  final double distanceFromDriverKm;
  final String aiReason;
  final bool isReturnTrip;

  const MatchedShipment({
    required this.shipment,
    required this.matchPercentage,
    required this.distanceFromDriverKm,
    required this.aiReason,
    this.isReturnTrip = false,
  });

  @override
  List<Object?> get props => [
        shipment,
        matchPercentage,
        distanceFromDriverKm,
        aiReason,
        isReturnTrip,
      ];
}
