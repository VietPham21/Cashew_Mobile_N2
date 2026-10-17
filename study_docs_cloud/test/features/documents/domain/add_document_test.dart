import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:study_docs/core/error/failures.dart';
import 'package:study_docs/features/documents/domain/entities/study_document.dart';
import 'package:study_docs/features/documents/domain/repositories/documents_repository.dart';
import 'package:study_docs/features/documents/domain/usecases/add_document.dart';

import 'add_document_test.mocks.dart';

@GenerateMocks([DocumentsRepository])
void main() {
  late AddDocument useCase;
  late MockDocumentsRepository mockRepo;

  setUp(() {
    mockRepo = MockDocumentsRepository();
    useCase = AddDocument(mockRepo);
  });

  final validDoc = StudyDocument(
    id: 'test-id-001',
    title: 'Bài giảng số 1',
    type: DocumentType.lecture,
    course: 'Lập trình Flutter',
    tags: ['chương 1'],
    notes: 'Ghi chú test',
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );

  group('AddDocument UseCase', () {
    test('gọi repository.add khi dữ liệu hợp lệ', () async {
      when(mockRepo.add(validDoc)).thenAnswer((_) async {});
      await useCase(validDoc);
      verify(mockRepo.add(validDoc)).called(1);
    });

    test('throw ValidationFailure khi title rỗng', () {
      final badDoc = StudyDocument(
        id: 'id', title: '', type: DocumentType.lecture,
        course: 'Flutter', tags: [], notes: '',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );
      expect(() => useCase(badDoc), throwsA(isA<ValidationFailure>()));
      verifyNever(mockRepo.add(any));
    });

    test('throw ValidationFailure khi course rỗng', () {
      final badDoc = StudyDocument(
        id: 'id', title: 'Có tiêu đề', type: DocumentType.lecture,
        course: '', tags: [], notes: '',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );
      expect(() => useCase(badDoc), throwsA(isA<ValidationFailure>()));
    });
  });
}
