import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import 'core/constants/supabase_constants.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/usecases/sign_in_google.dart';
import 'features/auth/domain/usecases/sign_out.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'features/documents/data/repositories/documents_repository_impl.dart';
import 'features/documents/presentation/pages/documents_list_page.dart';
import 'features/documents/presentation/viewmodels/documents_viewmodel.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Supabase dung Firebase token qua accessToken callback
  await Supabase.initialize(
    url: SupabaseConstants.supabaseUrl,
    anonKey: SupabaseConstants.supabaseAnonKey,
    accessToken: () async {
      try {
        final token = await FirebaseAuth.instance.currentUser
            ?.getIdToken(false);
        return token;
      } catch (_) {
        return null;
      }
    },
  );

  runApp(const StudyDocsApp());
}

class StudyDocsApp extends StatelessWidget {
  const StudyDocsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepo = AuthRepositoryImpl(
      firebaseAuth: FirebaseAuth.instance,
      supabase: Supabase.instance.client,
    );

    return ChangeNotifierProvider(
      create: (_) => AuthViewModel(
        signInUseCase: SignInWithGoogle(authRepo),
        signOutUseCase: SignOut(authRepo),
      ),
      child: MaterialApp(
        title: 'Study Docs Cloud',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        home: const _AppRouter(),
      ),
    );
  }
}

class _AppRouter extends StatelessWidget {
  const _AppRouter();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, authVm, _) {
        if (authVm.currentUser == null) {
          return const LoginPage();
        }

        final userId = authVm.currentUser!.id;

        return ChangeNotifierProvider(
          key: ValueKey(userId),
          create: (_) => DocumentsViewModel(
            repository: DocumentsRepositoryImpl(
              supabase: Supabase.instance.client,
              currentUserId: userId,
            ),
            currentUserId: userId,
          ),
          child: const DocumentsListPage(),
        );
      },
    );
  }
}
