import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/marketplace_item_model.dart';
import '../providers/marketplace_provider.dart';

class CreateMarketplaceItemScreen extends ConsumerStatefulWidget {
  const CreateMarketplaceItemScreen({super.key});

  @override
  ConsumerState<CreateMarketplaceItemScreen> createState() => _CreateMarketplaceItemScreenState();
}

class _CreateMarketplaceItemScreenState extends ConsumerState<CreateMarketplaceItemScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  String _selectedCategory = marketplaceCategories[1];
  List<File> _images = [];
  bool _isSubmitting = false;

  Future<void> _pickImages() async {
    final files = await ImagePicker().pickMultiImage();
    if (files.isNotEmpty) {
      setState(() => _images = files.map((f) => File(f.path)).toList());
    }
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Titre obligatoire')));
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await ref.read(marketplaceProvider.notifier).createItem(
        title: title,
        description: _descController.text.trim(),
        price: double.tryParse(_priceController.text.replaceAll(',', '.')),
        category: _selectedCategory,
        mediaFiles: _images,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle annonce'),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Publier', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImages,
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: _images.isEmpty
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('Ajouter des photos', style: TextStyle(color: Colors.grey)),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(_images.first, fit: BoxFit.cover, width: double.infinity),
                      ),
              ),
            ),
            if (_images.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('${_images.length} photo(s) selectionnee(s) - appuyer pour changer',
                style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Titre *', hintText: 'Que vendez-vous?'),
              maxLength: 100,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Description', hintText: 'Decrivez votre article...'),
              maxLines: 4,
              maxLength: 1000,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Prix (DA)',
                hintText: '0',
                prefixText: 'DA ',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(labelText: 'Categorie'),
              items: marketplaceCategories.where((c) => c != 'Tout').map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _selectedCategory = v ?? marketplaceCategories[1]),
            ),
          ],
        ),
      ),
    );
  }
}
