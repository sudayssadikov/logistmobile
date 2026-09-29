import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/document_repository.dart';
import 'document_event.dart';
import 'document_state.dart';

class DocumentBloc extends Bloc<DocumentEvent, DocumentState> {
  final IDocumentRepository _repository;

  DocumentBloc({required IDocumentRepository repository})
      : _repository = repository,
        super(const DocumentState()) {
    on<LoadDocumentsRequested>(_onLoadDocuments);
    on<UploadDocumentSubmitted>(_onUploadDocument);
    on<DeleteDocumentSubmitted>(_onDeleteDocument);
  }

  Future<void> _onLoadDocuments(
    LoadDocumentsRequested event,
    Emitter<DocumentState> emit,
  ) async {
    emit(state.copyWith(status: DocumentStateStatus.loading));
    try {
      final docs = await _repository.getDocuments(role: event.role);
      emit(state.copyWith(
        status: DocumentStateStatus.success,
        documents: docs,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: DocumentStateStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onUploadDocument(
    UploadDocumentSubmitted event,
    Emitter<DocumentState> emit,
  ) async {
    emit(state.copyWith(status: DocumentStateStatus.loading));
    try {
      final doc = await _repository.uploadDocument(
        docType: event.docType,
        docNumber: event.docNumber,
        issueDate: event.issueDate,
        expiryDate: event.expiryDate,
        fileName: event.fileName,
        userRole: event.userRole,
      );
      final updated = List.of(state.documents)..insert(0, doc);
      emit(state.copyWith(
        status: DocumentStateStatus.success,
        documents: updated,
        successMessage: 'Document uploaded successfully',
      ));
    } catch (e) {
      emit(state.copyWith(
        status: DocumentStateStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onDeleteDocument(
    DeleteDocumentSubmitted event,
    Emitter<DocumentState> emit,
  ) async {
    try {
      await _repository.deleteDocument(event.documentId);
      final updated = state.documents.where((d) => d.id != event.documentId).toList();
      emit(state.copyWith(
        status: DocumentStateStatus.success,
        documents: updated,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: DocumentStateStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }
}
