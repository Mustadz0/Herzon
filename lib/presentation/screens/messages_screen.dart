import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/firebase_uuid.dart';
import '../providers/messenger_provider.dart';
import 'conversation_screen.dart';
import 'search_screen.dart';

extension _ThemeDark on ThemeData {
  bool get isDark => brightness == Brightness.dark;
}

class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    // FIX: FirebaseAuth + UUID
    final firebaseUid = FirebaseAuth.instance.currentUser?.uid;
    final myId = firebaseUid != null ? FirebaseUuid.toUuid(firebaseUid) : null;
    final convsAsync = ref.watch(conversationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            ),
          ),
        ],
      ),
      body: convsAsync.when(
        data: (convs) => convs.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.chat_bubble_outline, size: 56,
                      color: t.colorScheme.onSurfaceVariant),
                    const SizedBox(height: 12),
                    Text('Aucune conversation', style: t.textTheme.bodyLarge),
                    const SizedBox(height: 4),
                    Text('Cherchez quelqu\'un pour commencer',
                      style: t.textTheme.bodySmall),
                  ],
                ),
              )
            : ListView.separated(
                itemCount: convs.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final conv = convs[i];
                  final isUnread = conv.unreadCount > 0;
                  return ListTile(
                    leading: Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: conv.otherUserAvatar == null
                            ? AppTheme.brandGradient
                            : null,
                      ),
                      child: conv.otherUserAvatar != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Image.network(
                                conv.otherUserAvatar!, fit: BoxFit.cover))
                          : const Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(
                      conv.otherUserName ?? 'Utilisateur',
                      style: TextStyle(
                        fontWeight: isUnread
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      conv.lastMessage ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isUnread
                            ? t.colorScheme.onSurface
                            : t.colorScheme.onSurfaceVariant,
                        fontWeight: isUnread
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (conv.lastMessageAt != null)
                          Text(_formatTime(conv.lastMessageAt!),
                            style: t.textTheme.bodySmall?.copyWith(
                              color: isUnread
                                  ? AppTheme.primary
                                  : t.colorScheme.onSurfaceVariant,
                              fontWeight: isUnread
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            )),
                        if (isUnread) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${conv.unreadCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ConversationScreen(
                          conversationId: conv.id,
                          otherUserId: conv.otherUserId,
                          otherUserName: conv.otherUserName ?? 'Utilisateur',
                          otherUserAvatar: conv.otherUserAvatar,
                        ),
                      ),
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}min';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}j';
    return '${dt.day}/${dt.month}';
  }
}
