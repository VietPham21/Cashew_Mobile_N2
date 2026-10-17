import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

class DocumentsTable extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get type => text()();
  TextColumn get course => text()();
  TextColumn get tagsCsv => text()();
  TextColumn get notes => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [DocumentsTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  Future<void> upsertDocument(DocumentsTableCompanion row) =>
      into(documentsTable).insertOnConflictUpdate(row);

  Future<int> deleteDocumentById(String id) =>
      (delete(documentsTable)..where((t) => t.id.equals(id))).go();

  Future<DocumentsTableData?> getDocumentById(String id) =>
      (select(documentsTable)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<List<DocumentsTableData>> searchDocuments({
    String? keyword,
    String? type,
    String? course,
  }) {
    final query = select(documentsTable);

    if (keyword != null && keyword.trim().isNotEmpty) {
      final k = '%${keyword.trim()}%';
      query.where(
          (t) => t.title.like(k) | t.notes.like(k) | t.course.like(k));
    }
    if (type != null) {
      query.where((t) => t.type.equals(type));
    }
    if (course != null && course.trim().isNotEmpty) {
      query.where((t) => t.course.equals(course));
    }

    query.orderBy([(t) => OrderingTerm.desc(t.updatedAt)]);
    return query.get();
  }

  Future<List<DocumentsTableData>> getAllDocuments() =>
      (select(documentsTable)
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .get();
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'study_docs.db'));
    return NativeDatabase.createInBackground(file);
  });
}
