import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/study_document.dart';
import '../../domain/repositories/documents_repository.dart';

class DocumentsViewModel extends ChangeNotifier {
  final DocumentsRepository repository;
  final String currentUserId;

  DocumentsViewModel({
    required this.repository,
    required this.currentUserId,
  });

  List<StudyDocument> myDocuments = [];
  List<StudyDocument> sharedDocuments = [];
  List<StudyDocument> searchResults = [];
  bool isLoading = false;
  String? errorMessage;
  String searchKeyword = '';
  DocumentType? filterType;
  bool showShared = false;

  // Map documentId -> permission_level cho tai lieu duoc chia se
  Map<String, String> sharedPermissions = {};

  List<StudyDocument> get displayDocuments =>
      showShared ? sharedDocuments : myDocuments;

  // Kiem tra user co quyen edit document nay khong
  bool canEdit(StudyDocument doc) {
    if (doc.ownerId == currentUserId) return true;
    return sharedPermissions[doc.id] == 'edit';
  }

  Future<void> loadAll() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      myDocuments = await repository.getMyDocuments();
      sharedDocuments = await repository.getSharedWithMe();

      // Lay quyen cua tung tai lieu duoc chia se
      await _loadSharedPermissions();
    } catch (e) {
      errorMessage = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> _loadSharedPermissions() async {
    if (sharedDocuments.isEmpty) {
      sharedPermissions = {};
      return;
    }

    try {
      final res = await Supabase.instance.client
          .from('permissions')
          .select('document_id, permission_level')
          .eq('shared_with_user_id', currentUserId);

      sharedPermissions = {};
      for (final row in res as List) {
        sharedPermissions[row['document_id']] =
            row['permission_level'];
      }
    } catch (_) {}
  }

  Future<void> searchDocs({String? keyword, DocumentType? type}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      searchResults = await repository.search(
        keyword: keyword ?? searchKeyword,
        type: type ?? filterType,
      );
    } catch (e) {
      errorMessage = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }

  Future<bool> add({
    required String title,
    required DocumentType type,
    required String course,
    required List<String> tags,
    required String notes,
    required bool isPublic,
    List<int>? fileBytes,
    String? fileName,
  }) async {
    try {
      final doc = StudyDocument(
        id: const Uuid().v4(),
        ownerId: currentUserId,
        title: title,
        type: type,
        course: course,
        tags: tags,
        notes: notes,
        fileUrl: '',
        fileName: fileName ?? '',
        fileSize: 0,
        isPublic: isPublic,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repository.add(
        doc,
        fileBytes: fileBytes,
        fileName: fileName,
      );
      await loadAll();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> update(
    StudyDocument doc, {
    List<int>? fileBytes,
    String? fileName,
  }) async {
    try {
      await repository.update(
        doc,
        fileBytes: fileBytes,
        fileName: fileName,
      );
      await loadAll();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> delete(String id) async {
    try {
      await repository.delete(id);
      await loadAll();
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  void toggleShowShared(bool value) {
    showShared = value;
    notifyListeners();
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }
}
