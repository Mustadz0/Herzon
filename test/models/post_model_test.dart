import 'package:flutter_test/flutter_test.dart';
import 'package:herzon/data/models/post_model.dart';

void main() {
  group('PollOptionData', () {
    test('fromJson parses correctly', () {
      final data = PollOptionData.fromJson({'text': 'Option A', 'votes': 5});
      expect(data.text, 'Option A');
      expect(data.votes, 5);
    });

    test('toJson returns correct map', () {
      final data = const PollOptionData(text: 'Option B', votes: 3);
      expect(data.toJson(), {'text': 'Option B', 'votes': 3});
    });

    test('percentageOf returns correct percentage', () {
      final data = const PollOptionData(text: 'X', votes: 25);
      expect(data.percentageOf(100), 25.0);
      expect(data.percentageOf(0), 0.0);
    });

    test('parseList handles map with options', () {
      final result = PollOptionData.parseList({
        'options': [
          {'text': 'A', 'votes': 1},
          {'text': 'B', 'votes': 2},
        ],
      });
      expect(result, isNotNull);
      expect(result!.length, 2);
      expect(result[0].text, 'A');
      expect(result[1].votes, 2);
    });

    test('parseList handles raw list', () {
      final result = PollOptionData.parseList([
        {'text': 'X', 'votes': 10},
        {'text': 'Y', 'votes': 20},
      ]);
      expect(result, isNotNull);
      expect(result!.length, 2);
      expect(result[1].text, 'Y');
    });

    test('parseList returns null for invalid input', () {
      expect(PollOptionData.parseList('invalid'), isNull);
      expect(PollOptionData.parseList(123), isNull);
      expect(PollOptionData.parseList(null), isNull);
    });
  });

  group('PostModel', () {
    final json = {
      'id': 'post-1',
      'user_id': 'user-1',
      'content': 'Test content',
      'media_urls': ['https://example.com/img.jpg'],
      'media_type': 'image',
      'latitude': 36.75,
      'longitude': 3.06,
      'zone_id': 'zone-1',
      'context_tag': 'general',
      'reaction_counts': {'herz': 10, 'fire': 3},
      'created_at': '2026-07-12T10:00:00Z',
      'user_username': 'testuser',
      'user_display_name': 'Test User',
      'user_avatar_url': 'https://example.com/avatar.jpg',
      'distance': 150.0,
      'comment_count': 5,
      'poll': {'options': [{'text': 'A', 'votes': 5}, {'text': 'B', 'votes': 3}]},
      'user_poll_vote_index': 0,
      'poll_total_votes': 8,
      'sticker_id': 'wave',
      'video_url': null,
    };

    test('fromJson parses all fields correctly', () {
      final post = PostModel.fromJson(json);
      expect(post.id, 'post-1');
      expect(post.userId, 'user-1');
      expect(post.content, 'Test content');
      expect(post.mediaUrls, ['https://example.com/img.jpg']);
      expect(post.mediaType, MediaType.image);
      expect(post.latitude, 36.75);
      expect(post.longitude, 3.06);
      expect(post.zoneId, 'zone-1');
      expect(post.contextTag, 'general');
      expect(post.reactionCounts['herz'], 10);
      expect(post.userUsername, 'testuser');
      expect(post.userDisplayName, 'Test User');
      expect(post.userAvatarUrl, 'https://example.com/avatar.jpg');
      expect(post.distanceMeters, 150.0);
      expect(post.commentCount, 5);
      expect(post.pollOptions, isNotNull);
      expect(post.pollOptions!.length, 2);
      expect(post.userPollVoteIndex, 0);
      expect(post.pollTotalVotes, 8);
      expect(post.stickerId, 'wave');
    });

    test('toJson returns correct map', () {
      final post = PostModel.fromJson(json);
      final out = post.toJson();
      expect(out['id'], 'post-1');
      expect(out['user_id'], 'user-1');
      expect(out['content'], 'Test content');
      expect(out['latitude'], 36.75);
      expect(out['longitude'], 3.06);
    });

    test('copyWith preserves unset fields', () {
      final post = PostModel.fromJson(json);
      final copy = post.copyWith(content: 'Updated');
      expect(copy.id, post.id);
      expect(copy.content, 'Updated');
      expect(copy.latitude, post.latitude);
    });

    test('fromJson handles text-only post', () {
      final textJson = {
        'id': 'post-2',
        'user_id': 'user-2',
        'content': 'Just text',
        'media_type': 'text',
        'latitude': 0,
        'longitude': 0,
      };
      final post = PostModel.fromJson(textJson);
      expect(post.content, 'Just text');
      expect(post.mediaType, MediaType.text);
      expect(post.mediaUrls, isEmpty);
    });
  });
}
