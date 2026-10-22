import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/borrow_request.dart';
import '../../domain/repositories/borrow_repository.dart';
import '../../../../core/services/notification_service.dart';

class BorrowViewModel extends ChangeNotifier {
  final BorrowRepository repository;

  BorrowViewModel({required this.repository});

  List<BorrowRequest> myRequests = [];
  List<BorrowRequest> incomingRequests = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> loadAll() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      myRequests = await repository.getMyRequests();
      incomingRequests = await repository.getIncomingRequests();
    } catch (e) {
      errorMessage = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }

  Future<bool> sendRequest({
    required String documentId,
    required String ownerId,
    String? message,
  }) async {
    try {
      await repository
          .sendRequest(
            documentId: documentId,
            ownerId: ownerId,
            message: message,
          )
          .timeout(const Duration(seconds: 20));

      // The borrow request is the primary operation. Notification delivery is
      // best-effort and must never keep the UI waiting after the request saved.
      unawaited(
        NotificationService.sendToUser(
          userId: ownerId,
          title: 'New Borrow Request',
          body: message?.isNotEmpty == true
              ? message!
              : 'Someone requested to borrow your document',
          type: 'borrow_request',
        ).timeout(const Duration(seconds: 5), onTimeout: () {}),
      );

      // Do not keep the request button spinning while the inbox refreshes.
      unawaited(loadAll());
      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> approve(String requestId) async {
    try {
      // Tim request de lay thong tin
      final req = incomingRequests.firstWhere((r) => r.id == requestId);

      // Tu dong cap quyen view cho requester
      await Supabase.instance.client.from('permissions').upsert({
        'id': const Uuid().v4(),
        'document_id': req.documentId,
        'owner_id': req.ownerId,
        'shared_with_user_id': req.requesterId,
        'permission_level': 'view',
      }, onConflict: 'document_id,shared_with_user_id');

      // Mark approved only after the permission was actually granted.
      await repository.updateStatus(requestId, BorrowStatus.approved);

      // Thong bao cho requester
      await NotificationService.sendToUser(
        userId: req.requesterId,
        title: 'Borrow Request Approved',
        body: 'Your request for "${req.documentTitle}" was approved!',
        type: 'borrow_approved',
      );

      await loadAll();
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> reject(String requestId) async {
    try {
      final req = incomingRequests.firstWhere((r) => r.id == requestId);

      await repository.updateStatus(requestId, BorrowStatus.rejected);

      await NotificationService.sendToUser(
        userId: req.requesterId,
        title: 'Borrow Request Rejected',
        body: 'Your request for "${req.documentTitle}" was rejected.',
        type: 'borrow_rejected',
      );

      await loadAll();
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<bool> hasRequested(String documentId) async {
    return await repository.hasRequested(documentId);
  }
}
