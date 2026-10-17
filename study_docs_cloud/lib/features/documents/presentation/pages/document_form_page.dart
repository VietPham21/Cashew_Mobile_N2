import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/study_document.dart';
import '../viewmodels/documents_viewmodel.dart';

class DocumentFormPage extends StatefulWidget {
  final StudyDocument? existing;
  final DocumentsViewModel viewModel; // Nhan VM tu ngoai vao

  const DocumentFormPage({
    super.key,
    this.existing,
    required this.viewModel,
  });

  @override
  State<DocumentFormPage> createState() => _DocumentFormPageState();
}

class _DocumentFormPageState extends State<DocumentFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _courseCtrl;
  late TextEditingController _notesCtrl;
  late TextEditingController _tagsCtrl;
  DocumentType _type = DocumentType.lecture;
  bool _isPublic = false;
  bool _isSubmitting = false;

  List<int>? _pickedFileBytes;
  String? _pickedFileName;

  bool get isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final d = widget.existing;
    _titleCtrl = TextEditingController(text: d?.title ?? '');
    _courseCtrl = TextEditingController(text: d?.course ?? '');
    _notesCtrl = TextEditingController(text: d?.notes ?? '');
    _tagsCtrl = TextEditingController(text: d?.tags.join(', ') ?? '');
    _type = d?.type ?? DocumentType.lecture;
    _isPublic = d?.isPublic ?? false;
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
      case DocumentType.lecture:    return 'Bai giang';
      case DocumentType.assignment: return 'Bai tap';
      case DocumentType.reference:  return 'Tai lieu tham khao';
      case DocumentType.other:      return 'Khac';
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      withData: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'png', 'jpg', 'jpeg'],
    );
    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _pickedFileBytes = result.files.single.bytes!;
        _pickedFileName = result.files.single.name;
      });
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

    // Dung VM duoc truyen tu ngoai vao
    final vm = widget.viewModel;
    bool success;

    if (isEditing) {
      final updated = widget.existing!.copyWith(
        title: _titleCtrl.text.trim(),
        type: _type,
        course: _courseCtrl.text.trim(),
        tags: tags,
        notes: _notesCtrl.text.trim(),
        isPublic: _isPublic,
      );
      success = await vm.update(
        updated,
        fileBytes: _pickedFileBytes,
        fileName: _pickedFileName,
      );
    } else {
      success = await vm.add(
        title: _titleCtrl.text.trim(),
        type: _type,
        course: _courseCtrl.text.trim(),
        tags: tags,
        notes: _notesCtrl.text.trim(),
        isPublic: _isPublic,
        fileBytes: _pickedFileBytes,
        fileName: _pickedFileName,
      );
    }

    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.errorMessage ?? 'Co loi xay ra'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Sua tai lieu' : 'Them tai lieu'),
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
                labelText: 'Tieu de *',
                prefixIcon: Icon(Icons.title),
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Vui long nhap tieu de'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _courseCtrl,
              decoration: const InputDecoration(
                labelText: 'Mon hoc *',
                prefixIcon: Icon(Icons.school),
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Vui long nhap ten mon hoc'
                  : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<DocumentType>(
              value: _type,
              decoration: const InputDecoration(
                labelText: 'Loai tai lieu',
                prefixIcon: Icon(Icons.category),
                border: OutlineInputBorder(),
              ),
              items: DocumentType.values
                  .map((t) => DropdownMenuItem(
                      value: t, child: Text(_typeLabel(t))))
                  .toList(),
              onChanged: (v) => setState(() => _type = v!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _tagsCtrl,
              decoration: const InputDecoration(
                labelText: 'Tags (cach nhau bang dau phay)',
                prefixIcon: Icon(Icons.tag),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Ghi chu',
                prefixIcon: Icon(Icons.notes),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // File picker
            OutlinedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.attach_file),
              label: Text(
                _pickedFileName ??
                    (widget.existing?.fileName.isNotEmpty == true
                        ? 'File: ${widget.existing!.fileName}'
                        : 'Chon file dinh kem (tuy chon)'),
              ),
            ),
            if (_pickedFileName != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Da chon: $_pickedFileName',
                  style: const TextStyle(
                      color: Colors.green, fontSize: 12),
                ),
              ),
            const SizedBox(height: 16),

            // Public toggle
            SwitchListTile(
              title: const Text('Cong khai cho moi nguoi'),
              subtitle: const Text('Tat ca nguoi dung co the xem'),
              value: _isPublic,
              onChanged: (v) => setState(() => _isPublic = v),
              activeColor: Colors.indigo,
            ),
            const SizedBox(height: 24),

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
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save),
                label: Text(
                  isEditing ? 'Cap nhat' : 'Luu tai lieu',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
