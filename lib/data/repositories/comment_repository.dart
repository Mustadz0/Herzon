import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/comment_model.dart';
import '../../core/utils/firebase_uuid.dart';

abstract class ICommentRepository {
  Future<List<CommentModel>> getComments(String postId);
  // FIX: حذف userId من المعاملات — يُستخرج داخلياً من Firebase
  Future<void> addComment(String postId, String content, {String? parentId});
  Future<void> deleteComment(String commentId);
}

class SupabaseCommentRepository implements ICommentRepository {
  final SupabaseClient _supabase;

  SupabaseCommentRepository({required SupabaseClient supabase})
      : _supabase = supabase;

  /// Returns the current user's UUID v5 (converted from Firebase UID).
  String _currentUuid() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');
    return FirebaseUuid.toUuid(uid);
  }

  @override
  Future<List<CommentModel>> getComments(String postId) async {
    final data = await _supabase
        .from('comments')
        .select('*, profiles!inner(username, display_name, avatar_url)')
        .eq('post_id', postId)
        .order('created_at', ascending: true);
    return data.map((json) {
      final profile = json['profiles'] as Map<String, dynamic>?;
      return CommentModel(
        id: json['id'] as String,
        postId: json['post_id'] as String,
        userId: json['user_id'] as String,
        content: json['content'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        username: profile?['username'] as String?,
        displayName: profile?['display_name'] as String?,
        avatarUrl: profile?['avatar_url'] as String?,
        parentId: json['parent_id'] as String?,
      );
    }).toList();
  }

  @override
  // FIX: userId لم يعد معاملاً خارجياً — يُستخرج من Firebase داخلياً
  Future<void> addComment(String postId, String content,
      {String? parentId}) async {
    final uuid = _currentUuid();
    await _supabase.from('comments').insert({
      'post_id': postId,
      'user_id': uuid,
      'content': content,
      if (parentId != null) 'parent_id': parentId,
    });
  }

  @override
  Future<void> deleteComment(String commentId) async {
    await _supabase.from('comments').delete().eq('id', commentId);
  }
}

final commentRepositoryProvider = Provider<ICommentRepository>((ref) {
  return SupabaseCommentRepository(supabase: Supabase.instance.client);
});
