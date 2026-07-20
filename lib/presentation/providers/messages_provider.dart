// This file is intentionally replaced.
// The real messagesProvider lives in messenger_provider.dart
// (StateNotifierProvider.family keyed by conversationId).
//
// Keeping this file to avoid breaking any existing import, but
// re-exporting from messenger_provider so there is only ONE
// source of truth.
export 'messenger_provider.dart'
    show
        messagesProvider,
        MessagesNotifier,
        conversationsProvider,
        ConversationsNotifier,
        messageRepositoryProvider,
        currentConversationIdProvider,
        totalUnreadProvider;
