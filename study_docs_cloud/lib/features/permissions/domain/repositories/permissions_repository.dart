import '../entities/permission.dart';

abstract class PermissionsRepository {
  Future<void> shareDocument({
    required String documentId,
    required String ownerId,
    required String targetEmail,
    required PermissionLevel level,
  });
  Future<void> revokePermission(String permissionId);
  Future<List<Permission>> getPermissionsForDocument(String documentId);
}
