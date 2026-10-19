import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  static Future<String?> initialize() async {
    try {
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('FCM: permission denied');
        return null;
      }

      // Web canh VAPID key (Firebase Console > Project Settings > Cloud Messaging > Web Push certificates)
      // Neu chua co VAPID, getToken van co the tra null tren web — app van chay binh thuong
      final token = await _fcm.getToken(
        vapidKey: 'BIIafEW_B1owh-mCI1Rsc30SOLQuLbTfOeNx0EdXc8jzhITkiXwN5hmU_eF5POVWd4V935GU91vTCdgLbYPVg5g',
      );
      debugPrint('FCM Token: $token');
      return token;
    } catch (e) {
      debugPrint('FCM init error: $e');
      return null;
    }
  }

  static Future<void> saveToken(String userId, String token) async {
    try {
      await Supabase.instance.client
          .from('users')
          .update({'fcm_token': token})
          .eq('id', userId);
      debugPrint('FCM token saved for $userId');
    } catch (e) {
      debugPrint('Save FCM token error: $e');
    }
  }

  // Tao notification trong DB (in-app + realtime)
  static Future<void> sendToUser({
    required String userId,
    required String title,
    required String body,
    String type = 'info',
  }) async {
    try {
      await Supabase.instance.client.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'body': body,
        'type': type,
        'is_read': false,
      });
      debugPrint('Notification sent to $userId: $title');
    } catch (e) {
      debugPrint('Send notification error: $e');
    }
  }

  // Lang nghe FCM khi app dang mo
  static void listenForeground(void Function(String title, String body) onMessage) {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final n = message.notification;
      if (n != null) {
        onMessage(n.title ?? 'Notification', n.body ?? '');
      }
    });
  }

  // Lay danh sach notification chua doc
  static Future<List<Map<String, dynamic>>> getUnread(String userId) async {
    try {
      final res = await Supabase.instance.client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .eq('is_read', false)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(res as List);
    } catch (_) {
      return [];
    }
  }

  // Danh dau da doc
  static Future<void> markAllRead(String userId) async {
    try {
      await Supabase.instance.client
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (_) {}
  }
}
