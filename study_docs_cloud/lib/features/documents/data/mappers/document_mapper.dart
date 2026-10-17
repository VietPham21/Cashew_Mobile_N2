import 'package:drift/drift.dart';
import '../../domain/entities/study_document.dart';
import '../db/app_database.dart';

class DocumentMapper {
  static StudyDocument fromRow(DocumentsTableData row) {
    return StudyDocument(
      id: row.id,
      title: row.title,
      type: DocumentType.values.byName(row.type),
      course: row.course,
      tags: row.tagsCsv.isEmpty
          ? []
          : row.tagsCsv
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList(),
      notes: row.notes,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  static DocumentsTableCompanion toRow(StudyDocument doc) {
    return DocumentsTableCompanion(
      id: Value(doc.id),
      title: Value(doc.title),
      type: Value(doc.type.name),
      course: Value(doc.course),
      tagsCsv: Value(doc.tags.join(',')),
      notes: Value(doc.notes),
      createdAt: Value(doc.createdAt),
      updatedAt: Value(doc.updatedAt),
    );
  }
}
