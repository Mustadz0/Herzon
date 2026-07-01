import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MediaUploadService {
  final SupabaseClient _supabase;

  MediaUploadService({required SupabaseClient supabase}) : _supabase = supabase;

  String _ext(String path) {
    final dot = path.lastIndexOf('.');
    return dot == -1 ? '' : path.substring(dot);
  }

  Future<List<String>> uploadPostMedia({
    required List<File> files,
    required String userId,
  }) async {
    if (files.isEmpty) return [];

    final urls = <String>[];
    final bucket = _supabase.storage.from('post-media');

    for (final file in files) {
      final ext = _ext(file.path);
      final path = '$userId/${DateTime.now().millisecondsSinceEpoch}$ext';
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
    final ext = _ext(file.path);
    final path = '$userId$ext';
    final bucket = _supabase.storage.from('avatars');
    await bucket.upload(path, file, fileOptions: const FileOptions(upsert: true));
    return bucket.getPublicUrl(path);
  }
}

final mediaUploadServiceProvider = Provider<MediaUploadService>((ref) {
  return MediaUploadService(supabase: Supabase.instance.client);
});
