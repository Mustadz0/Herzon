import 'package:flutter_test/flutter_test.dart';
import 'package:herzon/data/models/post_model.dart';

void main() {
  group('PostModel JSON contract', () {
    test('get_nearby_posts RPC response parses correctly', () {
      final rpcResponse = {
        'id': 'post-1',
        'user_id': 'user-1',
        'content': 'Nearby!',
        'media_urls': <String>[],
        'media_type': 'text',
        'latitude': 36.75,
        'longitude': 3.06,
        'distance': 120.0,
        'comment_count': 3,
        'user_username': 'testuser',
        'user_display_name': 'Test User',
        'user_avatar_url': null,
        'reaction_counts': {'herz': 5},
        'created_at': '2026-07-12T10:00:00Z',
        'zone_id': null,
        'context_tag': null,
        'poll': null,
        'poll_total_votes': null,
        'user_poll_vote_index': null,
        'sticker_id': null,
        'video_url': null,
      };

      final post = PostModel.fromJson(rpcResponse);
      expect(post.id, 'post-1');
      expect(post.distanceMeters, 120.0);
      expect(post.commentCount, 3);
      expect(post.reactionCounts['herz'], 5);
    });

    test('create_post_with_location response parses correctly', () {
      final response = {
        'id': 'new-post-1',
        'user_id': 'user-1',
        'content': 'New post!',
        'media_urls': <String>[],
        'media_type': 'text',
        'latitude': 36.75,
        'longitude': 3.06,
        'created_at': '2026-07-12T10:00:00Z',
      };

      final post = PostModel.fromJson(response);
      expect(post.content, 'New post!');
      expect(post.latitude, 36.75);
    });
  });
}
