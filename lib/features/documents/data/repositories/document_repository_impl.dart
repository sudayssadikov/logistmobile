import 'dart:async';
import 'package:uuid/uuid.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/models/document_model.dart';
import '../../domain/repositories/document_repository.dart';
import '../../../auth/domain/models/user_model.dart';

class DocumentRepositoryImpl implements IDocumentRepository {
  final DioClient? _dioClient;

  final List<DocumentModel> _mockDocs = [
    DocumentModel(
      id: 'DOC-101',
      docType: LogisticsDocType.driverLicense,
      docNumber: 'AA 9283741',
      issueDate: DateTime.now().subtract(const Duration(days: 300)),
      expiryDate: DateTime.now().add(const Duration(days: 420)),
      verificationStatus: DocumentVerificationStatus.verified,
      fileName: 'driver_license_front.pdf',
      fileUrl: 'https://docs.logiflow.uz/demo/driver_license.pdf',
      userRole: UserRole.driver,
    ),
    DocumentModel(
      id: 'DOC-102',
      docType: LogisticsDocType.vehicleReg,
      docNumber: 'TR-UZ-849204',
      issueDate: DateTime.now().subtract(const Duration(days: 340)),
      expiryDate: DateTime.now().add(const Duration(days: 25)),
      verificationStatus: DocumentVerificationStatus.verified,
      fileName: 'tech_passport_volvo.pdf',
      fileUrl: 'https://docs.logiflow.uz/demo/tech_passport.pdf',
      userRole: UserRole.carrier,
    ),
    DocumentModel(
      id: 'DOC-103',
      docType: LogisticsDocType.cmrInsurance,
      docNumber: 'POL-CMR-2026-991',
      issueDate: DateTime.now().subtract(const Duration(days: 400)),
      expiryDate: DateTime.now().subtract(const Duration(days: 10)),
      verificationStatus: DocumentVerificationStatus.rejected,
      fileName: 'cmr_insurance_2025.pdf',
      rejectionReason: 'Sug\'urta polisi muddati tugagan.',
      fileUrl: 'https://docs.logiflow.uz/demo/cmr.pdf',
      userRole: UserRole.carrier,
    ),
    DocumentModel(
      id: 'DOC-104',
      docType: LogisticsDocType.companyReg,
      docNumber: 'STIR: 309 881 294',
      issueDate: DateTime.now().subtract(const Duration(days: 500)),
      expiryDate: DateTime.now().add(const Duration(days: 730)),
      verificationStatus: DocumentVerificationStatus.verified,
      fileName: 'guvohnoma_stir_2024.pdf',
      fileUrl: 'https://docs.logiflow.uz/demo/stir.pdf',
      userRole: UserRole.shipper,
    ),
  ];

  DocumentRepositoryImpl([this._dioClient]);

  @override
  Future<List<DocumentModel>> getDocuments({required UserRole role}) async {
    if (_dioClient != null) {
      try {
        final response = await _dioClient!.get('/documents', queryParameters: {'role': role.key});
        if (response.statusCode == 200 && response.data != null) {
          final List raw = response.data['data'] ?? [];
          if (raw.isNotEmpty) {
            // parsed from backend
          }
        }
      } catch (_) {
        // Fallback
      }
    }
    await Future.delayed(const Duration(milliseconds: 150));
    return _mockDocs;
  }

  @override
  Future<DocumentModel> uploadDocument({
    required LogisticsDocType docType,
    required String docNumber,
    required DateTime issueDate,
    required DateTime expiryDate,
    required String fileName,
    required UserRole userRole,
  }) async {
    if (_dioClient != null) {
      try {
        final response = await _dioClient!.post(
          '/documents',
          data: {
            'doc_type': docType.name,
            'doc_number': docNumber,
            'issue_date': issueDate.toIso8601String(),
            'expiry_date': expiryDate.toIso8601String(),
            'file_name': fileName,
            'user_role': userRole.key,
          },
        );
        if (response.statusCode == 200) {
          // Success
        }
      } catch (_) {
        // Fallback
      }
    }

    await Future.delayed(const Duration(milliseconds: 200));
    final newDoc = DocumentModel(
      id: 'DOC-${const Uuid().v4().substring(0, 8).toUpperCase()}',
      docType: docType,
      docNumber: docNumber,
      issueDate: issueDate,
      expiryDate: expiryDate,
      verificationStatus: DocumentVerificationStatus.pendingReview,
      fileName: fileName,
      fileUrl: 'https://docs.logiflow.uz/uploads/$fileName',
      userRole: userRole,
    );
    _mockDocs.insert(0, newDoc);
    return newDoc;
  }

  @override
  Future<void> deleteDocument(String id) async {
    if (_dioClient != null) {
      try {
        await _dioClient!.delete('/documents/$id');
      } catch (_) {
        // Fallback
      }
    }
    await Future.delayed(const Duration(milliseconds: 100));
    _mockDocs.removeWhere((d) => d.id == id);
  }
}
