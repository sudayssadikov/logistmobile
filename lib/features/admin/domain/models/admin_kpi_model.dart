import 'package:equatable/equatable.dart';

class AdminKpiModel extends Equatable {
  final double totalGmv;
  final double totalRevenueCommission;
  final int activeLoadsInTransit;
  final int pendingBidsCount;
  final int completedDeliveriesCount;
  final int totalShippersCount;
  final int totalCarriersCount;
  final int activeDriversOnDuty;
  final double totalEscrowHeld;
  final double totalPayoutsReleased;
  final double systemUptimePercent;
  final int openDisputesCount;
  final int pendingKycCount;

  const AdminKpiModel({
    required this.totalGmv,
    required this.totalRevenueCommission,
    required this.activeLoadsInTransit,
    required this.pendingBidsCount,
    required this.completedDeliveriesCount,
    required this.totalShippersCount,
    required this.totalCarriersCount,
    required this.activeDriversOnDuty,
    required this.totalEscrowHeld,
    required this.totalPayoutsReleased,
    required this.systemUptimePercent,
    required this.openDisputesCount,
    required this.pendingKycCount,
  });

  Map<String, dynamic> toJson() => {
        'totalGmv': totalGmv,
        'totalRevenueCommission': totalRevenueCommission,
        'activeLoadsInTransit': activeLoadsInTransit,
        'pendingBidsCount': pendingBidsCount,
        'completedDeliveriesCount': completedDeliveriesCount,
        'totalShippersCount': totalShippersCount,
        'totalCarriersCount': totalCarriersCount,
        'activeDriversOnDuty': activeDriversOnDuty,
        'totalEscrowHeld': totalEscrowHeld,
        'totalPayoutsReleased': totalPayoutsReleased,
        'systemUptimePercent': systemUptimePercent,
        'openDisputesCount': openDisputesCount,
        'pendingKycCount': pendingKycCount,
      };

  factory AdminKpiModel.fromJson(Map<String, dynamic> json) => AdminKpiModel(
        totalGmv: (json['totalGmv'] as num?)?.toDouble() ?? 0.0,
        totalRevenueCommission: (json['totalRevenueCommission'] as num?)?.toDouble() ?? 0.0,
        activeLoadsInTransit: json['activeLoadsInTransit'] as int? ?? 0,
        pendingBidsCount: json['pendingBidsCount'] as int? ?? 0,
        completedDeliveriesCount: json['completedDeliveriesCount'] as int? ?? 0,
        totalShippersCount: json['totalShippersCount'] as int? ?? 0,
        totalCarriersCount: json['totalCarriersCount'] as int? ?? 0,
        activeDriversOnDuty: json['activeDriversOnDuty'] as int? ?? 0,
        totalEscrowHeld: (json['totalEscrowHeld'] as num?)?.toDouble() ?? 0.0,
        totalPayoutsReleased: (json['totalPayoutsReleased'] as num?)?.toDouble() ?? 0.0,
        systemUptimePercent: (json['systemUptimePercent'] as num?)?.toDouble() ?? 99.99,
        openDisputesCount: json['openDisputesCount'] as int? ?? 0,
        pendingKycCount: json['pendingKycCount'] as int? ?? 0,
      );

  @override
  List<Object?> get props => [
        totalGmv,
        totalRevenueCommission,
        activeLoadsInTransit,
        pendingBidsCount,
        completedDeliveriesCount,
        totalShippersCount,
        totalCarriersCount,
        activeDriversOnDuty,
        totalEscrowHeld,
        totalPayoutsReleased,
        systemUptimePercent,
        openDisputesCount,
        pendingKycCount,
      ];
}
