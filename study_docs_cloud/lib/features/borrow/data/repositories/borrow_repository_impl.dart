import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/borrow_request.dart';
import '../../domain/repositories/borrow_repository.dart';

class BorrowRepositoryImpl implements BorrowRepository {
  final SupabaseClient _client;
  final String _currentUserId;

  BorrowRepositoryImpl({
    required SupabaseClient supabase,
    required String currentUserId,
  })  : _client = supabase,
        _currentUserId = currentUserId;

  BorrowStatus _parseStatus(String s) {
    switch (s) {
      case 'approved': return BorrowStatus.approved;
      case 'rejected': return BorrowStatus.rejected;
      default:         return BorrowStatus.pending;
    }
  }

  BorrowRequest _fromMap(Map<String, dynamic> m) {
    return BorrowRequest(
      id:             m['id'] as String,
      documentId:     m['document_id'] as String,
      documentTitle:  m['document_title'] as String? ?? 'Unknown',
      requesterId:    m['requester_id'] as String,
      requesterEmail: m['requester_email'] as String? ?? '',
      ownerId:        m['owner_id'] as String,
      status:         _parseStatus(m['status'] as String),
      message:        m['message'] as String?,
      createdAt:      DateTime.parse(m['created_at'] as String),
    );
  }

  @override
  Future<void> sendRequest({
    required String documentId,
    required String ownerId,
    String? message,
  }) async {
    // Lay email nguoi gui
    final userRes = await _client
        .from('users')
        .select('email')
        .eq('id', _currentUserId)
        .single();
    final email = userRes['email'] as String? ?? '';

    // Lay title cua document
    final docRes = await _client
        .from('documents')
        .select('title')
        .eq('id', documentId)
        .single();
    final title = docRes['title'] as String? ?? '';

    await _client.from('borrow_requests').insert({
      'id':             const Uuid().v4(),
      'document_id':    documentId,
      'document_title': title,
      'requester_id':   _currentUserId,
      'requester_email': email,
      'owner_id':       ownerId,
      'status':         'pending',
      'message':        message,
    });
  }

  @override
  Future<List<BorrowRequest>> getMyRequests() async {
    final res = await _client
        .from('borrow_requests')
        .select()
        .eq('requester_id', _currentUserId)
        .order('created_at', ascending: false);
    return (res as List).map((e) => _fromMap(e)).toList();
  }

  @override
  Future<List<BorrowRequest>> getIncomingRequests() async {
    final res = await _client
        .from('borrow_requests')
        .select()
        .eq('owner_id', _currentUserId)
        .order('created_at', ascending: false);
    return (res as List).map((e) => _fromMap(e)).toList();
  }

  @override
  Future<void> updateStatus(String requestId, BorrowStatus status) async {
    await _client
        .from('borrow_requests')
        .update({'status': status.name})
        .eq('id', requestId);
  }

  @override
  Future<bool> hasRequested(String documentId) async {
    final res = await _client
        .from('borrow_requests')
        .select('id')
        .eq('document_id', documentId)
        .eq('requester_id', _currentUserId);
    return (res as List).isNotEmpty;
  }
}
