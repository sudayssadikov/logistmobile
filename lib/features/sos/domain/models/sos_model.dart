import 'package:equatable/equatable.dart';

enum SosServiceType {
  heavyTowTruck, // TIR Evakuator
  tyreRepair,    // TIR Vulkanizatsiya
  dieselRepair,  // Fura motor / dizel servisi
  fuelDelivery,  // Mobil yoqilg'i yetkazish
  autoElectric;  // Avtoelektrik

  String get key {
    switch (this) {
      case SosServiceType.heavyTowTruck:
        return 'heavy_tow_truck';
      case SosServiceType.tyreRepair:
        return 'tyre_repair';
      case SosServiceType.dieselRepair:
        return 'diesel_repair';
      case SosServiceType.fuelDelivery:
        return 'fuel_delivery';
      case SosServiceType.autoElectric:
        return 'auto_electric';
    }
  }

  static SosServiceType fromKey(String? val) {
    switch (val) {
      case 'heavy_tow_truck':
        return SosServiceType.heavyTowTruck;
      case 'tyre_repair':
        return SosServiceType.tyreRepair;
      case 'diesel_repair':
        return SosServiceType.dieselRepair;
      case 'fuel_delivery':
        return SosServiceType.fuelDelivery;
      case 'auto_electric':
        return SosServiceType.autoElectric;
      default:
        return SosServiceType.heavyTowTruck;
    }
  }
}

class NearbySosProvider extends Equatable {
  final String id;
  final String name;
  final SosServiceType type;
  final String phone;
  final double distanceKm;
  final double rating;
  final String address;
  final bool is24_7;
  final String estimatedArrivalMinutes;

  const NearbySosProvider({
    required this.id,
    required this.name,
    required this.type,
    required this.phone,
    required this.distanceKm,
    required this.rating,
    required this.address,
    this.is24_7 = true,
    required this.estimatedArrivalMinutes,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.key,
        'phone': phone,
        'distanceKm': distanceKm,
        'rating': rating,
        'address': address,
        'is24_7': is24_7,
        'estimatedArrivalMinutes': estimatedArrivalMinutes,
      };

  factory NearbySosProvider.fromJson(Map<String, dynamic> json) => NearbySosProvider(
        id: json['id'] as String? ?? 'SOS-00',
        name: json['name'] as String? ?? 'SOS Servis',
        type: SosServiceType.fromKey(json['type'] as String?),
        phone: json['phone'] as String? ?? '',
        distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
        rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
        address: json['address'] as String? ?? '',
        is24_7: json['is24_7'] as bool? ?? true,
        estimatedArrivalMinutes: json['estimatedArrivalMinutes'] as String? ?? '15 min',
      );

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        phone,
        distanceKm,
        rating,
        address,
        is24_7,
        estimatedArrivalMinutes,
      ];
}
