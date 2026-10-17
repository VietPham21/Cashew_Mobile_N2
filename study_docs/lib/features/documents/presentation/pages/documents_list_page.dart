import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/study_document.dart';
import '../viewmodels/documents_viewmodel.dart';
import 'document_form_page.dart';

class DocumentsListPage extends StatefulWidget {
  const DocumentsListPage({super.key});

  @override
  State<DocumentsListPage> createState() => _DocumentsListPageState();
}

class _DocumentsListPageState extends State<DocumentsListPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DocumentsViewModel>().loadDocuments();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _typeColor(DocumentType type) {
    switch (type) {
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

  String _typeLabel(DocumentType type) {
    switch (type) {
      case DocumentType.lecture:
        return 'Bai giang';
      case DocumentType.assignment:
        return 'Bai tap';
      case DocumentType.reference:
        return 'Tai lieu';
      case DocumentType.other:
        return 'Khac';
    }
  }

  IconData _typeIcon(DocumentType type) {
    switch (type) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tai lieu hoc tap'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterChips(),
          Expanded(child: _buildDocumentList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DocumentFormPage()),
          );
          if (mounted) {
            context.read<DocumentsViewModel>().loadDocuments();
          }
        },
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Them tai lieu'),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.indigo,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Tim kiem tai lieu...',
          hintStyle: const TextStyle(color: Colors.white70),
          prefixIcon: const Icon(Icons.search, color: Colors.white70),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear, color: Colors.white70),
            onPressed: () {
              _searchController.clear();
              context.read<DocumentsViewModel>().setFilter(keyword: '');
            },
          ),
          filled: true,
          fillColor: Colors.indigo.shade700,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (value) {
          context.read<DocumentsViewModel>().setFilter(keyword: value);
        },
      ),
    );
  }

  Widget _buildFilterChips() {
    return Consumer<DocumentsViewModel>(
      builder: (context, vm, _) {
        return SizedBox(
          height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: [
              FilterChip(
                label: const Text('Tat ca'),
                selected: vm.filterType == null,
                onSelected: (_) => vm.setFilter(type: null),
              ),
              const SizedBox(width: 8),
              ...DocumentType.values.map(
                (type) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    avatar: Icon(_typeIcon(type), size: 16),
                    label: Text(_typeLabel(type)),
                    selected: vm.filterType == type,
                    selectedColor: _typeColor(type).withValues(alpha: 0.2),
                    onSelected: (_) => vm.setFilter(
                      type: vm.filterType == type ? null : type,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDocumentList() {
    return Consumer<DocumentsViewModel>(
      builder: (context, vm, _) {
        if (vm.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (vm.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    size: 48, color: Colors.red),
                const SizedBox(height: 8),
                Text(vm.errorMessage!),
                TextButton(
                  onPressed: () {
                    vm.clearError();
                    vm.loadDocuments();
                  },
                  child: const Text('Thu lai'),
                ),
              ],
            ),
          );
        }

        if (vm.documents.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.folder_open,
                    size: 72, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text(
                  'Chua co tai lieu nao',
                  style: TextStyle(
                      color: Colors.grey.shade600, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  'Nhan + de them tai lieu moi',
                  style: TextStyle(color: Colors.grey.shade400),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: vm.documents.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final doc = vm.documents[index];
            return _DocumentCard(
              doc: doc,
              typeColor: _typeColor(doc.type),
              typeLabel: _typeLabel(doc.type),
              typeIcon: _typeIcon(doc.type),
              onEdit: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DocumentFormPage(existing: doc),
                  ),
                );
                vm.loadDocuments();
              },
              onDelete: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Xac nhan xoa'),
                    content: Text('Xoa "${doc.title}"?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Huy'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(
                            foregroundColor: Colors.red),
                        child: const Text('Xoa'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  vm.delete(doc.id);
                }
              },
            );
          },
        );
      },
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final StudyDocument doc;
  final Color typeColor;
  final String typeLabel;
  final IconData typeIcon;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DocumentCard({
    required this.doc,
    required this.typeColor,
    required this.typeLabel,
    required this.typeIcon,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(doc.updatedAt);

    return Card(
      elevation: 2,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(typeIcon, color: typeColor, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.school,
                            size: 13, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            doc.course,
                            style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: typeColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            typeLabel,
                            style: TextStyle(
                                color: typeColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    if (doc.tags.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        children: doc.tags
                            .take(3)
                            .map((t) => Chip(
                                  label: Text(t,
                                      style:
                                          const TextStyle(fontSize: 10)),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  padding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                ))
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 2),
                    Text(
                      'Cap nhat: $dateStr',
                      style: TextStyle(
                          color: Colors.grey.shade400, fontSize: 11),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (val) {
                  if (val == 'edit') onEdit();
                  if (val == 'delete') onDelete();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(children: [
                      Icon(Icons.edit, size: 18),
                      SizedBox(width: 8),
                      Text('Sua'),
                    ]),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [
                      Icon(Icons.delete, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Xoa',
                          style: TextStyle(color: Colors.red)),
                    ]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
