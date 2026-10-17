import '../entities/study_document.dart';

abstract class DocumentsRepository {
  Future<void> add(StudyDocument doc, {List<int>? fileBytes, String? fileName});
  Future<void> update(StudyDocument doc, {List<int>? fileBytes, String? fileName});
  Future<void> delete(String id);
  Future<StudyDocument?> getById(String id);
  Future<List<StudyDocument>> getMyDocuments();
  Future<List<StudyDocument>> getSharedWithMe();
  Future<List<StudyDocument>> search({
    String? keyword,
    DocumentType? type,
    String? course,
  });
}
