import 'package:flutter/material.dart';
import '../../domain/entities/study_document.dart';
import '../../domain/usecases/add_document.dart';
import '../../domain/usecases/delete_document.dart';
import '../../domain/usecases/search_documents.dart';
import '../../domain/usecases/update_document.dart';

class DocumentsViewModel extends ChangeNotifier {
  final AddDocument addDocumentUseCase;
  final UpdateDocument updateDocumentUseCase;
  final DeleteDocument deleteDocumentUseCase;
  final SearchDocuments searchDocumentsUseCase;

  DocumentsViewModel({
    required this.addDocumentUseCase,
    required this.updateDocumentUseCase,
    required this.deleteDocumentUseCase,
    required this.searchDocumentsUseCase,
  });

  List<StudyDocument> documents = [];
  bool isLoading = false;
  String? errorMessage;
  String searchKeyword = '';
  DocumentType? filterType;

  Future<void> loadDocuments({String? keyword, DocumentType? type}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      documents = await searchDocumentsUseCase(
        keyword: keyword ?? searchKeyword,
        type: type ?? filterType,
      );
    } catch (e) {
      errorMessage = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }

  Future<bool> add(StudyDocument doc) async {
    try {
      await addDocumentUseCase(doc);
      await loadDocuments();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> update(StudyDocument doc) async {
    try {
      await updateDocumentUseCase(doc);
      await loadDocuments();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> delete(String id) async {
    try {
      await deleteDocumentUseCase(id);
      await loadDocuments();
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  void setFilter({String? keyword, DocumentType? type}) {
    if (keyword != null) searchKeyword = keyword;
    filterType = type;
    loadDocuments(keyword: searchKeyword, type: filterType);
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }
}
