import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/story_provider.dart';

class CreateStoryScreen extends ConsumerStatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  ConsumerState<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends ConsumerState<CreateStoryScreen> {
  final _picker = ImagePicker();
  final _textController = TextEditingController();
  File? _mediaFile;
  String _mediaType = 'image';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickFromCamera() async {
    final xFile = await _picker.pickImage(source: ImageSource.camera);
    if (xFile != null) {
      setState(() => _mediaFile = File(xFile.path));
    }
  }

  Future<void> _pickFromGallery() async {
    final xFile = await _picker.pickImage(source: ImageSource.gallery);
    if (xFile != null) {
      setState(() => _mediaFile = File(xFile.path));
    }
  }

  Future<void> _pickVideo() async {
    final xFile = await _picker.pickVideo(source: ImageSource.gallery);
    if (xFile != null) {
      setState(() {
        _mediaFile = File(xFile.path);
        _mediaType = 'video';
      });
    }
  }

  Future<void> _submit() async {
    if (_mediaFile == null) return;

    setState(() => _isSubmitting = true);
    try {
      await ref.read(storyProvider.notifier).createStory(
        mediaFile: _mediaFile!,
        mediaType: _mediaType,
        textOverlay: _textController.text.trim().isEmpty
            ? null
            : _textController.text.trim(),
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Nouvelle story', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_mediaFile != null)
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
      body: _mediaFile == null
          ? _buildPicker()
          : _buildPreview(),
    );
  }

  Widget _buildPicker() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.add_photo_alternate, color: Colors.white54, size: 64),
          const SizedBox(height: 24),
          const Text(
            'Ajouter une photo ou video',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 32),
          _pickerButton(Icons.camera_alt, 'Appareil photo', _pickFromCamera),
          const SizedBox(height: 16),
          _pickerButton(Icons.photo_library, 'Galerie', _pickFromGallery),
          const SizedBox(height: 16),
          _pickerButton(Icons.videocam, 'Video', _pickVideo),
        ],
      ),
    );
  }

  Widget _pickerButton(IconData icon, String label, VoidCallback onTap) {
    return SizedBox(
      width: 220,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white),
        label: Text(label, style: const TextStyle(color: Colors.white)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.white24),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildPreview() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.file(
          _mediaFile!,
          fit: BoxFit.contain,
        ),
        Positioned(
          bottom: 120,
          left: 16,
          right: 16,
          child: TextField(
            controller: _textController,
            textAlign: TextAlign.center,
            maxLines: 3,
            maxLength: 100,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.none,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'Ajouter du texte...',
              hintStyle: TextStyle(color: Colors.white38, fontSize: 24),
              counterStyle: TextStyle(color: Colors.white38),
            ),
          ),
        ),
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _iconButton(Icons.camera_alt, _pickFromCamera),
              const SizedBox(width: 24),
              _iconButton(Icons.photo_library, _pickFromGallery),
              const SizedBox(width: 24),
              _iconButton(Icons.videocam, _pickVideo),
            ],
          ),
        ),
      ],
    );
  }

  Widget _iconButton(IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black54,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onTap,
      ),
    );
  }
}
