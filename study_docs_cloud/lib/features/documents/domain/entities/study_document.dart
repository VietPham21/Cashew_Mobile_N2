enum DocumentType { lecture, assignment, reference, other }

class StudyDocument {
  final String id;
  final String ownerId;
  final String title;
  final String course;
  final DocumentType type;
  final String notes;
  final List<String> tags;
  final String filePath;
  final String fileName;
  final int fileSize;
  final bool isPublic;
  final double? latitude;
  final double? longitude;
  final String? locationName;
  final DateTime createdAt;
  final DateTime updatedAt;

  const StudyDocument({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.course,
    required this.type,
    required this.notes,
    required this.tags,
    required this.filePath,
    required this.fileName,
    required this.fileSize,
    required this.isPublic,
    this.latitude,
    this.longitude,
    this.locationName,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get hasFile => filePath.isNotEmpty;

  StudyDocument copyWith({
    String? id,
    String? ownerId,
    String? title,
    String? course,
    DocumentType? type,
    String? notes,
    List<String>? tags,
    String? filePath,
    String? fileName,
    int? fileSize,
    bool? isPublic,
    double? latitude,
    double? longitude,
    String? locationName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StudyDocument(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      title: title ?? this.title,
      course: course ?? this.course,
      type: type ?? this.type,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      isPublic: isPublic ?? this.isPublic,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationName: locationName ?? this.locationName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
