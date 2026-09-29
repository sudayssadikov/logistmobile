import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum TruckBodyType {
  tent(labelKey: 'fleet.tent', icon: Icons.rv_hookup_rounded),
  refrigerated(labelKey: 'fleet.refrigerated', icon: Icons.ac_unit_rounded),
  isothermal(labelKey: 'fleet.isothermal', icon: Icons.severe_cold_rounded),
  fura(labelKey: 'fleet.fura', icon: Icons.local_shipping_rounded),
  mega(labelKey: 'fleet.mega', icon: Icons.view_compact_rounded),
  flatbed(labelKey: 'fleet.flatbed', icon: Icons.horizontal_distribute_rounded);

  final String labelKey;
  final IconData icon;

  const TruckBodyType({
    required this.labelKey,
    required this.icon,
  });
}

class TruckModel extends Equatable {
  final String id;
  final String plateNumber;
  final String model;
  final TruckBodyType bodyType;
  final double maxWeightTons;
  final double maxVolumeM3;
  final String? assignedDriverId;
  final String? assignedDriverName;
  final bool isAvailable;

  const TruckModel({
    required this.id,
    required this.plateNumber,
    required this.model,
    required this.bodyType,
    required this.maxWeightTons,
    required this.maxVolumeM3,
    this.assignedDriverId,
    this.assignedDriverName,
    this.isAvailable = true,
  });

  TruckModel copyWith({
    String? id,
    String? plateNumber,
    String? model,
    TruckBodyType? bodyType,
    double? maxWeightTons,
    double? maxVolumeM3,
    String? assignedDriverId,
    String? assignedDriverName,
    bool? isAvailable,
  }) {
    return TruckModel(
      id: id ?? this.id,
      plateNumber: plateNumber ?? this.plateNumber,
      model: model ?? this.model,
      bodyType: bodyType ?? this.bodyType,
      maxWeightTons: maxWeightTons ?? this.maxWeightTons,
      maxVolumeM3: maxVolumeM3 ?? this.maxVolumeM3,
      assignedDriverId: assignedDriverId ?? this.assignedDriverId,
      assignedDriverName: assignedDriverName ?? this.assignedDriverName,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'plateNumber': plateNumber,
        'model': model,
        'bodyType': bodyType.name,
        'maxWeightTons': maxWeightTons,
        'maxVolumeM3': maxVolumeM3,
        'assignedDriverId': assignedDriverId,
        'assignedDriverName': assignedDriverName,
        'isAvailable': isAvailable,
      };

  factory TruckModel.fromJson(Map<String, dynamic> json) => TruckModel(
        id: json['id'] as String,
        plateNumber: json['plateNumber'] as String,
        model: json['model'] as String,
        bodyType: TruckBodyType.values.firstWhere(
          (e) => e.name == json['bodyType'],
          orElse: () => TruckBodyType.fura,
        ),
        maxWeightTons: (json['maxWeightTons'] as num).toDouble(),
        maxVolumeM3: (json['maxVolumeM3'] as num).toDouble(),
        assignedDriverId: json['assignedDriverId'] as String?,
        assignedDriverName: json['assignedDriverName'] as String?,
        isAvailable: json['isAvailable'] as bool? ?? true,
      );

  @override
  List<Object?> get props => [
        id,
        plateNumber,
        model,
        bodyType,
        maxWeightTons,
        maxVolumeM3,
        assignedDriverId,
        assignedDriverName,
        isAvailable,
      ];
}
