import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/firebase_uuid.dart';
import '../../data/models/message_model.dart';
import '../providers/messenger_provider.dart';

extension _ThemeDark on ThemeData {
  bool get isDark => brightness == Brightness.dark;
}

class ConversationScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String otherUserName;
  final String? otherUserAvatar;
  final String otherUserId;

  const ConversationScreen({
    super.key,
    required this.conversationId,
    required this.otherUserName,
    this.otherUserAvatar,
    required this.otherUserId,
  });

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  bool _isSending = false;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(messagesProvider(widget.conversationId).notifier).loadMessages();
    });
    _subscribeRealtime();
  }

  void _subscribeRealtime() {
    _channel = Supabase.instance.client
        .channel('conv:${widget.conversationId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: widget.conversationId,
          ),
          callback: (_) {
            ref.read(messagesProvider(widget.conversationId).notifier).loadMessages();
            _scrollToBottom();
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _msgController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final content = _msgController.text.trim();
    if (content.isEmpty) return;
    setState(() => _isSending = true);
    try {
      // FIX: UUID من Firebase
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final senderUuid = FirebaseUuid.toUuid(uid);
      await ref
          .read(messagesProvider(widget.conversationId).notifier)
          .sendMessage(content: content, senderId: senderUuid);
      _msgController.clear();
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final messagesAsync = ref.watch(messagesProvider(widget.conversationId));
    // FIX: FirebaseAuth بدل Supabase.auth
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    final myUuid = myUid != null ? FirebaseUuid.toUuid(myUid) : null;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: widget.otherUserAvatar == null ? AppTheme.brandGradient : null,
              ),
              child: widget.otherUserAvatar != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.network(widget.otherUserAvatar!, fit: BoxFit.cover))
                  : const Icon(Icons.person, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Text(widget.otherUserName),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) => messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 48,
                            color: t.colorScheme.onSurfaceVariant),
                          const SizedBox(height: 12),
                          Text('Commencez la conversation !',
                            style: t.textTheme.bodyLarge),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (_, i) {
                        final msg = messages[i];
                        final isMe = myUuid != null && msg.senderId == myUuid;
                        return _MessageBubble(message: msg, isMe: isMe);
                      },
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erreur: $e')),
            ),
          ),
          // Input bar
          Container(
            decoration: BoxDecoration(
              color: t.scaffoldBackgroundColor,
              border: Border(
                top: BorderSide(
                  color: t.isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                ),
              ),
            ),
            padding: EdgeInsets.only(
              left: 12, right: 12, top: 8,
              bottom: MediaQuery.of(context).padding.bottom + 8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      hintText: 'Message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: t.isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF1F5F9),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                    ),
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    gradient: AppTheme.brandGradient,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: _isSending
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send, size: 18, color: Colors.white),
                    onPressed: _isSending ? null : _send,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final isDark = t.brightness == Brightness.dark;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: isMe ? AppTheme.brandGradient : null,
          color: isMe
              ? null
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.content,
              style: t.textTheme.bodyMedium?.copyWith(
                color: isMe ? Colors.white : null,
              ),
            ),
            const SizedBox(height: 2),
            if (message.createdAt != null)
              Text(
                _formatTime(message.createdAt!),
                style: TextStyle(
                  fontSize: 10,
                  color: isMe
                      ? Colors.white.withValues(alpha: 0.7)
                      : t.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
