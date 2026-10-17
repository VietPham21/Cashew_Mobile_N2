import '../entities/study_document.dart';
import '../repositories/documents_repository.dart';
import '../../../../core/error/failures.dart';

class UpdateDocument {
  final DocumentsRepository repository;

  UpdateDocument(this.repository);

  Future<void> call(StudyDocument doc) async {
    if (doc.title.trim().isEmpty) {
      throw const ValidationFailure('Tiêu đề không được để trống');
    }
    await repository.update(doc);
  }
}
