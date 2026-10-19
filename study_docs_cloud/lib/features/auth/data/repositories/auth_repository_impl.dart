import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../core/services/notification_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final SupabaseClient _supabase;

  AuthRepositoryImpl({
    required FirebaseAuth firebaseAuth,
    required SupabaseClient supabase,
  }) : _firebaseAuth = firebaseAuth,
       _supabase = supabase;

  AppUser _toAppUser(User u, {String? id}) => AppUser(
    id: id ?? u.uid,
    email: u.email ?? '',
    displayName: u.displayName ?? u.email ?? 'User',
    avatarUrl: u.photoURL,
  );

  @override
  Future<AppUser> signInWithGoogle() async {
    late final UserCredential cred;
    if (kIsWeb) {
      final provider = GoogleAuthProvider()
        ..addScope('email')
        ..setCustomParameters({'prompt': 'select_account'});
      cred = await _firebaseAuth.signInWithPopup(provider);
    } else {
      final googleUser = await GoogleSignIn(scopes: ['email']).signIn();
      if (googleUser == null) {
        throw Exception('Dang nhap da bi huy');
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      cred = await _firebaseAuth.signInWithCredential(credential);
    }

    final user = cred.user;
    if (user == null) throw Exception('Dang nhap that bai');

    await user.getIdToken(true);

    final email = user.email;
    if (email == null || email.isEmpty) {
      throw Exception('Google account did not provide an email address');
    }

    // Demo data may already contain this email under a seeded ID. Keep that
    // canonical database ID so documents and permissions remain connected.
    final existing = await _supabase
        .from('users')
        .select('id')
        .eq('email', email)
        .maybeSingle();

    final String databaseUserId;
    if (existing != null) {
      databaseUserId = existing['id'] as String;
    } else {
      await _supabase.from('users').insert({
        'id': user.uid,
        'email': email,
        'display_name': user.displayName ?? email,
        'avatar_url': user.photoURL,
      });
      databaseUserId = user.uid;
    }

    // Luu FCM token sau khi login
    try {
      final fcmToken = await NotificationService.initialize();
      if (fcmToken != null) {
        await NotificationService.saveToken(user.uid, fcmToken);
      }
    } catch (_) {}

    return _toAppUser(user, id: databaseUserId);
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    if (!kIsWeb) {
      await GoogleSignIn().signOut();
    }
  }

  @override
  AppUser? getCurrentUser() {
    final u = _firebaseAuth.currentUser;
    return u == null ? null : _toAppUser(u);
  }

  @override
  Stream<AppUser?> get authStateChanges => _firebaseAuth.authStateChanges().map(
    (u) => u == null ? null : _toAppUser(u),
  );
}
