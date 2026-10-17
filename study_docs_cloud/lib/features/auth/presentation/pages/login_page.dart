import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.shade900,
      body: Center(
        child: Consumer<AuthViewModel>(
          builder: (context, vm, _) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.library_books,
                    size: 80, color: Colors.white),
                const SizedBox(height: 24),
                const Text(
                  'Study Docs Cloud',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Quan ly tai lieu hoc tap tren may dam may',
                  style: TextStyle(color: Colors.indigo.shade200),
                ),
                const SizedBox(height: 48),
                if (vm.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      vm.errorMessage!,
                      style: const TextStyle(color: Colors.redAccent),
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (vm.isLoading)
                  const CircularProgressIndicator(color: Colors.white)
                else
                  ElevatedButton.icon(
                    onPressed: () => vm.signIn(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.indigo.shade900,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    icon: Image.network(
                      'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                      height: 24,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.login),
                    ),
                    label: const Text(
                      'Dang nhap bang Google',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
