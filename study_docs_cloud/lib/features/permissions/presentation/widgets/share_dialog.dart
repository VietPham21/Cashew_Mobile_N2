import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/permission.dart';
import '../../data/repositories/permissions_repository_impl.dart';

class ShareDialog extends StatefulWidget {
  final String documentId;
  final String ownerId;
  final String documentTitle;

  const ShareDialog({
    super.key,
    required this.documentId,
    required this.ownerId,
    required this.documentTitle,
  });

  @override
  State<ShareDialog> createState() => _ShareDialogState();
}

class _ShareDialogState extends State<ShareDialog> {
  final _emailCtrl = TextEditingController();
  PermissionLevel _selectedLevel = PermissionLevel.view;
  List<Permission> _permissions = [];
  bool _loading = false;
  String? _error;

  late final PermissionsRepositoryImpl _repo;

  @override
  void initState() {
    super.initState();
    _repo = PermissionsRepositoryImpl(Supabase.instance.client);
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    setState(() => _loading = true);
    try {
      _permissions = await _repo.getPermissionsForDocument(widget.documentId);
    } catch (e) {
      _error = e.toString();
    }
    setState(() => _loading = false);
  }

  Future<void> _share() async {
    if (_emailCtrl.text.trim().isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _repo.shareDocument(
        documentId: widget.documentId,
        ownerId: widget.ownerId,
        targetEmail: _emailCtrl.text.trim(),
        level: _selectedLevel,
      );
      _emailCtrl.clear();
      await _loadPermissions();
    } catch (e) {
      setState(() => _error = e.toString());
    }
    setState(() => _loading = false);
  }

  Future<void> _revoke(String permissionId) async {
    await _repo.revokePermission(permissionId);
    await _loadPermissions();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Chia se: ${widget.documentTitle}',
        style: const TextStyle(fontSize: 16),
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Input email
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _emailCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Email nguoi dung',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<PermissionLevel>(
                  value: _selectedLevel,
                  items: const [
                    DropdownMenuItem(
                      value: PermissionLevel.view,
                      child: Text('Xem'),
                    ),
                    DropdownMenuItem(
                      value: PermissionLevel.edit,
                      child: Text('Sua'),
                    ),
                  ],
                  onChanged: (v) => setState(() => _selectedLevel = v!),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_error != null)
              Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _loading ? null : _share,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
              icon: const Icon(Icons.share, color: Colors.white),
              label: const Text(
                'Chia se',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const Divider(height: 24),
            const Text(
              'Da chia se voi:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_permissions.isEmpty)
              const Text(
                'Chua chia se voi ai',
                style: TextStyle(color: Colors.grey),
              )
            else
              ..._permissions.map(
                (p) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.person),
                  title: Text(p.sharedWithEmail),
                  subtitle: Text(
                    p.level == PermissionLevel.view ? 'Xem' : 'Sua',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () => _revoke(p.id),
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Dong'),
        ),
      ],
    );
  }
}
