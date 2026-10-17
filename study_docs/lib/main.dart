import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'features/documents/data/db/app_database.dart';
import 'features/documents/data/repositories/documents_repository_impl.dart';
import 'features/documents/domain/usecases/add_document.dart';
import 'features/documents/domain/usecases/delete_document.dart';
import 'features/documents/domain/usecases/search_documents.dart';
import 'features/documents/domain/usecases/update_document.dart';
import 'features/documents/presentation/pages/documents_list_page.dart';
import 'features/documents/presentation/viewmodels/documents_viewmodel.dart';

void main() {
  runApp(const StudyDocsApp());
}

class StudyDocsApp extends StatelessWidget {
  const StudyDocsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final db = AppDatabase();
    final repository = DocumentsRepositoryImpl(db);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => DocumentsViewModel(
            addDocumentUseCase:     AddDocument(repository),
            updateDocumentUseCase:  UpdateDocument(repository),
            deleteDocumentUseCase:  DeleteDocument(repository),
            searchDocumentsUseCase: SearchDocuments(repository),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Study Docs',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        home: const DocumentsListPage(),
      ),
    );
  }
}
