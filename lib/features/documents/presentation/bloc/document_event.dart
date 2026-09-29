import 'package:equatable/equatable.dart';
import '../../domain/models/document_model.dart';
import '../../../auth/domain/models/user_model.dart';

abstract class DocumentEvent extends Equatable {
  const DocumentEvent();
  @override
  List<Object?> get props => [];
}

class LoadDocumentsRequested extends DocumentEvent {
  final UserRole role;
  const LoadDocumentsRequested(this.role);
  @override
  List<Object?> get props => [role];
}

class UploadDocumentSubmitted extends DocumentEvent {
  final LogisticsDocType docType;
  final String docNumber;
  final DateTime issueDate;
  final DateTime expiryDate;
  final String fileName;
  final UserRole userRole;

  const UploadDocumentSubmitted({
    required this.docType,
    required this.docNumber,
    required this.issueDate,
    required this.expiryDate,
    required this.fileName,
    required this.userRole,
  });

  @override
  List<Object?> get props => [docType, docNumber, issueDate, expiryDate, fileName, userRole];
}

class DeleteDocumentSubmitted extends DocumentEvent {
  final String documentId;
  const DeleteDocumentSubmitted(this.documentId);
  @override
  List<Object?> get props => [documentId];
}
