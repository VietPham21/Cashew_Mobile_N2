import '../entities/app_user.dart';

abstract class AuthRepository {
  Future<AppUser> signInWithGoogle();
  Future<void> signOut();
  AppUser? getCurrentUser();
  Stream<AppUser?> get authStateChanges;
}
