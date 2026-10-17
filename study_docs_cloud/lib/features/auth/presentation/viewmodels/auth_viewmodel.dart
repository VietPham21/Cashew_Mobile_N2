import 'package:flutter/material.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/usecases/sign_in_google.dart';
import '../../domain/usecases/sign_out.dart';

class AuthViewModel extends ChangeNotifier {
  final SignInWithGoogle signInUseCase;
  final SignOut signOutUseCase;

  AuthViewModel({
    required this.signInUseCase,
    required this.signOutUseCase,
  });

  AppUser? currentUser;
  bool isLoading = false;
  String? errorMessage;

  Future<void> signIn() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      currentUser = await signInUseCase();
    } catch (e) {
      errorMessage = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> signOut() async {
    await signOutUseCase();
    currentUser = null;
    notifyListeners();
  }

  void setUser(AppUser? user) {
    currentUser = user;
    notifyListeners();
  }
}
