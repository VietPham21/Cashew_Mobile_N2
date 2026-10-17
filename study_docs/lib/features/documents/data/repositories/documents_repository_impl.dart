import '../../domain/entities/study_document.dart';
import '../../domain/repositories/documents_repository.dart';
import '../db/app_database.dart';
import '../mappers/document_mapper.dart';

class DocumentsRepositoryImpl implements DocumentsRepository {
  final AppDatabase db;

  DocumentsRepositoryImpl(this.db);

  @override
  Future<void> add(StudyDocument doc) async {
    await db.upsertDocument(DocumentMapper.toRow(doc));
  }

  @override
  Future<void> update(StudyDocument doc) async {
    await db.upsertDocument(DocumentMapper.toRow(doc));
  }

  @override
  Future<void> delete(String id) async {
    await db.deleteDocumentById(id);
  }

  @override
  Future<StudyDocument?> getById(String id) async {
    final row = await db.getDocumentById(id);
    return row == null ? null : DocumentMapper.fromRow(row);
  }

  @override
  Future<List<StudyDocument>> search({
    String? keyword,
    DocumentType? type,
    String? course,
  }) async {
    final rows = await db.searchDocuments(
      keyword: keyword,
      type: type?.name,
      course: course,
    );
    return rows.map(DocumentMapper.fromRow).toList();
  }

  @override
  Future<List<StudyDocument>> getAll() async {
    final rows = await db.getAllDocuments();
    return rows.map(DocumentMapper.fromRow).toList();
  }
}
