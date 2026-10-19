import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:latlong2/latlong.dart';
import '../../domain/entities/study_document.dart';
import '../viewmodels/documents_viewmodel.dart';
import 'location_picker_page.dart';

class DocumentFormPage extends StatefulWidget {
  final DocumentsViewModel viewModel;
  final StudyDocument? existing;

  const DocumentFormPage({super.key, required this.viewModel, this.existing});

  @override
  State<DocumentFormPage> createState() => _DocumentFormPageState();
}

class _DocumentFormPageState extends State<DocumentFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _courseCtrl;
  late TextEditingController _notesCtrl;
  late TextEditingController _tagsCtrl;
  late TextEditingController _locationNameCtrl;
  DocumentType _type = DocumentType.lecture;
  bool _isPublic = false;
  bool _saving   = false;

  PlatformFile? _pickedFile;
  double? _lat;
  double? _lng;

  @override
  void initState() {
    super.initState();
    final d = widget.existing;
    _titleCtrl        = TextEditingController(text: d?.title ?? '');
    _courseCtrl       = TextEditingController(text: d?.course ?? '');
    _notesCtrl        = TextEditingController(text: d?.notes ?? '');
    _tagsCtrl         = TextEditingController(text: d?.tags.join(', ') ?? '');
    _locationNameCtrl = TextEditingController(text: d?.locationName ?? '');
    _type     = d?.type ?? DocumentType.lecture;
    _isPublic = d?.isPublic ?? false;
    _lat      = d?.latitude;
    _lng      = d?.longitude;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _courseCtrl.dispose();
    _notesCtrl.dispose();
    _tagsCtrl.dispose();
    _locationNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result != null && result.files.isNotEmpty) {
      setState(() => _pickedFile = result.files.first);
    }
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerPage(initialLat: _lat, initialLng: _lng),
      ),
    );
    if (result != null) {
      setState(() {
        _lat = result.latitude;
        _lng = result.longitude;
      });
    }
  }

  void _clearLocation() {
    setState(() {
      _lat = null;
      _lng = null;
      _locationNameCtrl.clear();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final tags = _tagsCtrl.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final locName = _locationNameCtrl.text.trim().isEmpty
        ? null
        : _locationNameCtrl.text.trim();

    bool ok;
    final d = widget.existing;

    if (d == null) {
      ok = await widget.viewModel.add(
        title:        _titleCtrl.text.trim(),
        type:         _type,
        course:       _courseCtrl.text.trim(),
        tags:         tags,
        notes:        _notesCtrl.text.trim(),
        isPublic:     _isPublic,
        latitude:     _lat,
        longitude:    _lng,
        locationName: locName,
        fileBytes:    _pickedFile?.bytes?.toList(),
        fileName:     _pickedFile?.name,
      );
    } else {
      final updated = d.copyWith(
        title:        _titleCtrl.text.trim(),
        type:         _type,
        course:       _courseCtrl.text.trim(),
        tags:         tags,
        notes:        _notesCtrl.text.trim(),
        isPublic:     _isPublic,
        latitude:     _lat,
        longitude:    _lng,
        locationName: locName,
        updatedAt:    DateTime.now(),
      );
      ok = await widget.viewModel.update(
        updated,
        fileBytes: _pickedFile?.bytes?.toList(),
        fileName:  _pickedFile?.name,
      );
    }

    if (mounted) {
      if (ok) {
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.viewModel.errorMessage ?? 'Error')),
        );
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Document' : 'Add Document')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Title *', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _courseCtrl,
              decoration: const InputDecoration(labelText: 'Course', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<DocumentType>(
              value: _type,
              decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
              items: DocumentType.values
                  .map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
                  .toList(),
              onChanged: (v) => setState(() => _type = v!),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesCtrl,
              decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder()),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _tagsCtrl,
              decoration: const InputDecoration(
                labelText: 'Tags (comma separated)',
                hintText: 'flutter, mobile, dart',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Public (visible to everyone)'),
              value: _isPublic,
              onChanged: (v) => setState(() => _isPublic = v),
            ),
            const Divider(height: 24),
            Text('Attached File', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _pickFile,
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Choose File'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _pickedFile?.name ?? (widget.existing?.fileName.isNotEmpty == true ? widget.existing!.fileName : 'No file chosen'),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text('Document Location', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            if (_lat != null && _lng != null)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Lat: ${_lat!.toStringAsFixed(5)}, Lng: ${_lng!.toStringAsFixed(5)}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: _clearLocation,
                      tooltip: 'Remove location',
                    ),
                  ],
                ),
              )
            else
              const Text('No location set', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _locationNameCtrl,
              decoration: const InputDecoration(
                labelText: 'Location Name (optional)',
                hintText: 'e.g. Library Room 3',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.place),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickLocation,
              icon: const Icon(Icons.map),
              label: Text(_lat != null ? 'Change Location on Map' : 'Pick Location on Map'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              child: _saving
                  ? const CircularProgressIndicator()
                  : Text(isEdit ? 'Save Changes' : 'Add Document'),
            ),
          ],
        ),
      ),
    );
  }
}
