import '../entities/study_document.dart';
import '../repositories/documents_repository.dart';

class SearchDocuments {
  final DocumentsRepository repository;

  SearchDocuments(this.repository);

  Future<List<StudyDocument>> call({
    String? keyword,
    DocumentType? type,
    String? course,
  }) async {
    return repository.search(
      keyword: keyword,
      type: type,
      course: course,
    );
  }
}
