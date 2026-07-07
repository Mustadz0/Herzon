import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/message_model.dart';

class MessagesState {
  final List<MessageModel> messages;
  final bool isLoading;
  final String? error;

  const MessagesState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
  });

  MessagesState copyWith({
    List<MessageModel>? messages,
    bool? isLoading,
    String? error,
  }) {
    return MessagesState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class MessagesNotifier extends StateNotifier<MessagesState> {
  MessagesNotifier() : super(const MessagesState());

  Future<void> sendMessage(String receiverId, String content) async {
    // Will be implemented with repository
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 300));
    state = state.copyWith(isLoading: false);
  }
}

final messagesProvider = StateNotifierProvider<MessagesNotifier, MessagesState>((ref) {
  return MessagesNotifier();
});
