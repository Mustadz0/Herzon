import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/messenger_provider.dart';
import '../../data/models/message_model.dart';
import 'conversation_screen.dart';

class ConversationsListScreen extends ConsumerStatefulWidget {
  const ConversationsListScreen({super.key});

  @override
  ConsumerState<ConversationsListScreen> createState() => _ConversationsListScreenState();
}

class _ConversationsListScreenState extends ConsumerState<ConversationsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(conversationsProvider.notifier).loadConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final conversationsAsync = ref.watch(conversationsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          color: const Color(0xFF1E293B),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Messages',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
        centerTitle: true,
      ),
      body: conversationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5))),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Color(0xFFEF4444)),
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
        data: (conversations) => RefreshIndicator(
          onRefresh: () => ref.read(conversationsProvider.notifier).loadConversations(),
          child: conversations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[200]),
                      const SizedBox(height: 20),
                      Text(
                        'Aucune conversation',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Envoyez un message depuis un profil',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: conversations.length,
                  itemBuilder: (context, index) {
                    final conv = conversations[index];
                    return _buildConversationTile(conv);
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildConversationTile(ConversationModel conv) {
    final hasUnread = conv.unreadCount > 0;
    final timeStr = conv.lastMessageAt != null
        ? _formatTime(conv.lastMessageAt!)
        : '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: hasUnread ? const Color(0xFF4F46E5).withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: () => _openConversation(conv),
        contentPadding: const EdgeInsets.all(12),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundImage: conv.otherUserAvatar != null
                  ? NetworkImage(conv.otherUserAvatar!)
                  : null,
              backgroundColor: const Color(0xFF4F46E5).withValues(alpha: 0.1),
              child: conv.otherUserAvatar == null
                  ? Text(
                      (conv.otherUserName ?? '?')[0].toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: const Color(0xFF4F46E5),
                      ),
                    )
                  : null,
            ),
            if (hasUnread)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFF4F46E5),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    conv.unreadCount.toString(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          conv.otherUserName ?? 'Utilisateur inconnu',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600,
            fontSize: 15,
            color: const Color(0xFF1E293B),
          ),
        ),
        subtitle: Text(
          conv.lastMessage ?? 'Aucun message',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: hasUnread ? const Color(0xFF4F46E5) : const Color(0xFF94A3B8),
            fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: timeStr.isNotEmpty
            ? Text(
                timeStr,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: hasUnread ? const Color(0xFF4F46E5) : const Color(0xFF94A3B8),
                  fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                ),
              )
            : null,
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inDays == 0) {
      return DateFormat('HH:mm').format(time);
    } else if (diff.inDays == 1) {
      return 'Hier';
    } else if (diff.inDays < 7) {
      return DateFormat('EEEE', 'fr').format(time);
    } else {
      return DateFormat('dd/MM').format(time);
    }
  }

  void _openConversation(ConversationModel conv) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConversationScreen(
          conversationId: conv.id,
          otherUserId: conv.otherUserId,
          otherUserName: conv.otherUserName ?? 'Utilisateur',
        ),
      ),
    ).then((_) {
      ref.read(conversationsProvider.notifier).loadConversations();
    });
  }
}
