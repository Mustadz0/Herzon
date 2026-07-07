import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/comment_model.dart';

abstract class ICommentRepository {
  Future<List<CommentModel>> getComments(String postId);
  Future<void> addComment(String postId, String userId, String content);
  Future<void> deleteComment(String commentId);
}

class SupabaseCommentRepository implements ICommentRepository {
  final SupabaseClient _supabase;

  SupabaseCommentRepository({required SupabaseClient supabase}) : _supabase = supabase;

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
      );
    }).toList();
  }

  @override
  Future<void> addComment(String postId, String userId, String content) async {
    await _supabase.from('comments').insert({
      'post_id': postId,
      'user_id': userId,
      'content': content,
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
