import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/study_document.dart';
import '../../domain/repositories/documents_repository.dart';

class DocumentsRepositoryImpl implements DocumentsRepository {
  final SupabaseClient _client;
  final String _currentUserId;

  DocumentsRepositoryImpl({
    required SupabaseClient supabase,
    required String currentUserId,
  }) : _client = supabase,
       _currentUserId = currentUserId;

  DocumentType _parseType(String t) {
    switch (t) {
      case 'assignment':
        return DocumentType.assignment;
      case 'reference':
        return DocumentType.reference;
      case 'other':
        return DocumentType.other;
      default:
        return DocumentType.lecture;
    }
  }

  StudyDocument _fromMap(Map<String, dynamic> m) {
    return StudyDocument(
      id: m['id'] as String,
      ownerId: m['owner_id'] as String,
      title: m['title'] as String,
      course: m['course'] as String? ?? '',
      type: _parseType(m['type'] as String? ?? 'lecture'),
      notes: m['notes'] as String? ?? '',
      tags:
          (m['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          [],
      filePath: m['file_path'] as String? ?? '',
      fileName: m['file_name'] as String? ?? '',
      fileSize: m['file_size'] as int? ?? 0,
      isPublic: m['is_public'] as bool? ?? false,
      latitude: (m['latitude'] as num?)?.toDouble(),
      longitude: (m['longitude'] as num?)?.toDouble(),
      locationName: m['location_name'] as String?,
      createdAt: DateTime.parse(m['created_at'] as String),
      updatedAt: DateTime.parse(m['updated_at'] as String),
    );
  }

  @override
  Future<List<StudyDocument>> getMyDocuments() async {
    final res = await _client
        .from('documents')
        .select()
        .order('updated_at', ascending: false);
    return (res as List).map((e) => _fromMap(e)).toList();
  }

  @override
  Future<List<StudyDocument>> getSharedWithMe() async {
    final perms = await _client
        .from('permissions')
        .select('document_id')
        .eq('shared_with_user_id', _currentUserId);

    final ids = (perms as List).map((e) => e['document_id'] as String).toList();
    if (ids.isEmpty) return [];

    final docs = await _client
        .from('documents')
        .select()
        .inFilter('id', ids)
        .order('updated_at', ascending: false);

    return (docs as List).map((e) => _fromMap(e)).toList();
  }

  @override
  Future<StudyDocument?> getById(String id) async {
    final res = await _client
        .from('documents')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (res == null) return null;
    return _fromMap(res);
  }

  @override
  Future<String> createFileSignedUrl(String path) =>
      _client.storage.from('documents').createSignedUrl(path, 300);

  @override
  Future<void> add(
    StudyDocument doc, {
    List<int>? fileBytes,
    String? fileName,
  }) async {
    String uploadedPath = '';
    String uploadedName = '';
    int uploadedSize = 0;

    await _client.from('documents').insert({
      'id': doc.id,
      'owner_id': doc.ownerId,
      'title': doc.title,
      'course': doc.course,
      'type': doc.type.name,
      'notes': doc.notes,
      'tags': doc.tags,
      'file_path': null,
      'file_url': null,
      'file_name': null,
      'file_size': null,
      'is_public': doc.isPublic,
      'latitude': doc.latitude,
      'longitude': doc.longitude,
      'location_name': doc.locationName,
    });

    if (fileBytes != null && fileName != null) {
      uploadedPath = '${doc.id}/$fileName';
      await _client.storage
          .from('documents')
          .uploadBinary(
            uploadedPath,
            Uint8List.fromList(fileBytes),
            fileOptions: const FileOptions(upsert: true),
          );
      uploadedName = fileName;
      uploadedSize = fileBytes.length;
      await _client
          .from('documents')
          .update({
            'file_path': uploadedPath,
            'file_name': uploadedName,
            'file_size': uploadedSize,
          })
          .eq('id', doc.id);
    }
  }

  @override
  Future<void> update(
    StudyDocument doc, {
    List<int>? fileBytes,
    String? fileName,
  }) async {
    String uploadedPath = doc.filePath;
    String uploadedName = doc.fileName;
    int uploadedSize = doc.fileSize;

    if (fileBytes != null && fileName != null) {
      final path = '${doc.id}/$fileName';
      await _client.storage
          .from('documents')
          .uploadBinary(
            path,
            Uint8List.fromList(fileBytes),
            fileOptions: const FileOptions(upsert: true),
          );
      uploadedPath = path;
      uploadedName = fileName;
      uploadedSize = fileBytes.length;
    }

    await _client
        .from('documents')
        .update({
          'title': doc.title,
          'course': doc.course,
          'type': doc.type.name,
          'notes': doc.notes,
          'tags': doc.tags,
          'file_path': uploadedPath.isNotEmpty ? uploadedPath : null,
          'file_url': null,
          'file_name': uploadedName.isNotEmpty ? uploadedName : null,
          'file_size': uploadedSize > 0 ? uploadedSize : null,
          'is_public': doc.isPublic,
          'latitude': doc.latitude,
          'longitude': doc.longitude,
          'location_name': doc.locationName,
        })
        .eq('id', doc.id);
  }

  @override
  Future<void> delete(String id) async {
    final row = await _client
        .from('documents')
        .select('file_path')
        .eq('id', id)
        .maybeSingle();
    final path = row?['file_path'] as String?;
    if (path != null && path.isNotEmpty) {
      await _client.storage.from('documents').remove([path]);
    }
    await _client.from('documents').delete().eq('id', id);
  }

  @override
  Future<List<StudyDocument>> search({
    String? keyword,
    DocumentType? type,
    String? course,
  }) async {
    var query = _client.from('documents').select();

    if (keyword != null && keyword.isNotEmpty) {
      query = query.or(
        'title.ilike.%$keyword%,course.ilike.%$keyword%,notes.ilike.%$keyword%',
      );
    }
    if (type != null) {
      query = query.eq('type', type.name);
    }
    if (course != null && course.isNotEmpty) {
      query = query.ilike('course', '%$course%');
    }

    final res = await query.order('updated_at', ascending: false);
    return (res as List).map((e) => _fromMap(e)).toList();
  }

  @override
  Future<List<StudyDocument>> getRecommendations() async {
    // Lay tat ca tags tu tai lieu cua user hien tai
    final myDocs = await getMyDocuments();
    final myTags = <String>{};
    for (final doc in myDocs) {
      myTags.addAll(doc.tags);
    }

    // Neu chua co tag nao, lay 10 tai lieu public moi nhat
    if (myTags.isEmpty) {
      final res = await _client
          .from('documents')
          .select()
          .eq('is_public', true)
          .neq('owner_id', _currentUserId)
          .order('created_at', ascending: false)
          .limit(10);
      return (res as List).map((e) => _fromMap(e)).toList();
    }

    // Lay tai lieu public cua nguoi khac
    final res = await _client
        .from('documents')
        .select()
        .eq('is_public', true)
        .neq('owner_id', _currentUserId)
        .order('created_at', ascending: false);

    final allPublic = (res as List).map((e) => _fromMap(e)).toList();

    // Tinh diem cho tung tai lieu dua tren so tag trung
    final scored = allPublic.map((doc) {
      final common = doc.tags.where((t) => myTags.contains(t)).length;
      return MapEntry(doc, common);
    }).toList();

    // Sap xep theo diem giam dan, lay top 10
    scored.sort((a, b) => b.value.compareTo(a.value));

    return scored
        .where((e) => e.value > 0 || allPublic.length <= 10)
        .take(10)
        .map((e) => e.key)
        .toList();
  }
}
