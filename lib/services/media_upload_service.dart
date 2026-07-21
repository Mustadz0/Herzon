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

  static const _magicBytes = <String, List<int>>{
    'jpg': [0xFF, 0xD8, 0xFF],
    'jpeg': [0xFF, 0xD8, 0xFF],
    'png': [0x89, 0x50, 0x4E, 0x47],
    'gif': [0x47, 0x49, 0x46],
    'webp': [0x52, 0x49, 0x46, 0x46],
    'mp4': [0x00, 0x00, 0x00],
    'mov': [0x00, 0x00, 0x00],
  };

  final SupabaseClient _supabase;

  MediaUploadService({required SupabaseClient supabase}) : _supabase = supabase;

  String _ext(String path) {
    final dot = path.lastIndexOf('.');
    return dot == -1 ? '' : path.substring(dot).toLowerCase();
  }

  Future<void> _validateMagicBytes(File file, String ext) async {
    final key = ext.replaceFirst('.', '');
    final expected = _magicBytes[key];
    if (expected == null) return;
    final raf = await file.open(mode: FileMode.read);
    try {
      final header = await raf.read(expected.length);
      if (header.length < expected.length) throw Exception('Fichier corrompu ou invalide.');
      for (var i = 0; i < expected.length; i++) {
        if (header[i] != expected[i]) {
          if (key == 'mp4' || key == 'mov') {
            // MP4/MOV boxes start with varying bytes — skip magic check for video
            return;
          }
          throw Exception('Le fichier ne correspond pas au type attendu ($ext).');
        }
      }
    } finally {
      await raf.close();
    }
  }

  Future<void> _validatePostMedia(File file) async {
    final ext = _ext(file.path);
    final isImage = _allowedImageExts.contains(ext);
    final isVideo = _allowedVideoExts.contains(ext);
    if (!isImage && !isVideo) {
      throw Exception('Type de fichier non autorise.');
    }

    await _validateMagicBytes(file, ext);

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
    await _validateMagicBytes(file, ext);
    if (await file.length() > 2 * 1024 * 1024) {
      throw Exception('L avatar depasse 2 Mo.');
    }
  }

  Future<List<String>> uploadPostMedia({
    required List<File> files,
    required String userId,
  }) async {
    if (files.isEmpty) return [];

    for (final file in files) {
      await _validatePostMedia(file);
    }

    final urls = <String>[];
    final paths = <String>[];
    final bucket = _supabase.storage.from('post-media');

    try {
      for (final file in files) {
        final ext = _ext(file.path);
        final path =
            '$userId/${DateTime.now().millisecondsSinceEpoch}-${_uuid.v4()}$ext';
        await bucket.upload(path, file);
        paths.add(path);
        urls.add(bucket.getPublicUrl(path));
      }
    } catch (e) {
      for (final path in paths) {
        try {
          await bucket.remove([path]);
        } catch (_) {}
      }
      rethrow;
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
