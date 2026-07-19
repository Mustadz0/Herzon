import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/firebase_uuid.dart';

class ReportScreen extends StatefulWidget {
  final String postId;

  const ReportScreen({super.key, required this.postId});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _reasonController = TextEditingController();
  bool _isSubmitting = false;

  final _reasons = [
    'Contenu inapproprie',
    'Harcelement',
    'Spam',
    'Contenu violent',
    'Autre',
  ];

  String? _selectedReason;

  Future<void> _submit() async {
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez selectionner un motif')));
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final fbUser = FirebaseAuth.instance.currentUser;
      if (fbUser == null) throw Exception('Not authenticated');
      await Supabase.instance.client.from('reports').insert({
        'reporter_id': FirebaseUuid.toUuid(fbUser.uid),
        'post_id': widget.postId,
        'reason': _selectedReason,
        'description': _reasonController.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signalement envoye')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Signaler')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Motif du signalement', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            RadioGroup<String>(
              groupValue: _selectedReason,
              onChanged: (v) => setState(() => _selectedReason = v ?? _selectedReason),
              child: Column(
                children: _reasons.map((reason) {
                  final selected = _selectedReason == reason;
                  return ListTile(
                    leading: Radio<String>(value: reason),
                    title: Text(reason),
                    onTap: () => setState(() => _selectedReason = reason),
                    selected: selected,
                  );
                }).toList(),
              ),
            ),
            if (_selectedReason == 'Autre') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.flag),
                label: Text(_isSubmitting ? 'Envoi...' : 'Envoyer le signalement'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
