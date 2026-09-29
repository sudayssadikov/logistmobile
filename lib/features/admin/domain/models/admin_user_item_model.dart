import 'package:equatable/equatable.dart';
import '../../../../features/auth/domain/models/user_model.dart';

class AdminUserItemModel extends Equatable {
  final String id;
  final String fullName;
  final String emailOrPhone;
  final UserRole role;
  final String? companyName;
  final bool isVerified;
  final bool isSuspended;
  final double rating;
  final int completedTrips;
  final double walletBalance;
  final DateTime registeredAt;
  final String? lastActiveDevice;

  const AdminUserItemModel({
    required this.id,
    required this.fullName,
    required this.emailOrPhone,
    required this.role,
    this.companyName,
    required this.isVerified,
    required this.isSuspended,
    required this.rating,
    required this.completedTrips,
    required this.walletBalance,
    required this.registeredAt,
    this.lastActiveDevice,
  });

  AdminUserItemModel copyWith({
    bool? isSuspended,
    bool? isVerified,
  }) {
    return AdminUserItemModel(
      id: id,
      fullName: fullName,
      emailOrPhone: emailOrPhone,
      role: role,
      companyName: companyName,
      isVerified: isVerified ?? this.isVerified,
      isSuspended: isSuspended ?? this.isSuspended,
      rating: rating,
      completedTrips: completedTrips,
      walletBalance: walletBalance,
      registeredAt: registeredAt,
      lastActiveDevice: lastActiveDevice,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'emailOrPhone': emailOrPhone,
        'role': role.key,
        'companyName': companyName,
        'isVerified': isVerified,
        'isSuspended': isSuspended,
        'rating': rating,
        'completedTrips': completedTrips,
        'walletBalance': walletBalance,
        'registeredAt': registeredAt.toIso8601String(),
        'lastActiveDevice': lastActiveDevice,
      };

  factory AdminUserItemModel.fromJson(Map<String, dynamic> json) => AdminUserItemModel(
        id: json['id'] as String,
        fullName: json['fullName'] as String,
        emailOrPhone: json['emailOrPhone'] as String,
        role: UserRole.fromKey(json['role'] as String?),
        companyName: json['companyName'] as String?,
        isVerified: json['isVerified'] as bool? ?? false,
        isSuspended: json['isSuspended'] as bool? ?? false,
        rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
        completedTrips: json['completedTrips'] as int? ?? 0,
        walletBalance: (json['walletBalance'] as num?)?.toDouble() ?? 0.0,
        registeredAt: DateTime.tryParse(json['registeredAt'] as String? ?? '') ?? DateTime.now(),
        lastActiveDevice: json['lastActiveDevice'] as String?,
      );

  @override
  List<Object?> get props => [
        id,
        fullName,
        emailOrPhone,
        role,
        companyName,
        isVerified,
        isSuspended,
        rating,
        completedTrips,
        walletBalance,
        registeredAt,
        lastActiveDevice,
      ];
}
