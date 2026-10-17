import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

class SignInWithGoogle {
  final AuthRepository repository;
  SignInWithGoogle(this.repository);

  Future<AppUser> call() async {
    return repository.signInWithGoogle();
  }
}
