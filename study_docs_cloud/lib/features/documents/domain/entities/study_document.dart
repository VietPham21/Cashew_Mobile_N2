enum DocumentType {
  lecture,
  assignment,
  reference,
  other,
}

class StudyDocument {
  final String id;
  final String ownerId;
  final String title;
  final DocumentType type;
  final String course;
  final List<String> tags;
  final String notes;
  final String fileUrl;
  final String fileName;
  final int fileSize;
  final bool isPublic;
  final DateTime createdAt;
  final DateTime updatedAt;

  const StudyDocument({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.type,
    required this.course,
    required this.tags,
    required this.notes,
    required this.fileUrl,
    required this.fileName,
    required this.fileSize,
    required this.isPublic,
    required this.createdAt,
    required this.updatedAt,
  });

  StudyDocument copyWith({
    String? title,
    DocumentType? type,
    String? course,
    List<String>? tags,
    String? notes,
    String? fileUrl,
    String? fileName,
    int? fileSize,
    bool? isPublic,
  }) {
    return StudyDocument(
      id: id,
      ownerId: ownerId,
      title: title ?? this.title,
      type: type ?? this.type,
      course: course ?? this.course,
      tags: tags ?? this.tags,
      notes: notes ?? this.notes,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  bool get hasFile => fileUrl.isNotEmpty;
}
