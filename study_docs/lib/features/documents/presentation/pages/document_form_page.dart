import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/study_document.dart';
import '../viewmodels/documents_viewmodel.dart';
import '../../../../core/utils/uuid_generator.dart';

class DocumentFormPage extends StatefulWidget {
  final StudyDocument? existing;
  const DocumentFormPage({super.key, this.existing});

  @override
  State<DocumentFormPage> createState() => _DocumentFormPageState();
}

class _DocumentFormPageState extends State<DocumentFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _courseCtrl;
  late TextEditingController _notesCtrl;
  late TextEditingController _tagsCtrl;
  DocumentType _selectedType = DocumentType.lecture;
  bool _isSubmitting = false;

  bool get isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final d = widget.existing;
    _titleCtrl  = TextEditingController(text: d?.title ?? '');
    _courseCtrl = TextEditingController(text: d?.course ?? '');
    _notesCtrl  = TextEditingController(text: d?.notes ?? '');
    _tagsCtrl   = TextEditingController(text: d?.tags.join(', ') ?? '');
    _selectedType = d?.type ?? DocumentType.lecture;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _courseCtrl.dispose();
    _notesCtrl.dispose();
    _tagsCtrl.dispose();
    super.dispose();
  }

  String _typeLabel(DocumentType t) {
    switch (t) {
      case DocumentType.lecture:    return 'Bài giảng';
      case DocumentType.assignment: return 'Bài tập';
      case DocumentType.reference:  return 'Tài liệu tham khảo';
      case DocumentType.other:      return 'Khác';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final tags = _tagsCtrl.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final now = DateTime.now();
    final vm = context.read<DocumentsViewModel>();
    bool success;

    if (isEditing) {
      final updated = widget.existing!.copyWith(
        title: _titleCtrl.text.trim(),
        type: _selectedType,
        course: _courseCtrl.text.trim(),
        tags: tags,
        notes: _notesCtrl.text.trim(),
      );
      success = await vm.update(updated);
    } else {
      final newDoc = StudyDocument(
        id: UuidGenerator.generate(),
        title: _titleCtrl.text.trim(),
        type: _selectedType,
        course: _courseCtrl.text.trim(),
        tags: tags,
        notes: _notesCtrl.text.trim(),
        createdAt: now,
        updatedAt: now,
      );
      success = await vm.add(newDoc);
    }

    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(vm.errorMessage ?? 'Có lỗi xảy ra'),
            backgroundColor: Colors.red),
      );
    }
    setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? '✏️ Sửa tài liệu' : '➕ Thêm tài liệu'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Tiêu đề *',
                prefixIcon: Icon(Icons.title),
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tiêu đề' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _courseCtrl,
              decoration: const InputDecoration(
                labelText: 'Môn học *',
                prefixIcon: Icon(Icons.school),
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tên môn học' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<DocumentType>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Loại tài liệu',
                prefixIcon: Icon(Icons.category),
                border: OutlineInputBorder(),
              ),
              items: DocumentType.values
                  .map((t) => DropdownMenuItem(value: t, child: Text(_typeLabel(t))))
                  .toList(),
              onChanged: (v) => setState(() => _selectedType = v!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _tagsCtrl,
              decoration: const InputDecoration(
                labelText: 'Tags (cách nhau bằng dấu phẩy)',
                prefixIcon: Icon(Icons.tag),
                hintText: 'ví dụ: chương 1, quan trọng, ôn thi',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Ghi chú',
                prefixIcon: Icon(Icons.notes),
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save),
                label: Text(isEditing ? 'Cập nhật' : 'Lưu tài liệu',
                    style: const TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
