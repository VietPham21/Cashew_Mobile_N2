import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final SupabaseClient _supabase;

  AuthRepositoryImpl({
    required FirebaseAuth firebaseAuth,
    required SupabaseClient supabase,
  })  : _firebaseAuth = firebaseAuth,
        _supabase = supabase;

  AppUser _toAppUser(User u) => AppUser(
        id: u.uid,
        email: u.email ?? '',
        displayName: u.displayName ?? u.email ?? 'User',
        avatarUrl: u.photoURL,
      );

  @override
  Future<AppUser> signInWithGoogle() async {
    final provider = GoogleAuthProvider()
      ..addScope('email')
      ..setCustomParameters({'prompt': 'select_account'});

    final cred = await _firebaseAuth.signInWithPopup(provider);
    final user = cred.user;
    if (user == null) throw Exception('Dang nhap that bai');

    // Lay Firebase ID token
    final idToken = await user.getIdToken(true);

    // Luu user vao Supabase voi token trong header
    await _supabase.from('users').upsert(
      {
        'id': user.uid,
        'email': user.email ?? '',
        'display_name': user.displayName ?? user.email ?? 'User',
        'avatar_url': user.photoURL,
      },
    );

    return _toAppUser(user);
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  @override
  AppUser? getCurrentUser() {
    final u = _firebaseAuth.currentUser;
    return u == null ? null : _toAppUser(u);
  }

  @override
  Stream<AppUser?> get authStateChanges =>
      _firebaseAuth.authStateChanges().map(
            (u) => u == null ? null : _toAppUser(u),
          );
}
