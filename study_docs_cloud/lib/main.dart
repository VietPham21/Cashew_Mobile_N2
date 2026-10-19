import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import 'core/constants/supabase_constants.dart';
import 'core/services/notification_service.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/usecases/sign_in_google.dart';
import 'features/auth/domain/usecases/sign_out.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'features/documents/data/repositories/documents_repository_impl.dart';
import 'features/documents/presentation/pages/documents_list_page.dart';
import 'features/documents/presentation/viewmodels/documents_viewmodel.dart';
import 'features/borrow/data/repositories/borrow_repository_impl.dart';
import 'features/borrow/presentation/viewmodels/borrow_viewmodel.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Supabase.initialize(
    url: SupabaseConstants.supabaseUrl,
    anonKey: SupabaseConstants.supabaseAnonKey,
    accessToken: () async {
      try {
        return await FirebaseAuth.instance.currentUser?.getIdToken(false);
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

class _AppRouter extends StatefulWidget {
  const _AppRouter();

  @override
  State<_AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<_AppRouter> {
  bool _fcmReady = false;

  Future<void> _setupFcm(String userId) async {
    if (_fcmReady) return;
    _fcmReady = true;
    try {
      final token = await NotificationService.initialize();
      if (token != null) {
        await NotificationService.saveToken(userId, token);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, authVm, _) {
        if (authVm.currentUser == null) {
          _fcmReady = false;
          return const LoginPage();
        }

        final userId = authVm.currentUser!.id;
        final supabase = Supabase.instance.client;

        // Setup FCM sau khi login
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _setupFcm(userId);
        });

        return MultiProvider(
          key: ValueKey(userId),
          providers: [
            ChangeNotifierProvider(
              create: (_) => DocumentsViewModel(
                repository: DocumentsRepositoryImpl(
                  supabase: supabase,
                  currentUserId: userId,
                ),
                currentUserId: userId,
              ),
            ),
            ChangeNotifierProvider(
              create: (_) => BorrowViewModel(
                repository: BorrowRepositoryImpl(
                  supabase: supabase,
                  currentUserId: userId,
                ),
              ),
            ),
          ],
          child: const DocumentsListPage(),
        );
      },
    );
  }
}
