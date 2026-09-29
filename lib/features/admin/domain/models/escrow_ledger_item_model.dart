import 'package:equatable/equatable.dart';

enum EscrowInterventionAction {
  freezeHold('freezeHold', 'Muzlatish (Hold)'),
  forceRelease('forceRelease', 'Majburiy chiqarish'),
  refundShipper('refundShipper', 'Yuk egasiga qaytarish');

  final String key;
  final String label;
  const EscrowInterventionAction(this.key, this.label);
}

class EscrowLedgerItemModel extends Equatable {
  final String id;
  final String shipmentId;
  final String trackingCode;
  final String shipperName;
  final String carrierName;
  final double amount;
  final double platformFee;
  final String status; // 'HOLD', 'FROZEN', 'RELEASED', 'REFUNDED'
  final DateTime fundedAt;
  final DateTime? releasedAt;
  final bool isFlaggedSuspicious;

  const EscrowLedgerItemModel({
    required this.id,
    required this.shipmentId,
    required this.trackingCode,
    required this.shipperName,
    required this.carrierName,
    required this.amount,
    required this.platformFee,
    required this.status,
    required this.fundedAt,
    this.releasedAt,
    required this.isFlaggedSuspicious,
  });

  EscrowLedgerItemModel copyWith({
    String? status,
    bool? isFlaggedSuspicious,
  }) {
    return EscrowLedgerItemModel(
      id: id,
      shipmentId: shipmentId,
      trackingCode: trackingCode,
      shipperName: shipperName,
      carrierName: carrierName,
      amount: amount,
      platformFee: platformFee,
      status: status ?? this.status,
      fundedAt: fundedAt,
      releasedAt: releasedAt,
      isFlaggedSuspicious: isFlaggedSuspicious ?? this.isFlaggedSuspicious,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'shipmentId': shipmentId,
        'trackingCode': trackingCode,
        'shipperName': shipperName,
        'carrierName': carrierName,
        'amount': amount,
        'platformFee': platformFee,
        'status': status,
        'fundedAt': fundedAt.toIso8601String(),
        'releasedAt': releasedAt?.toIso8601String(),
        'isFlaggedSuspicious': isFlaggedSuspicious,
      };

  factory EscrowLedgerItemModel.fromJson(Map<String, dynamic> json) => EscrowLedgerItemModel(
        id: json['id'] as String,
        shipmentId: json['shipmentId'] as String,
        trackingCode: json['trackingCode'] as String,
        shipperName: json['shipperName'] as String,
        carrierName: json['carrierName'] as String,
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        platformFee: (json['platformFee'] as num?)?.toDouble() ?? 0.0,
        status: json['status'] as String? ?? 'HOLD',
        fundedAt: DateTime.tryParse(json['fundedAt'] as String? ?? '') ?? DateTime.now(),
        releasedAt: json['releasedAt'] != null ? DateTime.tryParse(json['releasedAt'] as String) : null,
        isFlaggedSuspicious: json['isFlaggedSuspicious'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [
        id,
        shipmentId,
        trackingCode,
        shipperName,
        carrierName,
        amount,
        platformFee,
        status,
        fundedAt,
        releasedAt,
        isFlaggedSuspicious,
      ];
}
