import 'package:equatable/equatable.dart';
import '../../domain/models/document_model.dart';

enum DocumentStateStatus { initial, loading, success, failure }

class DocumentState extends Equatable {
  final DocumentStateStatus status;
  final List<DocumentModel> documents;
  final String? errorMessage;
  final String? successMessage;

  const DocumentState({
    this.status = DocumentStateStatus.initial,
    this.documents = const [],
    this.errorMessage,
    this.successMessage,
  });

  List<DocumentModel> get activeDocs =>
      documents.where((d) => d.expirationStatus == ExpirationStatus.active && d.verificationStatus == DocumentVerificationStatus.verified).toList();

  List<DocumentModel> get expiringSoonDocs =>
      documents.where((d) => d.expirationStatus == ExpirationStatus.expiringSoon).toList();

  List<DocumentModel> get expiredOrRejectedDocs =>
      documents.where((d) => d.expirationStatus == ExpirationStatus.expired || d.verificationStatus == DocumentVerificationStatus.rejected).toList();

  DocumentState copyWith({
    DocumentStateStatus? status,
    List<DocumentModel>? documents,
    String? errorMessage,
    String? successMessage,
  }) {
    return DocumentState(
      status: status ?? this.status,
      documents: documents ?? this.documents,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [status, documents, errorMessage, successMessage];
}
