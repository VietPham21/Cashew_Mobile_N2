import '../repositories/documents_repository.dart';

class DeleteDocument {
  final DocumentsRepository repository;

  DeleteDocument(this.repository);

  Future<void> call(String id) async {
    await repository.delete(id);
  }
}
