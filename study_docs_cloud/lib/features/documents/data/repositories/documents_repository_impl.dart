import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/study_document.dart';
import '../../domain/repositories/documents_repository.dart';

class DocumentsRepositoryImpl implements DocumentsRepository {
  final SupabaseClient supabase;
  final String currentUserId;

  DocumentsRepositoryImpl({
    required this.supabase,
    required this.currentUserId,
  });

  StudyDocument _fromMap(Map<String, dynamic> m) => StudyDocument(
        id: m['id'],
        ownerId: m['owner_id'],
        title: m['title'],
        course: m['course'] ?? '',
        type: DocumentType.values.byName(m['type'] ?? 'other'),
        tags: List<String>.from(m['tags'] ?? []),
        notes: m['notes'] ?? '',
        fileUrl: m['file_url'] ?? '',
        fileName: m['file_name'] ?? '',
        fileSize: (m['file_size'] ?? 0) as int,
        isPublic: m['is_public'] ?? false,
        createdAt: DateTime.parse(m['created_at']),
        updatedAt: DateTime.parse(m['updated_at']),
      );

  Map<String, dynamic> _toMap(StudyDocument doc) => {
        'id': doc.id,
        'owner_id': doc.ownerId,
        'title': doc.title,
        'course': doc.course,
        'type': doc.type.name,
        'notes': doc.notes,
        'tags': doc.tags,
        'file_url': doc.fileUrl,
        'file_name': doc.fileName,
        'file_size': doc.fileSize,
        'is_public': doc.isPublic,
        'updated_at': doc.updatedAt.toIso8601String(),
      };

  // Upload file len Supabase Storage
  Future<String> _uploadFile(
      String docId, List<int> bytes, String fileName) async {
    final path = '$currentUserId/$docId/$fileName';

    await supabase.storage.from('documents').uploadBinary(
          path,
          bytes is List<int> ? bytes as dynamic : bytes,
          fileOptions: const FileOptions(upsert: true),
        );

    final url =
        supabase.storage.from('documents').getPublicUrl(path);
    return url;
  }

  @override
  Future<void> add(StudyDocument doc,
      {List<int>? fileBytes, String? fileName}) async {
    String fileUrl = '';
    int fileSize = 0;
    String uploadedName = '';

    if (fileBytes != null && fileName != null) {
      fileUrl = await _uploadFile(doc.id, fileBytes, fileName);
      fileSize = fileBytes.length;
      uploadedName = fileName;
    }

    final map = _toMap(doc);
    map['file_url'] = fileUrl;
    map['file_name'] = uploadedName;
    map['file_size'] = fileSize;

    await supabase.from('documents').insert(map);
  }

  @override
  Future<void> update(StudyDocument doc,
      {List<int>? fileBytes, String? fileName}) async {
    String fileUrl = doc.fileUrl;
    int fileSize = doc.fileSize;
    String uploadedName = doc.fileName;

    if (fileBytes != null && fileName != null) {
      fileUrl = await _uploadFile(doc.id, fileBytes, fileName);
      fileSize = fileBytes.length;
      uploadedName = fileName;
    }

    final map = _toMap(doc);
    map['file_url'] = fileUrl;
    map['file_name'] = uploadedName;
    map['file_size'] = fileSize;
    map.remove('id');

    await supabase
        .from('documents')
        .update(map)
        .eq('id', doc.id);
  }

  @override
  Future<void> delete(String id) async {
    // Xoa file tren storage truoc
    try {
      final doc = await getById(id);
      if (doc != null && doc.hasFile) {
        final path =
            '$currentUserId/$id/${doc.fileName}';
        await supabase.storage
            .from('documents')
            .remove([path]);
      }
    } catch (_) {}

    // Xoa document tren database
    await supabase.from('documents').delete().eq('id', id);
  }

  @override
  Future<StudyDocument?> getById(String id) async {
    final res = await supabase
        .from('documents')
        .select()
        .eq('id', id)
        .maybeSingle();
    return res == null ? null : _fromMap(res);
  }

  @override
  Future<List<StudyDocument>> getMyDocuments() async {
    final res = await supabase
        .from('documents')
        .select()
        .eq('owner_id', currentUserId)
        .order('updated_at', ascending: false);
    return (res as List).map((e) => _fromMap(e)).toList();
  }

  @override
  Future<List<StudyDocument>> getSharedWithMe() async {
    final permRes = await supabase
        .from('permissions')
        .select('document_id')
        .eq('shared_with_user_id', currentUserId);

    if ((permRes as List).isEmpty) return [];

    final docIds =
        permRes.map((e) => e['document_id'] as String).toList();

    final docRes = await supabase
        .from('documents')
        .select()
        .inFilter('id', docIds)
        .order('updated_at', ascending: false);

    return (docRes as List).map((e) => _fromMap(e)).toList();
  }

  @override
  Future<List<StudyDocument>> search({
    String? keyword,
    DocumentType? type,
    String? course,
  }) async {
    var query = supabase.from('documents').select();

    if (type != null) {
      query = query.eq('type', type.name);
    }
    if (course != null && course.isNotEmpty) {
      query = query.eq('course', course);
    }

    final res = await query.order('updated_at', ascending: false);
    var docs = (res as List).map((e) => _fromMap(e)).toList();

    if (keyword != null && keyword.isNotEmpty) {
      final kw = keyword.toLowerCase();
      docs = docs
          .where((d) =>
              d.title.toLowerCase().contains(kw) ||
              d.notes.toLowerCase().contains(kw) ||
              d.course.toLowerCase().contains(kw))
          .toList();
    }

    return docs;
  }
}
