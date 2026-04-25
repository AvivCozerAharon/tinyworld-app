import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinyworld_app/core/api/rest_client.dart';
import 'package:tinyworld_app/core/storage/local_storage.dart';

class ChatItem {
  final String simId;
  final String otherUserId;
  final String otherAvatar;
  final String otherName;
  final double compatibility;
  final String humanizeState;
  final String ts;
  final String lastMessage;

  const ChatItem({
    required this.simId,
    required this.otherUserId,
    required this.otherAvatar,
    required this.otherName,
    required this.compatibility,
    required this.humanizeState,
    required this.ts,
    this.lastMessage = '',
  });
}

class ChatsState {
  final List<ChatItem> chats;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;

  const ChatsState({
    this.chats = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.error,
  });

  ChatsState copyWith({
    List<ChatItem>? chats,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
  }) =>
      ChatsState(
        chats: chats ?? this.chats,
        isLoading: isLoading ?? this.isLoading,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        hasMore: hasMore ?? this.hasMore,
        error: error,
      );
}

class ChatsController extends StateNotifier<ChatsState> {
  ChatsController() : super(const ChatsState());

  static const _pageSize = 50;

  Future<void> loadChats() async {
    state = state.copyWith(isLoading: true);
    try {
      final resp = await apiClient.get(
        '/chats',
        queryParams: {'limit': _pageSize, 'offset': 0},
      );
      final items = _parseItems(resp.data as List);
      state = state.copyWith(
        chats: items,
        isLoading: false,
        hasMore: items.length == _pageSize,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final resp = await apiClient.get(
        '/chats',
        queryParams: {'limit': _pageSize, 'offset': state.chats.length},
      );
      final newItems = _parseItems(resp.data as List);
      state = state.copyWith(
        chats: [...state.chats, ...newItems],
        isLoadingMore: false,
        hasMore: newItems.length == _pageSize,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  List<ChatItem> _parseItems(List data) => data
      .map((d) => ChatItem(
            simId: d['sim_id'] as String,
            otherUserId: d['other_user_id'] as String? ?? '',
            otherAvatar: d['other_avatar'] as String? ?? '',
            otherName: d['other_name'] as String? ?? '',
            compatibility: (d['compatibility'] as num).toDouble(),
            humanizeState: d['humanize_state'] as String? ?? 'simulated',
            ts: d['ts'] as String? ?? '',
            lastMessage: d['last_message'] as String? ?? '',
          ))
      .toList();

  Future<bool> requestHumanize(String simId) async {
    final userId = await localStorage.getUserId();
    try {
      await apiClient.post('/chats/$simId/humanize/request',
          data: {'user_id': userId});
      final updated = state.chats
          .map((c) => c.simId == simId
              ? ChatItem(
                  simId: c.simId,
                  otherUserId: c.otherUserId,
                  otherAvatar: c.otherAvatar,
                  otherName: c.otherName,
                  compatibility: c.compatibility,
                  humanizeState: 'humanize_pending_sent',
                  ts: c.ts,
                  lastMessage: c.lastMessage)
              : c)
          .toList();
      state = state.copyWith(chats: updated);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> acceptHumanize(String simId) async {
    final userId = await localStorage.getUserId();
    try {
      await apiClient.post('/chats/$simId/humanize/accept',
          data: {'user_id': userId});
      final updated = state.chats
          .map((c) => c.simId == simId
              ? ChatItem(
                  simId: c.simId,
                  otherUserId: c.otherUserId,
                  otherAvatar: c.otherAvatar,
                  otherName: c.otherName,
                  compatibility: c.compatibility,
                  humanizeState: 'humanized',
                  ts: c.ts,
                  lastMessage: c.lastMessage)
              : c)
          .toList();
      state = state.copyWith(chats: updated);
      return true;
    } catch (_) {
      return false;
    }
  }

  void deleteChat(String simId) {
    state = state.copyWith(
      chats: state.chats.where((c) => c.simId != simId).toList(),
    );
  }

  Future<List<String>> getIcebreakers(String simId) async {
    try {
      final resp = await apiClient.get('/chats/$simId/icebreakers');
      final list = resp.data['icebreakers'] as List?;
      return list?.map((e) => e.toString()).toList() ?? [];
    } catch (_) {
      return [];
    }
  }
}

final chatsControllerProvider =
    StateNotifierProvider<ChatsController, ChatsState>(
        (_) => ChatsController());
