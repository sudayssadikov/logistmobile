import '../models/document_model.dart';
import '../../../auth/domain/models/user_model.dart';

abstract class IDocumentRepository {
  Future<List<DocumentModel>> getDocuments({required UserRole role});
  Future<DocumentModel> uploadDocument({
    required LogisticsDocType docType,
    required String docNumber,
    required DateTime issueDate,
    required DateTime expiryDate,
    required String fileName,
    required UserRole userRole,
  });
  Future<void> deleteDocument(String id);
}
