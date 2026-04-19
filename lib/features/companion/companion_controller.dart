import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinyworld_app/core/api/rest_client.dart';

class CompanionMessage {
  final String role; // 'user' or 'assistant'
  final String content;

  const CompanionMessage({required this.role, required this.content});
}

class CompanionState {
  final List<CompanionMessage> messages;
  final bool isLoading;
  final bool isSending;

  const CompanionState({
    this.messages = const [],
    this.isLoading = false,
    this.isSending = false,
  });

  CompanionState copyWith({
    List<CompanionMessage>? messages,
    bool? isLoading,
    bool? isSending,
  }) =>
      CompanionState(
        messages: messages ?? this.messages,
        isLoading: isLoading ?? this.isLoading,
        isSending: isSending ?? this.isSending,
      );
}

class CompanionController extends StateNotifier<CompanionState> {
  CompanionController() : super(const CompanionState());

  Future<void> loadHistory() async {
    state = state.copyWith(isLoading: true);
    try {
      final resp = await apiClient.get('/companion/chat/history');
      final list = (resp.data as List?) ?? [];
      final messages = list
          .map((m) => CompanionMessage(
                role: m['role'] as String,
                content: m['content'] as String,
              ))
          .toList();
      state = state.copyWith(messages: messages, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || state.isSending) return;

    final userMsg = CompanionMessage(role: 'user', content: text.trim());
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isSending: true,
    );

    try {
      final resp = await apiClient.post(
        '/companion/chat',
        data: {'message': text.trim()},
      );
      final reply = resp.data['reply'] as String? ?? '...';
      final assistantMsg = CompanionMessage(role: 'assistant', content: reply);
      state = state.copyWith(
        messages: [...state.messages, assistantMsg],
        isSending: false,
      );
    } catch (_) {
      state = state.copyWith(isSending: false);
    }
  }

  Future<void> clearHistory() async {
    try {
      await apiClient.delete('/companion/chat/history');
      state = state.copyWith(messages: []);
    } catch (_) {}
  }
}

final companionControllerProvider =
    StateNotifierProvider<CompanionController, CompanionState>(
        (_) => CompanionController());
