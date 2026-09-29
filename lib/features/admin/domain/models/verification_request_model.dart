import 'package:equatable/equatable.dart';

enum VerificationDocType {
  companyRegistration('companyRegistration', 'Guvohnoma (STIR / OGRN)'),
  driverLicense('driverLicense', 'Haydovchilik guvohnomasi'),
  vehicleTechPassport('vehicleTechPassport', 'Texnik pasport'),
  cmrInsurance('cmrInsurance', 'CMR / Frayt sug\'urtasi');

  final String key;
  final String label;
  const VerificationDocType(this.key, this.label);

  static VerificationDocType fromKey(String? key) {
    return VerificationDocType.values.firstWhere(
      (e) => e.key == key,
      orElse: () => VerificationDocType.companyRegistration,
    );
  }
}

enum VerificationStatus {
  pending('pending', 'Kutilmoqda'),
  approved('approved', 'Tasdiqlangan'),
  rejected('rejected', 'Rad etilgan'),
  reuploadRequested('reuploadRequested', 'Qayta yuklash so\'ralgan');

  final String key;
  final String label;
  const VerificationStatus(this.key, this.label);

  static VerificationStatus fromKey(String? key) {
    return VerificationStatus.values.firstWhere(
      (e) => e.key == key,
      orElse: () => VerificationStatus.pending,
    );
  }
}

class VerificationRequestModel extends Equatable {
  final String id;
  final String userId;
  final String userFullName;
  final String userRoleKey;
  final String companyName;
  final VerificationDocType docType;
  final String documentNumber;
  final String documentFileUrl;
  final VerificationStatus status;
  final DateTime submittedAt;
  final String? rejectionReason;

  const VerificationRequestModel({
    required this.id,
    required this.userId,
    required this.userFullName,
    required this.userRoleKey,
    required this.companyName,
    required this.docType,
    required this.documentNumber,
    required this.documentFileUrl,
    required this.status,
    required this.submittedAt,
    this.rejectionReason,
  });

  VerificationRequestModel copyWith({
    VerificationStatus? status,
    String? rejectionReason,
  }) {
    return VerificationRequestModel(
      id: id,
      userId: userId,
      userFullName: userFullName,
      userRoleKey: userRoleKey,
      companyName: companyName,
      docType: docType,
      documentNumber: documentNumber,
      documentFileUrl: documentFileUrl,
      status: status ?? this.status,
      submittedAt: submittedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'userFullName': userFullName,
        'userRoleKey': userRoleKey,
        'companyName': companyName,
        'docType': docType.key,
        'documentNumber': documentNumber,
        'documentFileUrl': documentFileUrl,
        'status': status.key,
        'submittedAt': submittedAt.toIso8601String(),
        'rejectionReason': rejectionReason,
      };

  factory VerificationRequestModel.fromJson(Map<String, dynamic> json) => VerificationRequestModel(
        id: json['id'] as String,
        userId: json['userId'] as String,
        userFullName: json['userFullName'] as String,
        userRoleKey: json['userRoleKey'] as String,
        companyName: json['companyName'] as String,
        docType: VerificationDocType.fromKey(json['docType'] as String?),
        documentNumber: json['documentNumber'] as String,
        documentFileUrl: json['documentFileUrl'] as String,
        status: VerificationStatus.fromKey(json['status'] as String?),
        submittedAt: DateTime.tryParse(json['submittedAt'] as String? ?? '') ?? DateTime.now(),
        rejectionReason: json['rejectionReason'] as String?,
      );

  @override
  List<Object?> get props => [
        id,
        userId,
        userFullName,
        userRoleKey,
        companyName,
        docType,
        documentNumber,
        documentFileUrl,
        status,
        submittedAt,
        rejectionReason,
      ];
}
