import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/permission.dart';
import '../../domain/repositories/permissions_repository.dart';

class PermissionsRepositoryImpl implements PermissionsRepository {
  final SupabaseClient supabase;

  PermissionsRepositoryImpl(this.supabase);

  @override
  Future<void> shareDocument({
    required String documentId,
    required String ownerId,
    required String targetEmail,
    required PermissionLevel level,
  }) async {
    // Query 1: tim user theo email
    final userRes = await supabase
        .from('users')
        .select('id, email')
        .eq('email', targetEmail)
        .maybeSingle();

    if (userRes == null) {
      throw Exception('Khong tim thay nguoi dung: $targetEmail\n'
          '(Ho phai dang nhap vao app it nhat 1 lan)');
    }

    final targetUserId = userRes['id'] as String;

    if (targetUserId == ownerId) {
      throw Exception('Khong the chia se cho chinh ban');
    }

    // Query 2: upsert permission
    await supabase.from('permissions').upsert({
      'document_id': documentId,
      'owner_id': ownerId,
      'shared_with_user_id': targetUserId,
      'permission_level': level.name,
    }, onConflict: 'document_id,shared_with_user_id');
  }

  @override
  Future<void> revokePermission(String permissionId) async {
    await supabase.from('permissions').delete().eq('id', permissionId);
  }

  @override
  Future<List<Permission>> getPermissionsForDocument(
      String documentId) async {
    // Query 1: lay danh sach permissions
    final permRes = await supabase
        .from('permissions')
        .select()
        .eq('document_id', documentId);

    if (permRes == null || (permRes as List).isEmpty) return [];

    // Query 2: lay thong tin email cua tung user
    final userIds = permRes
        .map((e) => e['shared_with_user_id'] as String)
        .toList();

    final userRes = await supabase
        .from('users')
        .select('id, email')
        .inFilter('id', userIds);

    final userMap = <String, String>{};
    for (final u in userRes as List) {
      userMap[u['id'] as String] = u['email'] as String;
    }

    return permRes.map((row) {
      final uid = row['shared_with_user_id'] as String;
      return Permission(
        id: row['id'],
        documentId: row['document_id'],
        ownerId: row['owner_id'],
        sharedWithUserId: uid,
        sharedWithEmail: userMap[uid] ?? '',
        level: PermissionLevel.values.byName(row['permission_level']),
        createdAt: DateTime.parse(row['created_at']),
      );
    }).toList();
  }
}
