// Fix #4: ConversationsNotifier now subscribes to Realtime so new
// conversations appear instantly.
// Fix #1: messagesProvider name conflict resolved — messages_provider.dart
// now re-exports this file.
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/message_model.dart';
import '../../data/repositories/message_repository.dart';

final messageRepositoryProvider = Provider<IMessageRepository>((ref) {
  return SupabaseMessageRepository(supabase: Supabase.instance.client);
});

// ── Conversations ─────────────────────────────────────────────────────────────

final conversationsProvider = StateNotifierProvider<
    ConversationsNotifier, AsyncValue<List<ConversationModel>>>((ref) {
  return ConversationsNotifier(ref.read(messageRepositoryProvider));
});

class ConversationsNotifier
    extends StateNotifier<AsyncValue<List<ConversationModel>>> {
  final IMessageRepository _repository;
  RealtimeChannel? _channel; // Fix #4

  ConversationsNotifier(this._repository)
      : super(const AsyncValue.loading()) {
    loadConversations();
    _subscribeRealtime();
  }

  Future<void> loadConversations() async {
    state = const AsyncValue.loading();
    try {
      final conversations = await _repository.getConversations();
      if (mounted) state = AsyncValue.data(conversations);
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }

  // Fix #4: listen for new messages — reload conversation list so
  // last_message and unread_count update automatically.
  void _subscribeRealtime() {
    _channel = Supabase.instance.client
        .channel('conversations:messages')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (_) => loadConversations(),
        )
        .subscribe();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}

// ── Messages ──────────────────────────────────────────────────────────────────

final messagesProvider = StateNotifierProvider.family<
    MessagesNotifier, AsyncValue<List<MessageModel>>, String>(
  (ref, conversationId) => MessagesNotifier(
    ref.read(messageRepositoryProvider),
    conversationId,
  ),
);

class MessagesNotifier
    extends StateNotifier<AsyncValue<List<MessageModel>>> {
  final IMessageRepository _repository;
  final String conversationId;
  StreamSubscription? _subscription;

  MessagesNotifier(this._repository, this.conversationId)
      : super(const AsyncValue.loading()) {
    loadMessages();
    _subscribeToMessages();
  }

  Future<void> loadMessages() async {
    state = const AsyncValue.loading();
    try {
      final messages = await _repository.getMessages(conversationId);
      if (mounted) state = AsyncValue.data(messages);
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }

  void _subscribeToMessages() {
    _subscription =
        _repository.subscribeToMessages(conversationId).listen((message) {
      if (!mounted) return;
      state.whenData((messages) {
        if (!messages.any((m) => m.id == message.id)) {
          state = AsyncValue.data([...messages, message]);
        }
      });
    });
  }

  Future<void> sendMessage({
    required String content,
    String messageType = 'text',
    String? mediaUrl,
    String? stickerId,
  }) async {
    try {
      final message = await _repository.sendMessage(
        conversationId: conversationId,
        content: content,
        messageType: messageType,
        mediaUrl: mediaUrl,
        stickerId: stickerId,
      );
      if (mounted) {
        state.whenData(
            (messages) => state = AsyncValue.data([...messages, message]));
      }
    } catch (e, st) {
      if (mounted)
        state = AsyncValue.error('Failed to send message: $e', st);
    }
  }

  Future<void> markAsRead() async {
    try {
      await _repository.markAsRead(conversationId);
    } catch (e) {
      debugPrint('Failed to mark as read: $e');
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final currentConversationIdProvider = StateProvider<String?>((ref) => null);

final totalUnreadProvider = Provider<AsyncValue<int>>((ref) {
  final conversationsAsync = ref.watch(conversationsProvider);
  return conversationsAsync.whenData(
    (conversations) =>
        conversations.fold(0, (sum, c) => sum + c.unreadCount),
  );
});
