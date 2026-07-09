import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class MediaUploadService {
  static const int _maxImageBytes = 10 * 1024 * 1024;
  static const int _maxVideoBytes = 50 * 1024 * 1024;
  static const Set<String> _allowedImageExts = {
    '.jpg',
    '.jpeg',
    '.png',
    '.gif',
    '.webp',
  };
  static const Set<String> _allowedVideoExts = {'.mp4', '.mov'};
  static const Uuid _uuid = Uuid();

  final SupabaseClient _supabase;

  MediaUploadService({required SupabaseClient supabase}) : _supabase = supabase;

  String _ext(String path) {
    final dot = path.lastIndexOf('.');
    return dot == -1 ? '' : path.substring(dot).toLowerCase();
  }

  Future<void> _validatePostMedia(File file) async {
    final ext = _ext(file.path);
    final isImage = _allowedImageExts.contains(ext);
    final isVideo = _allowedVideoExts.contains(ext);
    if (!isImage && !isVideo) {
      throw Exception('Type de fichier non autorise.');
    }

    final length = await file.length();
    final maxBytes = isVideo ? _maxVideoBytes : _maxImageBytes;
    if (length > maxBytes) {
      throw Exception(
        isVideo ? 'La video depasse 50 Mo.' : 'L image depasse 10 Mo.',
      );
    }
  }

  Future<void> _validateAvatar(File file) async {
    final ext = _ext(file.path);
    if (!_allowedImageExts.contains(ext) || ext == '.gif') {
      throw Exception('Format d avatar non autorise.');
    }
    if (await file.length() > 2 * 1024 * 1024) {
      throw Exception('L avatar depasse 2 Mo.');
    }
  }

  Future<List<String>> uploadPostMedia({
    required List<File> files,
    required String userId,
  }) async {
    if (files.isEmpty) return [];

    final urls = <String>[];
    final bucket = _supabase.storage.from('post-media');

    for (final file in files) {
      await _validatePostMedia(file);
      final ext = _ext(file.path);
      final path =
          '$userId/${DateTime.now().millisecondsSinceEpoch}-${_uuid.v4()}$ext';
      await bucket.upload(path, file);
      final url = bucket.getPublicUrl(path);
      urls.add(url);
    }

    return urls;
  }

  Future<String?> uploadAvatar({
    required File file,
    required String userId,
  }) async {
    await _validateAvatar(file);
    final ext = _ext(file.path);
    final path = '$userId$ext';
    final bucket = _supabase.storage.from('avatars');
    await bucket.upload(
      path,
      file,
      fileOptions: const FileOptions(upsert: true),
    );
    return bucket.getPublicUrl(path);
  }
}

final mediaUploadServiceProvider = Provider<MediaUploadService>((ref) {
  return MediaUploadService(supabase: Supabase.instance.client);
});
