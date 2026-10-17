import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/study_document.dart';
import '../viewmodels/documents_viewmodel.dart';
import '../../../../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../../features/permissions/presentation/widgets/share_dialog.dart';
import 'document_detail_page.dart';
import 'document_form_page.dart';

class DocumentsListPage extends StatefulWidget {
  const DocumentsListPage({super.key});

  @override
  State<DocumentsListPage> createState() => _DocumentsListPageState();
}

class _DocumentsListPageState extends State<DocumentsListPage> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DocumentsViewModel>().loadAll();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Color _typeColor(DocumentType t) {
    switch (t) {
      case DocumentType.lecture:    return Colors.blue;
      case DocumentType.assignment: return Colors.orange;
      case DocumentType.reference:  return Colors.green;
      case DocumentType.other:      return Colors.grey;
    }
  }

  String _typeLabel(DocumentType t) {
    switch (t) {
      case DocumentType.lecture:    return 'Bai giang';
      case DocumentType.assignment: return 'Bai tap';
      case DocumentType.reference:  return 'Tai lieu';
      case DocumentType.other:      return 'Khac';
    }
  }

  IconData _typeIcon(DocumentType t) {
    switch (t) {
      case DocumentType.lecture:    return Icons.menu_book;
      case DocumentType.assignment: return Icons.assignment;
      case DocumentType.reference:  return Icons.library_books;
      case DocumentType.other:      return Icons.folder;
    }
  }

  void _openDetail(BuildContext context, StudyDocument doc,
      DocumentsViewModel vm) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DocumentDetailPage(
          doc: doc,
          canEdit: vm.canEdit(doc),
          viewModel: vm,
        ),
      ),
    ).then((_) => vm.loadAll());
  }

  void _openForm(BuildContext context, DocumentsViewModel vm,
      {StudyDocument? existing}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DocumentFormPage(
          existing: existing,
          viewModel: vm,
        ),
      ),
    ).then((_) => vm.loadAll());
  }

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Docs Cloud'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          if (authVm.currentUser?.avatarUrl != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: CircleAvatar(
                radius: 16,
                backgroundImage:
                    NetworkImage(authVm.currentUser!.avatarUrl!),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Dang xuat',
            onPressed: () => authVm.signOut(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: Colors.indigo,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Tim kiem tai lieu...',
                hintStyle: const TextStyle(color: Colors.white70),
                prefixIcon:
                    const Icon(Icons.search, color: Colors.white70),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white70),
                  onPressed: () {
                    _searchCtrl.clear();
                    context.read<DocumentsViewModel>().loadAll();
                  },
                ),
                filled: true,
                fillColor: Colors.indigo.shade700,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => context
                  .read<DocumentsViewModel>()
                  .searchDocs(keyword: v),
            ),
          ),

          // Tab
          Consumer<DocumentsViewModel>(
            builder: (context, vm, _) => Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => vm.toggleShowShared(false),
                    style: TextButton.styleFrom(
                      foregroundColor: !vm.showShared
                          ? Colors.indigo
                          : Colors.grey,
                      backgroundColor: !vm.showShared
                          ? Colors.indigo.shade50
                          : null,
                    ),
                    child:
                        Text('Cua toi (${vm.myDocuments.length})'),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: () => vm.toggleShowShared(true),
                    style: TextButton.styleFrom(
                      foregroundColor:
                          vm.showShared ? Colors.indigo : Colors.grey,
                      backgroundColor: vm.showShared
                          ? Colors.indigo.shade50
                          : null,
                    ),
                    child: Text(
                        'Duoc chia se (${vm.sharedDocuments.length})'),
                  ),
                ),
              ],
            ),
          ),

          // Filter chips
          Consumer<DocumentsViewModel>(
            builder: (context, vm, _) => SizedBox(
              height: 46,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                children: [
                  FilterChip(
                    label: const Text('Tat ca'),
                    selected: vm.filterType == null,
                    onSelected: (_) {
                      vm.filterType = null;
                      vm.loadAll();
                    },
                  ),
                  const SizedBox(width: 8),
                  ...DocumentType.values.map((t) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          avatar: Icon(_typeIcon(t), size: 14),
                          label: Text(_typeLabel(t)),
                          selected: vm.filterType == t,
                          onSelected: (_) {
                            vm.filterType =
                                vm.filterType == t ? null : t;
                            vm.searchDocs(type: vm.filterType);
                          },
                        ),
                      )),
                ],
              ),
            ),
          ),

          // List
          Expanded(
            child: Consumer<DocumentsViewModel>(
              builder: (context, vm, _) {
                if (vm.isLoading) {
                  return const Center(
                      child: CircularProgressIndicator());
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
                            vm.loadAll();
                          },
                          child: const Text('Thu lai'),
                        ),
                      ],
                    ),
                  );
                }

                final docs = vm.searchKeyword.isNotEmpty
                    ? vm.searchResults
                    : vm.displayDocuments;

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.folder_open,
                            size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          vm.showShared
                              ? 'Chua co tai lieu duoc chia se'
                              : 'Chua co tai lieu nao',
                          style: TextStyle(
                              color: Colors.grey.shade600),
                        ),
                        if (!vm.showShared)
                          Text('Nhan + de them tai lieu moi',
                              style: TextStyle(
                                  color: Colors.grey.shade400)),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: vm.loadAll,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final doc = docs[i];
                      final isOwner =
                          doc.ownerId == authVm.currentUser?.id;
                      return _buildCard(
                          context, doc, vm, isOwner);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Consumer<DocumentsViewModel>(
        builder: (context, vm, _) => FloatingActionButton.extended(
          onPressed: () => _openForm(context, vm),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('Them tai lieu'),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, StudyDocument doc,
      DocumentsViewModel vm, bool isOwner) {
    final color = _typeColor(doc.type);
    final date =
        DateFormat('dd/MM/yyyy HH:mm').format(doc.updatedAt);
    final userCanEdit = vm.canEdit(doc);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        // TAT CA card deu click duoc de xem chi tiet
        onTap: () => _openDetail(context, doc, vm),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_typeIcon(doc.type), color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            doc.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (doc.isPublic)
                          const Icon(Icons.public,
                              size: 14, color: Colors.green),
                        if (!isOwner)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Icon(
                              userCanEdit
                                  ? Icons.edit
                                  : Icons.visibility,
                              size: 14,
                              color: userCanEdit
                                  ? Colors.orange
                                  : Colors.blue,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.school,
                            size: 12, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            doc.course,
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _typeLabel(doc.type),
                            style: TextStyle(
                                color: color,
                                fontSize: 10,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    if (doc.hasFile)
                      Row(
                        children: [
                          Icon(Icons.attach_file,
                              size: 12,
                              color: Colors.grey.shade400),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              doc.fileName,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade400),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    Text(
                      date,
                      style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade400),
                    ),
                  ],
                ),
              ),

              // Menu 3 cham: chi chu so huu moi co
              if (isOwner)
                PopupMenuButton<String>(
                  onSelected: (val) async {
                    if (val == 'edit') {
                      _openForm(context, vm, existing: doc);
                    } else if (val == 'share') {
                      showDialog(
                        context: context,
                        builder: (_) => ShareDialog(
                          documentId: doc.id,
                          ownerId: doc.ownerId,
                          documentTitle: doc.title,
                        ),
                      );
                    } else if (val == 'delete') {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Xac nhan xoa'),
                          content: Text('Xoa "${doc.title}"?'),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(context, false),
                              child: const Text('Huy'),
                            ),
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(context, true),
                              style: TextButton.styleFrom(
                                  foregroundColor: Colors.red),
                              child: const Text('Xoa'),
                            ),
                          ],
                        ),
                      );
                      if (ok == true) vm.delete(doc.id);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(children: [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 8),
                        Text('Sua'),
                      ]),
                    ),
                    const PopupMenuItem(
                      value: 'share',
                      child: Row(children: [
                        Icon(Icons.share,
                            size: 18, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Chia se',
                            style: TextStyle(color: Colors.blue)),
                      ]),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        Icon(Icons.delete,
                            size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Xoa',
                            style: TextStyle(color: Colors.red)),
                      ]),
                    ),
                  ],
                )
              else
                // Nguoi duoc chia se: hien icon quyen
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Tooltip(
                    message: userCanEdit
                        ? 'Co quyen chinh sua'
                        : 'Chi duoc xem',
                    child: Icon(
                      userCanEdit ? Icons.edit_note : Icons.lock,
                      color: userCanEdit
                          ? Colors.orange.shade300
                          : Colors.grey.shade400,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
