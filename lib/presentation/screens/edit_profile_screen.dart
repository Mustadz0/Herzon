import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/firebase_uuid.dart';

extension _ThemeDark on ThemeData {
  bool get isDark => brightness == Brightness.dark;
}

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _displayNameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      // FIX: UUID من Firebase بدل Supabase.auth
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final uuid = FirebaseUuid.toUuid(uid);
      final data = await Supabase.instance.client
          .from('profiles')
          .select('display_name, username, bio')
          .eq('id', uuid)
          .maybeSingle();
      if (data != null && mounted) {
        _displayNameCtrl.text = data['display_name'] ?? '';
        _usernameCtrl.text = data['username'] ?? '';
        _bioCtrl.text = data['bio'] ?? '';
      }
    } catch (e) {
      debugPrint('EditProfile load error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    final displayName = _displayNameCtrl.text.trim();
    final username = _usernameCtrl.text.trim();
    if (displayName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le nom est requis')));
      return;
    }
    setState(() => _isSaving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final uuid = FirebaseUuid.toUuid(uid);
      await Supabase.instance.client.from('profiles').upsert({
        'id': uuid,
        'display_name': displayName,
        'username': username,
        'bio': _bioCtrl.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil mis à jour ✓'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    _usernameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier le profil'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Enregistrer'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _displayNameCtrl,
            decoration: const InputDecoration(
              labelText: 'Nom affiché *',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _usernameCtrl,
            decoration: const InputDecoration(
              labelText: 'Nom d\'utilisateur',
              prefixText: '@',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _bioCtrl,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Bio',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}
