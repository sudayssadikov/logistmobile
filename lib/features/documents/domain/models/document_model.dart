import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../auth/domain/models/user_model.dart';

enum LogisticsDocType {
  driverLicense(
    labelKey: 'documents.driverLicense',
    icon: Icons.badge_outlined,
    targetRole: UserRole.driver,
  ),
  vehicleReg(
    labelKey: 'documents.vehicleReg',
    icon: Icons.directions_car_outlined,
    targetRole: UserRole.carrier,
  ),
  cmrInsurance(
    labelKey: 'documents.cmrInsurance',
    icon: Icons.shield_outlined,
    targetRole: UserRole.carrier,
  ),
  companyReg(
    labelKey: 'documents.companyReg',
    icon: Icons.domain_rounded,
    targetRole: UserRole.shipper,
  ),
  cargoClearance(
    labelKey: 'documents.cargoClearance',
    icon: Icons.assignment_turned_in_outlined,
    targetRole: UserRole.shipper,
  );

  final String labelKey;
  final IconData icon;
  final UserRole targetRole;

  const LogisticsDocType({
    required this.labelKey,
    required this.icon,
    required this.targetRole,
  });
}

enum DocumentVerificationStatus {
  pendingReview,
  verified,
  rejected;

  Color get color {
    switch (this) {
      case DocumentVerificationStatus.verified:
        return AppColors.emerald;
      case DocumentVerificationStatus.pendingReview:
        return AppColors.amber;
      case DocumentVerificationStatus.rejected:
        return AppColors.rose;
    }
  }

  String get labelKey {
    switch (this) {
      case DocumentVerificationStatus.verified:
        return 'documents.verified';
      case DocumentVerificationStatus.pendingReview:
        return 'documents.pendingReview';
      case DocumentVerificationStatus.rejected:
        return 'documents.rejected';
    }
  }
}

enum ExpirationStatus {
  active,
  expiringSoon,
  expired;

  Color get color {
    switch (this) {
      case ExpirationStatus.active:
        return AppColors.emerald;
      case ExpirationStatus.expiringSoon:
        return AppColors.amber;
      case ExpirationStatus.expired:
        return AppColors.rose;
    }
  }

  String get labelKey {
    switch (this) {
      case ExpirationStatus.active:
        return 'documents.active';
      case ExpirationStatus.expiringSoon:
        return 'documents.expiringSoon';
      case ExpirationStatus.expired:
        return 'documents.expired';
    }
  }
}

class DocumentModel extends Equatable {
  final String id;
  final LogisticsDocType docType;
  final String docNumber;
  final DateTime issueDate;
  final DateTime expiryDate;
  final DocumentVerificationStatus verificationStatus;
  final String? fileUrl;
  final String? fileName;
  final String? rejectionReason;
  final UserRole userRole;

  const DocumentModel({
    required this.id,
    required this.docType,
    required this.docNumber,
    required this.issueDate,
    required this.expiryDate,
    required this.verificationStatus,
    this.fileUrl,
    this.fileName,
    this.rejectionReason,
    required this.userRole,
  });

  int get daysUntilExpiry {
    final now = DateTime.now();
    return expiryDate.difference(now).inDays;
  }

  ExpirationStatus get expirationStatus {
    final days = daysUntilExpiry;
    if (days <= 0) return ExpirationStatus.expired;
    if (days <= 30) return ExpirationStatus.expiringSoon;
    return ExpirationStatus.active;
  }

  DocumentModel copyWith({
    String? id,
    LogisticsDocType? docType,
    String? docNumber,
    DateTime? issueDate,
    DateTime? expiryDate,
    DocumentVerificationStatus? verificationStatus,
    String? fileUrl,
    String? fileName,
    String? rejectionReason,
    UserRole? userRole,
  }) {
    return DocumentModel(
      id: id ?? this.id,
      docType: docType ?? this.docType,
      docNumber: docNumber ?? this.docNumber,
      issueDate: issueDate ?? this.issueDate,
      expiryDate: expiryDate ?? this.expiryDate,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      userRole: userRole ?? this.userRole,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'docType': docType.name,
      'docNumber': docNumber,
      'issueDate': issueDate.toIso8601String(),
      'expiryDate': expiryDate.toIso8601String(),
      'verificationStatus': verificationStatus.name,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'rejectionReason': rejectionReason,
      'userRole': userRole.name,
    };
  }

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'] as String,
      docType: LogisticsDocType.values.firstWhere(
        (e) => e.name == json['docType'],
        orElse: () => LogisticsDocType.driverLicense,
      ),
      docNumber: json['docNumber'] as String,
      issueDate: DateTime.parse(json['issueDate'] as String),
      expiryDate: DateTime.parse(json['expiryDate'] as String),
      verificationStatus: DocumentVerificationStatus.values.firstWhere(
        (e) => e.name == json['verificationStatus'],
        orElse: () => DocumentVerificationStatus.pendingReview,
      ),
      fileUrl: json['fileUrl'] as String?,
      fileName: json['fileName'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      userRole: UserRole.values.firstWhere(
        (e) => e.name == json['userRole'],
        orElse: () => UserRole.carrier,
      ),
    );
  }

  @override
  List<Object?> get props => [
        id,
        docType,
        docNumber,
        issueDate,
        expiryDate,
        verificationStatus,
        fileUrl,
        fileName,
        rejectionReason,
        userRole,
      ];
}
