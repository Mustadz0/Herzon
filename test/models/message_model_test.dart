import 'package:flutter_test/flutter_test.dart';
import 'package:herzon/data/models/message_model.dart';

void main() {
  group('MessageModel', () {
    test('fromJson parses text message', () {
      final json = {
        'id': 'msg-1',
        'conversation_id': 'conv-1',
        'sender_id': 'user-1',
        'content': 'Hello!',
        'message_type': 'text',
        'is_read': true,
        'created_at': '2026-07-12T10:00:00Z',
      };
      final msg = MessageModel.fromJson(json);
      expect(msg.id, 'msg-1');
      expect(msg.content, 'Hello!');
      expect(msg.isText, true);
      expect(msg.isRead, true);
    });

    test('fromJson parses image message', () {
      final json = {
        'id': 'msg-2',
        'sender_id': 'user-2',
        'content': 'Check this',
        'message_type': 'image',
        'media_url': 'https://example.com/img.jpg',
      };
      final msg = MessageModel.fromJson(json);
      expect(msg.isImage, true);
      expect(msg.mediaUrl, 'https://example.com/img.jpg');
    });

    test('copyWith', () {
      final json = {
        'id': 'msg-1',
        'sender_id': 'user-1',
        'content': 'Hello!',
      };
      final msg = MessageModel.fromJson(json);
      final copy = msg.copyWith(content: 'Updated', isRead: true);
      expect(copy.content, 'Updated');
      expect(copy.isRead, true);
      expect(copy.id, 'msg-1');
    });
  });

  group('ConversationModel', () {
    test('fromJson parses correctly', () {
      final json = {
        'conversation_id': 'conv-1',
        'other_user_id': 'user-2',
        'other_user_name': 'User 2',
        'other_user_avatar': 'https://example.com/avatar.jpg',
        'last_message': 'Hey!',
        'last_message_at': '2026-07-12T10:00:00Z',
        'unread_count': 3,
      };
      final conv = ConversationModel.fromJson(json);
      expect(conv.id, 'conv-1');
      expect(conv.otherUserId, 'user-2');
      expect(conv.otherUserName, 'User 2');
      expect(conv.unreadCount, 3);
    });
  });
}
