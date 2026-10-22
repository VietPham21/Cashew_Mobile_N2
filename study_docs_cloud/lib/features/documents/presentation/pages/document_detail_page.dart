import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/study_document.dart';
import '../viewmodels/documents_viewmodel.dart';
import 'document_form_page.dart';
import '../../../borrow/presentation/viewmodels/borrow_viewmodel.dart';

class DocumentDetailPage extends StatefulWidget {
  final StudyDocument doc;
  final bool canEdit;
  final bool canAccessFile;
  final DocumentsViewModel viewModel;

  const DocumentDetailPage({
    super.key,
    required this.doc,
    required this.canEdit,
    required this.canAccessFile,
    required this.viewModel,
  });

  @override
  State<DocumentDetailPage> createState() => _DocumentDetailPageState();
}

class _DocumentDetailPageState extends State<DocumentDetailPage> {
  bool _hasRequested = false;
  bool _checkingStatus = true;
  bool _sendingRequest = false;
  bool _isOwner = false;
  String? _statusCheckError;

  @override
  void initState() {
    super.initState();
    _checkBorrowStatus();
  }

  Future<void> _checkBorrowStatus() async {
    _isOwner = widget.doc.ownerId == widget.viewModel.currentUserId;
    try {
      if (!_isOwner) {
        final vm = context.read<BorrowViewModel>();
        final already = await vm.hasRequested(widget.doc.id);
        if (mounted) setState(() => _hasRequested = already);
      }
    } catch (e) {
      // A failed status lookup must not hide the request action forever.
      if (mounted) setState(() => _statusCheckError = e.toString());
    } finally {
      if (mounted) setState(() => _checkingStatus = false);
    }
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

  String _typeLabel(DocumentType t) {
    switch (t) {
      case DocumentType.lecture:
        return 'Bai giang';
      case DocumentType.assignment:
        return 'Bai tap';
      case DocumentType.reference:
        return 'Tai lieu tham khao';
      case DocumentType.other:
        return 'Khac';
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

  Future<void> _showBorrowDialog() async {
    final msgCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.library_books, color: Color(0xFF245B45)),
            SizedBox(width: 8),
            Text('Request to Borrow'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.doc.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: msgCtrl,
              decoration: const InputDecoration(
                labelText: 'Message (optional)',
                hintText: 'e.g. I need this for my research...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.send),
            label: const Text('Send Request'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF245B45),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _sendingRequest = true);
      final vm = context.read<BorrowViewModel>();
      final ok = await vm.sendRequest(
        documentId: widget.doc.id,
        ownerId: widget.doc.ownerId,
        message: msgCtrl.text.trim().isEmpty ? null : msgCtrl.text.trim(),
      );
      if (mounted) {
        setState(() => _sendingRequest = false);
        if (ok) {
          setState(() => _hasRequested = true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF187E68),
              duration: const Duration(seconds: 4),
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Đã gửi yêu cầu mượn “${widget.doc.title}” thành công.',
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          final error = vm.errorMessage ?? 'Lỗi không xác định';
          final friendlyError = error.contains('42501')
              ? 'Supabase từ chối yêu cầu theo chính sách RLS. Kiểm tra quyền INSERT của borrow_requests và hồ sơ người dùng.'
              : error.contains('23505')
              ? 'Bạn đã gửi yêu cầu mượn tài liệu này rồi.'
              : error;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Không gửi được yêu cầu: $friendlyError'),
              backgroundColor: Colors.red.shade700,
              duration: const Duration(seconds: 6),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(widget.doc.type);
    final dateCreated = DateFormat('dd/MM/yyyy HH:mm')
        .format(widget.doc.createdAt);
    final dateUpdated = DateFormat('dd/MM/yyyy HH:mm')
        .format(widget.doc.updatedAt);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiet tai lieu'),
        actions: [
          if (widget.canEdit)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Chinh sua',
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DocumentFormPage(
                      existing: widget.doc,
                      viewModel: widget.viewModel,
                    ),
                  ),
                );
              },
            ),
        ],
      ),

      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_typeIcon(widget.doc.type), color: color, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.doc.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _typeLabel(widget.doc.type),
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (!_checkingStatus && !_isOwner) ...[
            if (widget.canAccessFile)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: const Text(
                  'You have permission to view and download this file.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else if (_hasRequested)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.hourglass_empty, color: Colors.orange, size: 18),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Borrow request sent — waiting for approval',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_statusCheckError != null) ...[
                    Text(
                      'Could not check previous requests. You can still try sending one.',
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  ElevatedButton.icon(
                    onPressed: _sendingRequest ? null : _showBorrowDialog,
                    icon: _sendingRequest
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.library_books),
                    label: Text(
                      _sendingRequest
                          ? 'Đang gửi yêu cầu...'
                          : 'Request to Borrow',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF245B45),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 24),
          ],

          // Quyen truy cap
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.canEdit
                  ? Colors.green.shade50
                  : widget.canAccessFile
                  ? Colors.blue.shade50
                  : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: widget.canEdit
                    ? Colors.green.shade200
                    : widget.canAccessFile
                    ? Colors.blue.shade200
                    : Colors.orange.shade200,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  widget.canEdit ? Icons.edit : Icons.visibility,
                  color: widget.canEdit
                      ? Colors.green
                      : widget.canAccessFile
                      ? Colors.blue
                      : Colors.orange,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.canEdit
                      ? 'Ban co quyen chinh sua tai lieu nay'
                      : widget.canAccessFile
                      ? 'Ban co quyen xem va tai file'
                      : 'Metadata cong khai; xin muon de xem/tai file',
                  style: TextStyle(
                    color: widget.canEdit
                        ? Colors.green.shade700
                        : widget.canAccessFile
                        ? Colors.blue.shade700
                        : Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Thong tin chi tiet
          _buildInfoRow(Icons.school, 'Mon hoc', widget.doc.course),
          const Divider(height: 24),

          if (widget.doc.notes.isNotEmpty) ...[
            _buildInfoRow(Icons.notes, 'Ghi chu', widget.doc.notes),
            const Divider(height: 24),
          ],

          if (widget.doc.tags.isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.tag, color: Colors.grey, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tags',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        children: widget.doc.tags
                            .map(
                              (t) => Chip(
                                label: Text(
                                  t,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
          ],

          // Location
          if (widget.doc.latitude != null && widget.doc.longitude != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on, color: Colors.red, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Vi tri tai lieu',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      if (widget.doc.locationName != null &&
                          widget.doc.locationName!.isNotEmpty)
                        Text(
                          widget.doc.locationName!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      Text(
                        'Lat: ${widget.doc.latitude!.toStringAsFixed(5)}, Lng: ${widget.doc.longitude!.toStringAsFixed(5)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
          ],

          // File dinh kem
          if (widget.doc.hasFile && widget.canAccessFile) ...[
            Row(
              children: [
                const Icon(Icons.attach_file, color: Colors.grey, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'File dinh kem',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.doc.fileName,
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        '${(widget.doc.fileSize / 1024).toStringAsFixed(1)} KB',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      final fileUrl = await widget.viewModel
                          .createFileSignedUrl(widget.doc.filePath);
                      final uri = Uri.parse(fileUrl);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Không thể mở file: $e')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('Mo file'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF245B45),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
          ],

          // Thoi gian
          _buildInfoRow(Icons.access_time, 'Ngay tao', dateCreated),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.update, 'Cap nhat lan cuoi', dateUpdated),
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.public,
            'Trang thai',
            widget.doc.isPublic ? 'Cong khai' : 'Chi minh toi',
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.grey, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }
}
