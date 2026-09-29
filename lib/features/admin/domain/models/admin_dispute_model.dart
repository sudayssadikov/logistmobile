import 'package:equatable/equatable.dart';

enum DisputeCategory {
  cargoDamage('cargoDamage', 'Yuk shikastlanishi'),
  nonPayment('nonPayment', 'To\'lov kechikishi'),
  routeAbandonment('routeAbandonment', 'Marshrutdan chiqish / Tashlab ketish'),
  severeDelay('severeDelay', 'Katta kechikish');

  final String key;
  final String label;
  const DisputeCategory(this.key, this.label);

  static DisputeCategory fromKey(String? key) {
    return DisputeCategory.values.firstWhere(
      (e) => e.key == key,
      orElse: () => DisputeCategory.cargoDamage,
    );
  }
}

enum DisputeVerdict {
  releaseToCarrier('releaseToCarrier', 'Haydovchiga to\'liq to\'lash'),
  refundToShipper('refundToShipper', 'Yuk egasiga to\'liq qaytarish'),
  splitEqual('splitEqual', '50/50 taqsimlash'),
  penaltyDeduction('penaltyDeduction', 'Jarima chegirib to\'lash');

  final String key;
  final String label;
  const DisputeVerdict(this.key, this.label);

  static DisputeVerdict fromKey(String? key) {
    return DisputeVerdict.values.firstWhere(
      (e) => e.key == key,
      orElse: () => DisputeVerdict.releaseToCarrier,
    );
  }
}

class AdminDisputeCaseModel extends Equatable {
  final String id;
  final String shipmentId;
  final String trackingCode;
  final DisputeCategory category;
  final String complainantName;
  final String respondentName;
  final double disputedAmount;
  final String description;
  final String shipperManifestUrl;
  final List<String> podEvidencePhotos;
  final String status;
  final DateTime createdAt;
  final DisputeVerdict? finalVerdict;
  final String? resolutionNotes;

  const AdminDisputeCaseModel({
    required this.id,
    required this.shipmentId,
    required this.trackingCode,
    required this.category,
    required this.complainantName,
    required this.respondentName,
    required this.disputedAmount,
    required this.description,
    required this.shipperManifestUrl,
    required this.podEvidencePhotos,
    required this.status,
    required this.createdAt,
    this.finalVerdict,
    this.resolutionNotes,
  });

  AdminDisputeCaseModel copyWith({
    String? status,
    DisputeVerdict? finalVerdict,
    String? resolutionNotes,
  }) {
    return AdminDisputeCaseModel(
      id: id,
      shipmentId: shipmentId,
      trackingCode: trackingCode,
      category: category,
      complainantName: complainantName,
      respondentName: respondentName,
      disputedAmount: disputedAmount,
      description: description,
      shipperManifestUrl: shipperManifestUrl,
      podEvidencePhotos: podEvidencePhotos,
      status: status ?? this.status,
      createdAt: createdAt,
      finalVerdict: finalVerdict ?? this.finalVerdict,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'shipmentId': shipmentId,
        'trackingCode': trackingCode,
        'category': category.key,
        'complainantName': complainantName,
        'respondentName': respondentName,
        'disputedAmount': disputedAmount,
        'description': description,
        'shipperManifestUrl': shipperManifestUrl,
        'podEvidencePhotos': podEvidencePhotos,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
        'finalVerdict': finalVerdict?.key,
        'resolutionNotes': resolutionNotes,
      };

  factory AdminDisputeCaseModel.fromJson(Map<String, dynamic> json) => AdminDisputeCaseModel(
        id: json['id'] as String,
        shipmentId: json['shipmentId'] as String,
        trackingCode: json['trackingCode'] as String,
        category: DisputeCategory.fromKey(json['category'] as String?),
        complainantName: json['complainantName'] as String,
        respondentName: json['respondentName'] as String,
        disputedAmount: (json['disputedAmount'] as num?)?.toDouble() ?? 0.0,
        description: json['description'] as String,
        shipperManifestUrl: json['shipperManifestUrl'] as String,
        podEvidencePhotos: (json['podEvidencePhotos'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
        status: json['status'] as String? ?? 'OPEN',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
        finalVerdict: json['finalVerdict'] != null ? DisputeVerdict.fromKey(json['finalVerdict'] as String) : null,
        resolutionNotes: json['resolutionNotes'] as String?,
      );

  @override
  List<Object?> get props => [
        id,
        shipmentId,
        trackingCode,
        category,
        complainantName,
        respondentName,
        disputedAmount,
        description,
        shipperManifestUrl,
        podEvidencePhotos,
        status,
        createdAt,
        finalVerdict,
        resolutionNotes,
      ];
}
