import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/study_document.dart';
import '../viewmodels/documents_viewmodel.dart';
import 'document_form_page.dart';

class DocumentDetailPage extends StatelessWidget {
  final StudyDocument doc;
  final bool canEdit;
  final DocumentsViewModel viewModel;

  const DocumentDetailPage({
    super.key,
    required this.doc,
    required this.canEdit,
    required this.viewModel,
  });

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
      case DocumentType.reference:  return 'Tai lieu tham khao';
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

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(doc.type);
    final dateCreated =
        DateFormat('dd/MM/yyyy HH:mm').format(doc.createdAt);
    final dateUpdated =
        DateFormat('dd/MM/yyyy HH:mm').format(doc.updatedAt);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiet tai lieu'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          if (canEdit)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Chinh sua',
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DocumentFormPage(
                      existing: doc,
                      viewModel: viewModel,
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
                child: Icon(_typeIcon(doc.type), color: color, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc.title,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _typeLabel(doc.type),
                        style: TextStyle(
                            color: color, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Quyen truy cap
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: canEdit
                  ? Colors.green.shade50
                  : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: canEdit
                    ? Colors.green.shade200
                    : Colors.blue.shade200,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  canEdit ? Icons.edit : Icons.visibility,
                  color: canEdit ? Colors.green : Colors.blue,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  canEdit
                      ? 'Ban co quyen chinh sua tai lieu nay'
                      : 'Ban co quyen xem tai lieu nay',
                  style: TextStyle(
                    color: canEdit
                        ? Colors.green.shade700
                        : Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Thong tin chi tiet
          _buildInfoRow(Icons.school, 'Mon hoc', doc.course),
          const Divider(height: 24),

          if (doc.notes.isNotEmpty) ...[
            _buildInfoRow(Icons.notes, 'Ghi chu', doc.notes),
            const Divider(height: 24),
          ],

          if (doc.tags.isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.tag, color: Colors.grey, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tags',
                          style: TextStyle(
                              color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        children: doc.tags
                            .map((t) => Chip(
                                  label: Text(t,
                                      style: const TextStyle(
                                          fontSize: 12)),
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
          ],

          // File dinh kem
          if (doc.hasFile) ...[
            Row(
              children: [
                const Icon(Icons.attach_file,
                    color: Colors.grey, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('File dinh kem',
                          style: TextStyle(
                              color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(doc.fileName,
                          style: const TextStyle(fontSize: 14)),
                      Text(
                        '${(doc.fileSize / 1024).toStringAsFixed(1)} KB',
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final uri = Uri.parse(doc.fileUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('Mo file'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
          ],

          // Thoi gian
          _buildInfoRow(
              Icons.access_time, 'Ngay tao', dateCreated),
          const SizedBox(height: 8),
          _buildInfoRow(
              Icons.update, 'Cap nhat lan cuoi', dateUpdated),
          const SizedBox(height: 8),
          _buildInfoRow(
              Icons.public,
              'Trang thai',
              doc.isPublic ? 'Cong khai' : 'Chi minh toi'),
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
              Text(label,
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }
}
