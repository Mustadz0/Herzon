import 'package:flutter_test/flutter_test.dart';
import 'package:herzon/data/models/comment_model.dart';

void main() {
  group('CommentModel', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 'comment-1',
        'post_id': 'post-1',
        'user_id': 'user-1',
        'content': 'Great post!',
        'created_at': '2026-07-12T10:00:00Z',
        'username': 'testuser',
        'display_name': 'Test User',
        'avatar_url': 'https://example.com/avatar.jpg',
        'parent_id': 'comment-0',
      };
      final comment = CommentModel.fromJson(json);
      expect(comment.id, 'comment-1');
      expect(comment.postId, 'post-1');
      expect(comment.content, 'Great post!');
      expect(comment.parentId, 'comment-0');
    });
  });
}
