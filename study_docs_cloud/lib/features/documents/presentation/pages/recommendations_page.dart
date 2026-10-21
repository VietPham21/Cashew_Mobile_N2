import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/responsive.dart';
import '../../domain/entities/study_document.dart';
import '../viewmodels/documents_viewmodel.dart';
import 'document_detail_page.dart';

class RecommendationsPage extends StatefulWidget {
  const RecommendationsPage({super.key});

  @override
  State<RecommendationsPage> createState() => _RecommendationsPageState();
}

class _RecommendationsPageState extends State<RecommendationsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DocumentsViewModel>().loadAll();
    });
  }

  Color _typeColor(DocumentType t) {
    switch (t) {
      case DocumentType.lecture:
        return Colors.blue;
      case DocumentType.assignment:
        return Colors.orange;
      case DocumentType.reference:
        return Colors.green;
      case DocumentType.other:
        return Colors.grey;
    }
  }

  IconData _typeIcon(DocumentType t) {
    switch (t) {
      case DocumentType.lecture:
        return Icons.menu_book;
      case DocumentType.assignment:
        return Icons.assignment;
      case DocumentType.reference:
        return Icons.library_books;
      case DocumentType.other:
        return Icons.folder;
    }
  }

  Widget _buildDocCard(
    BuildContext context,
    StudyDocument doc,
    DocumentsViewModel vm,
  ) {
    final color = _typeColor(doc.type);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DocumentDetailPage(
                doc: doc,
                canEdit: false,
                canAccessFile: vm.canAccessFile(doc),
                viewModel: vm,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_typeIcon(doc.type), color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      doc.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (doc.course.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        doc.course,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (doc.tags.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        children: doc.tags
                            .map(
                              (t) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '#$t',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('For You')),
      body: Consumer<DocumentsViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (vm.recommendations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 72,
                    color: Theme.of(context).colorScheme.primary
                        .withValues(alpha: 0.35),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No recommendations yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Add tags to your documents so we can suggest relevant public documents from other users.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            );
          }

          final isMobile = Responsive.isMobile(context);
          final columns = Responsive.gridColumns(context);
          final pad = Responsive.padding(context);

          return Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: Theme.of(context).colorScheme.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Based on your tags — ${vm.recommendations.length} suggestions',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              // List or Grid
              Expanded(
                child: RefreshIndicator(
                  onRefresh: vm.loadAll,
                  child: isMobile
                      ? ListView.separated(
                          padding: EdgeInsets.all(pad),
                          itemCount: vm.recommendations.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, i) =>
                              _buildDocCard(context, vm.recommendations[i], vm),
                        )
                      : GridView.builder(
                          padding: EdgeInsets.all(pad),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 2.2,
                              ),
                          itemCount: vm.recommendations.length,
                          itemBuilder: (context, i) =>
                              _buildDocCard(context, vm.recommendations[i], vm),
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
