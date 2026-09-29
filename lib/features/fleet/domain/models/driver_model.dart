import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';

enum DriverStatus {
  idle,
  inTransit,
  offDuty;

  Color get color {
    switch (this) {
      case DriverStatus.idle:
        return AppColors.emerald;
      case DriverStatus.inTransit:
        return AppColors.primary;
      case DriverStatus.offDuty:
        return AppColors.darkTextMuted;
    }
  }

  String get labelKey {
    switch (this) {
      case DriverStatus.idle:
        return 'fleet.idle';
      case DriverStatus.inTransit:
        return 'fleet.inTransit';
      case DriverStatus.offDuty:
        return 'fleet.offDuty';
    }
  }
}

class DriverModel extends Equatable {
  final String id;
  final String fullName;
  final String phone;
  final String email;
  final double rating;
  final int completedTrips;
  final DriverStatus status;
  final String? assignedVehiclePlate;
  final String? assignedTruckId;

  const DriverModel({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.rating,
    required this.completedTrips,
    required this.status,
    this.assignedVehiclePlate,
    this.assignedTruckId,
  });

  DriverModel copyWith({
    String? id,
    String? fullName,
    String? phone,
    String? email,
    double? rating,
    int? completedTrips,
    DriverStatus? status,
    String? assignedVehiclePlate,
    String? assignedTruckId,
  }) {
    return DriverModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      rating: rating ?? this.rating,
      completedTrips: completedTrips ?? this.completedTrips,
      status: status ?? this.status,
      assignedVehiclePlate: assignedVehiclePlate ?? this.assignedVehiclePlate,
      assignedTruckId: assignedTruckId ?? this.assignedTruckId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'phone': phone,
        'email': email,
        'rating': rating,
        'completedTrips': completedTrips,
        'status': status.name,
        'assignedVehiclePlate': assignedVehiclePlate,
        'assignedTruckId': assignedTruckId,
      };

  factory DriverModel.fromJson(Map<String, dynamic> json) => DriverModel(
        id: json['id'] as String,
        fullName: json['fullName'] as String,
        phone: json['phone'] as String,
        email: json['email'] as String,
        rating: (json['rating'] as num).toDouble(),
        completedTrips: json['completedTrips'] as int,
        status: DriverStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => DriverStatus.idle,
        ),
        assignedVehiclePlate: json['assignedVehiclePlate'] as String?,
        assignedTruckId: json['assignedTruckId'] as String?,
      );

  @override
  List<Object?> get props => [
        id,
        fullName,
        phone,
        email,
        rating,
        completedTrips,
        status,
        assignedVehiclePlate,
        assignedTruckId,
      ];
}
