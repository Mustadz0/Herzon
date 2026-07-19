import 'package:flutter_test/flutter_test.dart';
import 'package:herzon/data/models/user_model.dart';

void main() {
  group('UserModel', () {
    final json = {
      'id': 'user-1',
      'username': 'testuser',
      'display_name': 'Test User',
      'avatar_url': 'https://example.com/avatar.jpg',
      'bio': 'Hello!',
      'is_anonymous': false,
      'is_premium': true,
      'is_admin': true,
      'can_use_vibes': true,
      'premium_expires_at': '2027-01-01T00:00:00Z',
      'privacy_settings': {'show_activity': true, 'allow_messages': true},
      'created_at': '2026-01-01T00:00:00Z',
      'updated_at': '2026-07-01T00:00:00Z',
    };

    test('fromJson parses all fields', () {
      final user = UserModel.fromJson(json);
      expect(user.id, 'user-1');
      expect(user.username, 'testuser');
      expect(user.displayName, 'Test User');
      expect(user.avatarUrl, 'https://example.com/avatar.jpg');
      expect(user.bio, 'Hello!');
      expect(user.isAnonymous, false);
      expect(user.isPremium, true);
      expect(user.isAdmin, true);
      expect(user.canUseVibes, true);
    });

    test('toJson roundtrip', () {
      final original = UserModel.fromJson(json);
      final out = original.toJson();
      final restored = UserModel.fromJson(out);
      expect(restored.id, original.id);
      expect(restored.username, original.username);
      expect(restored.displayName, original.displayName);
      expect(restored.isAdmin, original.isAdmin);
    });

    test('default values for missing fields', () {
      final minimal = UserModel.fromJson({'id': 'user-2'});
      expect(minimal.isAnonymous, false);
      expect(minimal.isAdmin, false);
      expect(minimal.isPremium, false);
      expect(minimal.bio, isNull);
    });

    test('copyWith', () {
      final user = UserModel.fromJson(json);
      final copy = user.copyWith(displayName: 'Updated Name');
      expect(copy.displayName, 'Updated Name');
      expect(copy.id, user.id);
    });
  });
}
