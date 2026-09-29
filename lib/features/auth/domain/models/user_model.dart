import 'package:equatable/equatable.dart';
import '../../../../core/localization/app_localizations.dart';

enum UserRole {
  shipper('shipper', 'Yuk beruvchi (Shipper)', 'Post loads, manage escrow, track freight'),
  carrier('carrier', 'Tashuvchi (Carrier)', 'Browse load board, manage fleet, submit bids'),
  driver('driver', 'Haydovchi (Driver)', 'Navigate routes, update shipment status, sign POD'),
  admin('admin', 'Tizim Administratori (Admin)', 'Global control tower, fleet telemetry, system oversight');

  final String key;
  final String defaultTitle;
  final String defaultSubtitle;

  const UserRole(this.key, this.defaultTitle, this.defaultSubtitle);

  String get title {
    final tKey = 'roles.${name}Title';
    final val = tKey.tr();
    return val != tKey ? val : defaultTitle;
  }

  String get subtitle {
    final sKey = 'roles.${name}Subtitle';
    final val = sKey.tr();
    return val != sKey ? val : defaultSubtitle;
  }

  static UserRole fromKey(String? key) {
    return UserRole.values.firstWhere(
      (e) => e.key.toLowerCase() == key?.toLowerCase(),
      orElse: () => UserRole.shipper,
    );
  }
}

class UserModel extends Equatable {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final UserRole role;
  final String? companyName;
  final String? avatarUrl;
  final bool isVerified;
  final double rating;
  final int completedTrips;
  final double walletBalance;
  final String? vehicleModel;
  final String? vehiclePlate;
  final String? driverLicenseNumber;
  final String? bankCardNumber;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    this.companyName,
    this.avatarUrl,
    this.isVerified = true,
    this.rating = 4.9,
    this.completedTrips = 142,
    this.walletBalance = 18450000.0,
    this.vehicleModel = 'Volvo FH16 (Refrigerated)',
    this.vehiclePlate = '01 A 777 AA',
    this.driverLicenseNumber = 'AA 9812450',
    this.bankCardNumber = '8600 **** **** 4819',
  });

  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    UserRole? role,
    String? companyName,
    String? avatarUrl,
    bool? isVerified,
    double? rating,
    int? completedTrips,
    double? walletBalance,
    String? vehicleModel,
    String? vehiclePlate,
    String? driverLicenseNumber,
    String? bankCardNumber,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      companyName: companyName ?? this.companyName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isVerified: isVerified ?? this.isVerified,
      rating: rating ?? this.rating,
      completedTrips: completedTrips ?? this.completedTrips,
      walletBalance: walletBalance ?? this.walletBalance,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      driverLicenseNumber: driverLicenseNumber ?? this.driverLicenseNumber,
      bankCardNumber: bankCardNumber ?? this.bankCardNumber,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'role': role.key,
      'company_name': companyName,
      'avatar_url': avatarUrl,
      'is_verified': isVerified,
      'rating': rating,
      'completed_trips': completedTrips,
      'wallet_balance': walletBalance,
      'vehicle_model': vehicleModel,
      'vehicle_plate': vehiclePlate,
      'driver_license_number': driverLicenseNumber,
      'bank_card_number': bankCardNumber,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      role: UserRole.fromKey(json['role'] as String?),
      companyName: json['company_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      isVerified: json['is_verified'] as bool? ?? false,
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      completedTrips: json['completed_trips'] as int? ?? 0,
      walletBalance: (json['wallet_balance'] as num?)?.toDouble() ?? 0.0,
      vehicleModel: json['vehicle_model'] as String?,
      vehiclePlate: json['vehicle_plate'] as String?,
      driverLicenseNumber: json['driver_license_number'] as String?,
      bankCardNumber: json['bank_card_number'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        fullName,
        email,
        phone,
        role,
        companyName,
        avatarUrl,
        isVerified,
        rating,
        completedTrips,
        walletBalance,
        vehicleModel,
        vehiclePlate,
        driverLicenseNumber,
        bankCardNumber,
      ];
}
