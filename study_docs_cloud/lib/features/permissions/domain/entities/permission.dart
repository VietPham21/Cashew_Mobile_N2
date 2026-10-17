enum PermissionLevel { view, edit }

class Permission {
  final String id;
  final String documentId;
  final String ownerId;
  final String sharedWithUserId;
  final String sharedWithEmail;
  final PermissionLevel level;
  final DateTime createdAt;

  const Permission({
    required this.id,
    required this.documentId,
    required this.ownerId,
    required this.sharedWithUserId,
    required this.sharedWithEmail,
    required this.level,
    required this.createdAt,
  });
}
