import '../entities/study_document.dart';
import '../repositories/documents_repository.dart';
import '../../../../core/error/failures.dart';

class AddDocument {
  final DocumentsRepository repository;

  AddDocument(this.repository);

  Future<void> call(StudyDocument doc) async {
    if (doc.title.trim().isEmpty) {
      throw const ValidationFailure('Tiêu đề không được để trống');
    }
    if (doc.course.trim().isEmpty) {
      throw const ValidationFailure('Tên môn học không được để trống');
    }
    await repository.add(doc);
  }
}
