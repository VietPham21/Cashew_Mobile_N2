import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/responsive.dart';
import '../../../../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../../features/permissions/presentation/widgets/share_dialog.dart';
import '../../../borrow/presentation/pages/borrow_requests_page.dart';
import '../../../borrow/presentation/viewmodels/borrow_viewmodel.dart';
import '../../domain/entities/study_document.dart';
import '../viewmodels/documents_viewmodel.dart';
import 'document_detail_page.dart';
import 'document_form_page.dart';
import 'recommendations_page.dart';

const _canvas = Color(0xFFF4F6F1);
const _ink = Color(0xFF1B2923);
const _muted = Color(0xFF78847D);
const _green = Color(0xFF187E68);

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

  Color _typeColor(DocumentType type) => switch (type) {
    DocumentType.lecture => const Color(0xFF457BC1),
    DocumentType.assignment => const Color(0xFFD37D36),
    DocumentType.reference => const Color(0xFF438A64),
    DocumentType.other => const Color(0xFF8075A8),
  };

  Color _typeSurface(DocumentType type) => switch (type) {
    DocumentType.lecture => const Color(0xFFE8F0FC),
    DocumentType.assignment => const Color(0xFFFFF0E2),
    DocumentType.reference => const Color(0xFFE7F3E9),
    DocumentType.other => const Color(0xFFF0ECF8),
  };

  String _typeLabel(DocumentType type) => switch (type) {
    DocumentType.lecture => 'Bài giảng',
    DocumentType.assignment => 'Bài tập',
    DocumentType.reference => 'Tham khảo',
    DocumentType.other => 'Khác',
  };

  IconData _typeIcon(DocumentType type) => switch (type) {
    DocumentType.lecture => Icons.menu_book_rounded,
    DocumentType.assignment => Icons.assignment_rounded,
    DocumentType.reference => Icons.auto_stories_rounded,
    DocumentType.other => Icons.folder_copy_rounded,
  };

  void _openDetail(
    BuildContext context,
    StudyDocument doc,
    DocumentsViewModel vm,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DocumentDetailPage(
          doc: doc,
          canEdit: vm.canEdit(doc),
          canAccessFile: vm.canAccessFile(doc),
          viewModel: vm,
        ),
      ),
    ).then((_) => vm.loadAll());
  }

  void _openForm(
    BuildContext context,
    DocumentsViewModel vm, {
    StudyDocument? existing,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DocumentFormPage(existing: existing, viewModel: vm),
      ),
    ).then((_) => vm.loadAll());
  }

  void _openRecommendations(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: context.read<DocumentsViewModel>(),
          child: const RecommendationsPage(),
        ),
      ),
    );
  }

  void _openRequests(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: context.read<BorrowViewModel>(),
          child: const BorrowRequestsPage(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final user = authVm.currentUser;

    return Scaffold(
      backgroundColor: _canvas,
      appBar: AppBar(
        toolbarHeight: 72,
        backgroundColor: _canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: Responsive.isMobile(context) ? 16 : 32,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.local_library_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 11),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'study docs',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                Text(
                  'LEARNING LIBRARY',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (!Responsive.isMobile(context)) ...[
            _headerAction(
              icon: Icons.auto_awesome_rounded,
              label: 'Gợi ý',
              onPressed: () => _openRecommendations(context),
            ),
            _headerAction(
              icon: Icons.inbox_rounded,
              label: 'Yêu cầu',
              onPressed: () => _openRequests(context),
            ),
            const SizedBox(width: 12),
          ] else ...[
            IconButton(
              tooltip: 'For You',
              onPressed: () => _openRecommendations(context),
              icon: const Icon(Icons.auto_awesome_rounded),
            ),
            IconButton(
              tooltip: 'Yêu cầu mượn',
              onPressed: () => _openRequests(context),
              icon: const Icon(Icons.inbox_rounded),
            ),
          ],
          if (user?.avatarUrl != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: CircleAvatar(
                radius: 19,
                backgroundColor: const Color(0xFFDCE9E2),
                backgroundImage: NetworkImage(user!.avatarUrl!),
                onBackgroundImageError: (_, __) {},
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: CircleAvatar(
                radius: 19,
                backgroundColor: const Color(0xFFDCE9E2),
                child: Text(
                  _initials(user?.displayName ?? 'U'),
                  style: const TextStyle(
                    color: _green,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: authVm.signOut,
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, viewport) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1320),
            child: SizedBox(
              width: double.infinity,
              height: viewport.maxHeight,
              child: Consumer<DocumentsViewModel>(
                builder: (context, vm, _) {
                  final horizontal = Responsive.isDesktop(context)
                      ? 32.0
                      : 20.0;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontal,
                          8,
                          horizontal,
                          18,
                        ),
                        child: _welcomePanel(context, user?.displayName, vm),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: horizontal),
                        child: _libraryControls(context, vm),
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: _documentCollection(
                          context,
                          vm,
                          user?.id,
                          horizontal,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, context.read<DocumentsViewModel>()),
        backgroundColor: _green,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tạo tài liệu'),
      ),
    );
  }

  Widget _headerAction({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) => TextButton.icon(
    onPressed: onPressed,
    icon: Icon(icon, size: 19),
    label: Text(label),
    style: TextButton.styleFrom(
      foregroundColor: _ink,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      textStyle: const TextStyle(fontWeight: FontWeight.w700),
    ),
  );

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return '${parts.first.characters.first}${parts.last.characters.first}'
        .toUpperCase();
  }

  Widget _welcomePanel(
    BuildContext context,
    String? displayName,
    DocumentsViewModel vm,
  ) {
    final width = MediaQuery.sizeOf(context).width;
    final mobile = width < 600;
    final shortName = (displayName ?? 'bạn').trim().split(RegExp(r'\s+')).last;

    return Container(
      constraints: const BoxConstraints(minHeight: 158),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF174F43), Color(0xFF21856D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF174F43).withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: mobile ? -44 : 135,
            top: -75,
            child: Container(
              width: 210,
              height: 210,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: .10),
                  width: 26,
                ),
              ),
            ),
          ),
          Positioned(
            right: mobile ? 16 : 75,
            bottom: -90,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFD6E779).withValues(alpha: .10),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: mobile ? 20 : 30,
              vertical: 22,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'KHÔNG GIAN HỌC TẬP CỦA BẠN',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .7),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.7,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Chào $shortName 👋',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: mobile ? 25 : 31,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Mọi ý tưởng hay đều bắt đầu từ một ghi chú.',
                        maxLines: mobile ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .78),
                          fontSize: mobile ? 12 : 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _heroStat(
                            Icons.menu_book_rounded,
                            '${vm.myDocuments.length} tài liệu',
                          ),
                          _heroStat(
                            Icons.people_alt_rounded,
                            '${vm.sharedDocuments.length} được chia sẻ',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!mobile) ...[
                  const SizedBox(width: 24),
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD8E982),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .12),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.auto_stories_rounded,
                      color: Color(0xFF174F43),
                      size: 38,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroStat(IconData icon, String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: Colors.white.withValues(alpha: .14)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFFD8E982)),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );

  Widget _libraryControls(BuildContext context, DocumentsViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Thư viện của bạn',
                style: TextStyle(
                  color: _ink,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.5,
                ),
              ),
            ),
            Text(
              '${vm.displayDocuments.length} mục',
              style: const TextStyle(
                color: _muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _searchCtrl,
          onChanged: (value) {
            vm.searchKeyword = value;
            if (value.trim().isEmpty && vm.filterType == null) {
              vm.loadAll();
            } else {
              vm.searchDocs(keyword: value, type: vm.filterType);
            }
          },
          decoration: InputDecoration(
            hintText: 'Tìm theo tên, môn học hoặc ghi chú',
            hintStyle: const TextStyle(color: Color(0xFF9AA49D), fontSize: 14),
            prefixIcon: const Icon(Icons.search_rounded, color: _green),
            suffixIcon: _searchCtrl.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Xóa tìm kiếm',
                    onPressed: () {
                      _searchCtrl.clear();
                      vm.searchKeyword = '';
                      if (vm.filterType == null) {
                        vm.loadAll();
                      } else {
                        vm.searchDocs(keyword: '', type: vm.filterType);
                      }
                      setState(() {});
                    },
                    icon: const Icon(Icons.close_rounded, size: 19),
                  ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE3E8E2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE3E8E2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _green, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _collectionTabs(vm),
        const SizedBox(height: 10),
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _filterChip(
                label: 'Tất cả',
                icon: Icons.grid_view_rounded,
                selected: vm.filterType == null,
                onSelected: () => _applyFilter(vm, null),
              ),
              ...DocumentType.values.map(
                (type) => Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: _filterChip(
                    label: _typeLabel(type),
                    icon: _typeIcon(type),
                    selected: vm.filterType == type,
                    onSelected: () =>
                        _applyFilter(vm, vm.filterType == type ? null : type),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _collectionTabs(DocumentsViewModel vm) => Container(
    height: 48,
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: const Color(0xFFE8ECE6),
      borderRadius: BorderRadius.circular(15),
    ),
    child: Row(
      children: [
        _collectionTab(
          label: 'Của tôi',
          count: vm.myDocuments.length,
          selected: !vm.showShared,
          onTap: () => _switchCollection(vm, false),
        ),
        _collectionTab(
          label: 'Được chia sẻ',
          count: vm.sharedDocuments.length,
          selected: vm.showShared,
          onTap: () => _switchCollection(vm, true),
        ),
      ],
    ),
  );

  Widget _collectionTab({
    required String label,
    required int count,
    required bool selected,
    required VoidCallback onTap,
  }) => Expanded(
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: selected ? _ink : _muted,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 7),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFFE4F1E9) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: selected ? _green : _muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _filterChip({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onSelected,
  }) => ChoiceChip(
    label: Text(label),
    avatar: Icon(icon, size: 15),
    selected: selected,
    onSelected: (_) => onSelected(),
    showCheckmark: false,
    labelStyle: TextStyle(
      color: selected ? Colors.white : const Color(0xFF68746C),
      fontSize: 12,
      fontWeight: FontWeight.w700,
    ),
    avatarBorder: const CircleBorder(),
    backgroundColor: Colors.white,
    selectedColor: _green,
    side: BorderSide(color: selected ? _green : const Color(0xFFE0E6DF)),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
  );

  void _applyFilter(DocumentsViewModel vm, DocumentType? type) {
    vm.filterType = type;
    if (vm.searchKeyword.isEmpty && type == null) {
      vm.loadAll();
    } else {
      vm.searchDocs(keyword: vm.searchKeyword, type: type);
    }
  }

  void _switchCollection(DocumentsViewModel vm, bool showShared) {
    if (vm.showShared == showShared) return;
    vm.toggleShowShared(showShared);
    if (_searchCtrl.text.isNotEmpty || vm.filterType != null) {
      _searchCtrl.clear();
      vm.searchKeyword = '';
      vm.filterType = null;
      vm.loadAll();
    }
  }

  Widget _documentCollection(
    BuildContext context,
    DocumentsViewModel vm,
    String? currentUserId,
    double horizontal,
  ) {
    if (vm.isLoading) {
      return const Center(child: CircularProgressIndicator(color: _green));
    }

    if (vm.errorMessage != null) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: _cardDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 42, color: _green),
              const SizedBox(height: 12),
              const Text(
                'Chưa tải được thư viện',
                style: TextStyle(fontWeight: FontWeight.w800, color: _ink),
              ),
              const SizedBox(height: 5),
              Text(
                vm.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _muted, fontSize: 12),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () {
                  vm.clearError();
                  vm.loadAll();
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Thử tải lại'),
                style: FilledButton.styleFrom(backgroundColor: _green),
              ),
            ],
          ),
        ),
      );
    }

    final isFiltered = vm.searchKeyword.isNotEmpty || vm.filterType != null;
    final docs = isFiltered ? vm.searchResults : vm.displayDocuments;
    if (docs.isEmpty) {
      return _emptyState(context, vm);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final mobile = Responsive.isMobile(context);
        if (mobile) {
          return RefreshIndicator(
            color: _green,
            onRefresh: vm.loadAll,
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(horizontal, 8, horizontal, 105),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 13),
              itemBuilder: (context, index) {
                final doc = docs[index];
                final isOwner = doc.ownerId == currentUserId;
                return _buildCard(context, doc, vm, isOwner);
              },
            ),
          );
        }

        final columns = constraints.maxWidth >= 1050 ? 3 : 2;
        return RefreshIndicator(
          color: _green,
          onRefresh: vm.loadAll,
          child: GridView.builder(
            padding: EdgeInsets.fromLTRB(horizontal, 8, horizontal, 105),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              mainAxisExtent: 246,
            ),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final isOwner = doc.ownerId == currentUserId;
              return _buildCard(context, doc, vm, isOwner);
            },
          ),
        );
      },
    );
  }

  Widget _emptyState(BuildContext context, DocumentsViewModel vm) {
    final filtered = vm.searchKeyword.isNotEmpty || vm.filterType != null;
    final title = filtered
        ? 'Không tìm thấy tài liệu'
        : vm.showShared
        ? 'Chưa có tài liệu được chia sẻ'
        : 'Thư viện đang chờ tài liệu đầu tiên';
    final subtitle = filtered
        ? 'Thử đổi từ khóa hoặc bộ lọc nhé.'
        : vm.showShared
        ? 'Khi có người chia sẻ tài liệu với bạn, chúng sẽ xuất hiện ở đây.'
        : 'Thêm tài liệu, gắn tag và bắt đầu xây dựng kho học tập của bạn.';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: const BoxDecoration(
                color: Color(0xFFE4EFE7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_stories_rounded,
                size: 38,
                color: _green,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _ink,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 390),
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _muted, height: 1.5),
              ),
            ),
            if (!vm.showShared && !filtered) ...[
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () => _openForm(context, vm),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Tạo tài liệu đầu tiên'),
                style: FilledButton.styleFrom(
                  backgroundColor: _green,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 13,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    StudyDocument doc,
    DocumentsViewModel vm,
    bool isOwner,
  ) {
    final color = _typeColor(doc.type);
    final userCanEdit = vm.canEdit(doc);
    final date = DateFormat('d MMM yyyy').format(doc.updatedAt);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(21),
        side: const BorderSide(color: Color(0xFFE5EAE3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openDetail(context, doc, vm),
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _typeSurface(doc.type),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(_typeIcon(doc.type), color: color, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: _typeSurface(doc.type),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        _typeLabel(doc.type),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _visibilityBadge(doc.isPublic),
                  if (isOwner)
                    PopupMenuButton<String>(
                      tooltip: 'Tùy chọn tài liệu',
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.more_horiz_rounded, color: _muted),
                      onSelected: (value) =>
                          _handleDocumentAction(context, value, doc, vm),
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            leading: Icon(Icons.edit_outlined),
                            title: Text('Chỉnh sửa'),
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),
                        ),
                        PopupMenuItem(
                          value: 'share',
                          child: ListTile(
                            leading: Icon(Icons.ios_share_rounded),
                            title: Text('Chia sẻ quyền'),
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.red,
                            ),
                            title: Text(
                              'Xóa tài liệu',
                              style: TextStyle(color: Colors.red),
                            ),
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),
                        ),
                      ],
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Tooltip(
                        message: userCanEdit
                            ? 'Có quyền chỉnh sửa'
                            : 'Có quyền xem',
                        child: Icon(
                          userCanEdit
                              ? Icons.edit_note_rounded
                              : Icons.visibility_rounded,
                          size: 18,
                          color: userCanEdit ? const Color(0xFFD37D36) : _green,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 13),
              Text(
                doc.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 17,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.3,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.school_rounded, size: 15, color: _muted),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      doc.course.isEmpty
                          ? 'Chưa phân loại môn học'
                          : doc.course,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (doc.tags.isNotEmpty)
                Wrap(
                  spacing: 6,
                  runSpacing: 5,
                  children: doc.tags.take(3).map(_tagPill).toList(),
                )
              else
                const SizedBox(height: 25),
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFE9EDE8)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    doc.hasFile
                        ? Icons.attach_file_rounded
                        : Icons.schedule_rounded,
                    size: 15,
                    color: _green,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      doc.hasFile && vm.canAccessFile(doc)
                          ? doc.fileName
                          : doc.locationName ?? 'Cập nhật $date',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF6F7C73),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_outward_rounded,
                    size: 15,
                    color: _muted,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _visibilityBadge(bool isPublic) => Container(
    width: 31,
    height: 31,
    decoration: BoxDecoration(
      color: isPublic ? const Color(0xFFE7F3E9) : const Color(0xFFF0F1EE),
      shape: BoxShape.circle,
    ),
    child: Tooltip(
      message: isPublic ? 'Công khai' : 'Riêng tư',
      child: Icon(
        isPublic ? Icons.public_rounded : Icons.lock_outline_rounded,
        color: isPublic ? _green : const Color(0xFF758078),
        size: 15,
      ),
    ),
  );

  Widget _tagPill(String tag) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xFFF1F4EF),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Text(
      '#$tag',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Color(0xFF607067),
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: const Color(0xFFE5EAE3)),
  );

  Future<void> _handleDocumentAction(
    BuildContext context,
    String value,
    StudyDocument doc,
    DocumentsViewModel vm,
  ) async {
    if (value == 'edit') {
      _openForm(context, vm, existing: doc);
    } else if (value == 'share') {
      showDialog<void>(
        context: context,
        builder: (_) => ShareDialog(
          documentId: doc.id,
          ownerId: doc.ownerId,
          documentTitle: doc.title,
        ),
      );
    } else if (value == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Xóa tài liệu?'),
          content: Text('“${doc.title}” sẽ bị xóa khỏi thư viện.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Giữ lại'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade700,
              ),
              child: const Text('Xóa'),
            ),
          ],
        ),
      );
      if (confirmed == true) await vm.delete(doc.id);
    }
  }
}
