import 'dart:async';
import '../../../../core/network/dio_client.dart';
import '../../domain/models/document_model.dart';
import '../../domain/repositories/document_repository.dart';
import '../../../auth/domain/models/user_model.dart';

class DocumentRepositoryImpl implements IDocumentRepository {
  final DioClient? _dioClient;

  DocumentRepositoryImpl([this._dioClient]);

  @override
  Future<List<DocumentModel>> getDocuments({required UserRole role}) async {
    if (_dioClient == null) return [];

    try {
      final response = await _dioClient!.get('/documents', queryParameters: {'role': role.key});
      if (response.statusCode == 200 && response.data != null) {
        final List raw = response.data['data'] ?? [];
        return raw.map((item) {
          final m = item as Map<String, dynamic>;
          return DocumentModel(
            id: m['id'] ?? '',
            docType: LogisticsDocType.values.firstWhere(
              (e) => e.name == m['doc_type'] || e.name == m['docType'],
              orElse: () => LogisticsDocType.driverLicense,
            ),
            docNumber: m['doc_number'] ?? m['docNumber'] ?? '',
            issueDate: m['issue_date'] != null
                ? DateTime.parse(m['issue_date'])
                : (m['issueDate'] != null ? DateTime.parse(m['issueDate']) : DateTime.now()),
            expiryDate: m['expiry_date'] != null
                ? DateTime.parse(m['expiry_date'])
                : (m['expiryDate'] != null ? DateTime.parse(m['expiryDate']) : DateTime.now()),
            verificationStatus: DocumentVerificationStatus.values.firstWhere(
              (e) => e.name == m['verification_status'] || e.name == m['verificationStatus'],
              orElse: () => DocumentVerificationStatus.pendingReview,
            ),
            fileName: m['file_name'] ?? m['fileName'] ?? 'document.pdf',
            fileUrl: m['file_url'] ?? m['fileUrl'] ?? '',
            userRole: role,
          );
        }).toList();
      }
    } catch (_) {
      // Re-throw or return empty list
    }
    return [];
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
    if (_dioClient == null) {
      throw Exception('Server bilan aloqa mavjud emas');
    }

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

    if (response.statusCode == 200 && response.data != null) {
      final m = response.data['data'] as Map<String, dynamic>;
      return DocumentModel(
        id: m['id'] ?? '',
        docType: docType,
        docNumber: m['doc_number'] ?? docNumber,
        issueDate: issueDate,
        expiryDate: expiryDate,
        verificationStatus: DocumentVerificationStatus.pendingReview,
        fileName: fileName,
        fileUrl: m['file_url'] ?? '',
        userRole: userRole,
      );
    }
    throw Exception(response.data?['message'] ?? 'Hujjatni yuklab bo\'lmadi');
  }

  @override
  Future<void> deleteDocument(String id) async {
    if (_dioClient == null) {
      throw Exception('Server bilan aloqa mavjud emas');
    }
    final response = await _dioClient!.delete('/documents/$id');
    if (response.statusCode != 200) {
      throw Exception(response.data?['message'] ?? 'Hujjatni o\'chirib bo\'lmadi');
    }
  }
}
