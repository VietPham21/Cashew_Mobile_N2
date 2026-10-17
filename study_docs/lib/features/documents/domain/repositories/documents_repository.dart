import '../entities/study_document.dart';

abstract class DocumentsRepository {
  Future<void> add(StudyDocument doc);
  Future<void> update(StudyDocument doc);
  Future<void> delete(String id);
  Future<StudyDocument?> getById(String id);
  Future<List<StudyDocument>> search({
    String? keyword,
    DocumentType? type,
    String? course,
  });
  Future<List<StudyDocument>> getAll();
}
