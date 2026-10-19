import '../entities/borrow_request.dart';

abstract class BorrowRepository {
  // Gui yeu cau muon
  Future<void> sendRequest({
    required String documentId,
    required String ownerId,
    String? message,
  });

  // Lay danh sach request minh da gui
  Future<List<BorrowRequest>> getMyRequests();

  // Lay danh sach request nguoi khac gui den minh (owner)
  Future<List<BorrowRequest>> getIncomingRequests();

  // Duyet hoac tu choi
  Future<void> updateStatus(String requestId, BorrowStatus status);

  // Kiem tra da gui request cho doc nay chua
  Future<bool> hasRequested(String documentId);
}
