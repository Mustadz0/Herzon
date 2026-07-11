import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/messenger_provider.dart';
import '../../data/models/message_model.dart';
import '../screens/conversation_screen.dart';

class ConversationsListWidget extends ConsumerWidget {
  final ScrollController? scrollController;

  const ConversationsListWidget({super.key, this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationsProvider);

    return conversationsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text('Erreur: $e', style: GoogleFonts.plusJakartaSans(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(conversationsProvider.notifier).loadConversations(),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
      data: (conversations) => conversations.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[600]),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune conversation',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white70,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: conversations.length,
              itemBuilder: (context, index) {
                final conv = conversations[index];
                return _ConversationTile(conv: conv);
              },
            ),
    );
  }
}

class _ConversationTile extends ConsumerWidget {
  final ConversationModel conv;
  const _ConversationTile({required this.conv});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasUnread = conv.unreadCount > 0;
    final timeStr = conv.lastMessageAt != null ? _formatTime(conv.lastMessageAt!) : '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: hasUnread ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ConversationScreen(conversationId: conv.id, otherUserId: conv.otherUserId, otherUserName: conv.otherUserName ?? 'Utilisateur'))),
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: Colors.white.withValues(alpha: 0.1),
          backgroundImage: conv.otherUserAvatar != null
              ? NetworkImage(conv.otherUserAvatar!)
              : null,
          child: conv.otherUserAvatar == null
              ? Icon(Icons.person, color: Colors.white.withValues(alpha: 0.5))
              : null,
        ),
        title: Text(
          conv.otherUserName ?? 'Utilisateur',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w500,
            color: Colors.white,
            fontSize: 15,
          ),
        ),
        subtitle: conv.lastMessage != null
            ? Text(
                conv.lastMessage!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 13,
                ),
              )
            : null,
        trailing: conv.lastMessageAt != null
            ? Text(
                timeStr,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 11,
                ),
              )
            : null,
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'maintenant';
    if (diff.inHours < 1) return '${diff.inMinutes}min';
    if (diff.inDays < 1) return DateFormat('HH:mm').format(dt);
    return DateFormat('dd/MM').format(dt);
  }
}
