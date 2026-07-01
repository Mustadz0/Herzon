import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../providers/post_provider.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _controller = TextEditingController();
  final _picker = ImagePicker();
  String? _selectedTag;
  bool _isSubmitting = false;
  List<File> _selectedFiles = [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickFromCamera() async {
    final xFile = await _picker.pickImage(source: ImageSource.camera);
    if (xFile != null) {
      setState(() => _selectedFiles.add(File(xFile.path)));
    }
  }

  Future<void> _pickFromGallery() async {
    final xFiles = await _picker.pickMultiImage();
    setState(() {
      _selectedFiles.addAll(xFiles.map((x) => File(x.path)));
    });
  }

  Future<void> _removeFile(int index) async {
    setState(() => _selectedFiles.removeAt(index));
  }

  Future<void> _submit() async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      await ref.read(postProvider.notifier).createPost(
        content,
        _selectedTag,
        mediaFiles: _selectedFiles,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle publication'),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Publier', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              maxLines: 5,
              maxLength: 500,
              decoration: const InputDecoration(
                hintText: 'Quoi de nouveau ?',
                border: OutlineInputBorder(),
              ),
            ),
            if (_selectedFiles.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedFiles.length,
                  itemBuilder: (context, index) => Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _selectedFiles[index],
                            height: 100, width: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0, right: 8,
                        child: GestureDetector(
                          onTap: () => _removeFile(index),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, size: 18, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Text('Contexte', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: AppConstants.contextTags.map((tag) {
                final selected = _selectedTag == tag;
                return ChoiceChip(
                  label: Text(tag),
                  selected: selected,
                  onSelected: (val) => setState(() => _selectedTag = val ? tag : null),
                  selectedColor: AppTheme.primaryColor.withValues(alpha: 0.3),
                );
              }).toList(),
            ),
            const Spacer(),
            Row(
              children: [
                const Icon(Icons.location_on, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Position actuelle',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.camera_alt, color: Colors.grey),
                  onPressed: _pickFromCamera,
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.image, color: Colors.grey),
                  onPressed: _pickFromGallery,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
