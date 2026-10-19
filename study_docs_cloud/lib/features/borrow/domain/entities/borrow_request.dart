enum BorrowStatus { pending, approved, rejected }

class BorrowRequest {
  final String id;
  final String documentId;
  final String documentTitle;
  final String requesterId;
  final String requesterEmail;
  final String ownerId;
  final BorrowStatus status;
  final String? message;
  final DateTime createdAt;

  const BorrowRequest({
    required this.id,
    required this.documentId,
    required this.documentTitle,
    required this.requesterId,
    required this.requesterEmail,
    required this.ownerId,
    required this.status,
    this.message,
    required this.createdAt,
  });

  BorrowStatus get borrowStatus => status;
}
