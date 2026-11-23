class DriverVehicleModel {
  final String id;
  final String driverId;
  final String truckType;
  final double capacityTons;
  final String? plateNumber;
  final bool isPrimary;
  final DateTime? createdAt;

  const DriverVehicleModel({
    required this.id,
    required this.driverId,
    required this.truckType,
    required this.capacityTons,
    this.plateNumber,
    this.isPrimary = true,
    this.createdAt,
  });

  factory DriverVehicleModel.fromJson(Map<String, dynamic> json) {
    return DriverVehicleModel(
      id: json['id'] as String? ?? '',
      driverId: json['driver_id'] as String? ?? '',
      truckType: json['truck_type'] as String? ?? 'TENT',
      capacityTons: (json['capacity_tons'] as num?)?.toDouble() ?? 0.0,
      plateNumber: json['plate_number'] as String?,
      isPrimary: json['is_primary'] as bool? ?? true,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'truck_type': truckType,
      'capacity_tons': capacityTons,
      'plate_number': plateNumber,
      'is_primary': isPrimary,
    };
  }
}

