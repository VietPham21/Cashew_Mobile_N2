enum DocumentType {
  lecture,
  assignment,
  reference,
  other,
}

class StudyDocument {
  final String id;
  final String title;
  final DocumentType type;
  final String course;
  final List<String> tags;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const StudyDocument({
    required this.id,
    required this.title,
    required this.type,
    required this.course,
    required this.tags,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  StudyDocument copyWith({
    String? title,
    DocumentType? type,
    String? course,
    List<String>? tags,
    String? notes,
  }) {
    return StudyDocument(
      id: id,
      title: title ?? this.title,
      type: type ?? this.type,
      course: course ?? this.course,
      tags: tags ?? this.tags,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
