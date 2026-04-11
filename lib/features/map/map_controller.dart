import 'dart:convert';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinyworld_app/core/api/rest_client.dart';
import 'package:tinyworld_app/core/storage/local_storage.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class SimulationEntry {
  final String jobId;
  final String otherUserId;
  final double x;
  final double y;
  SimulationStatus status;
  double? compatibility;
  String? activeAgentId;

  SimulationEntry({
    required this.jobId,
    required this.otherUserId,
    required this.x,
    required this.y,
    this.status = SimulationStatus.chatting,
    this.compatibility,
    this.activeAgentId,
  });

  SimulationEntry copyWith({
    SimulationStatus? status,
    double? compatibility,
    String? activeAgentId,
  }) =>
      SimulationEntry(
        jobId: jobId,
        otherUserId: otherUserId,
        x: x,
        y: y,
        status: status ?? this.status,
        compatibility: compatibility ?? this.compatibility,
        activeAgentId: activeAgentId ?? this.activeAgentId,
      );
}

enum SimulationStatus { chatting, completed }

class MapState {
  final String? sessionId;
  final List<SimulationEntry> activeSimulations;
  final bool isSearching;
  final bool searchDone;

  const MapState({
    this.sessionId,
    this.activeSimulations = const [],
    this.isSearching = false,
    this.searchDone = false,
  });

  MapState copyWith({
    String? sessionId,
    List<SimulationEntry>? activeSimulations,
    bool? isSearching,
    bool? searchDone,
  }) =>
      MapState(
        sessionId: sessionId ?? this.sessionId,
        activeSimulations: activeSimulations ?? this.activeSimulations,
        isSearching: isSearching ?? this.isSearching,
        searchDone: searchDone ?? this.searchDone,
      );
}

class MapController extends StateNotifier<MapState> {
  WebSocketChannel? _channel;
  final _rng = Random();

  MapController() : super(const MapState());

  void handleEvent(Map<String, dynamic> event) {
    final type = event['event'] as String;
    switch (type) {
      case 'sim.started':
        final entry = SimulationEntry(
          jobId: event['job_id'] as String,
          otherUserId: event['other_user_id'] as String,
          x: 0.2 + _rng.nextDouble() * 0.6,
          y: 0.2 + _rng.nextDouble() * 0.6,
        );
        state = state.copyWith(
          activeSimulations: [...state.activeSimulations, entry],
        );
      case 'sim.turn.start':
        final jobId = event['job_id'] as String;
        final agentId = event['agent_id'] as String?;
        final updated = state.activeSimulations.map((s) {
          if (s.jobId != jobId) return s;
          return s.copyWith(activeAgentId: agentId);
        }).toList();
        state = state.copyWith(activeSimulations: updated);
      case 'sim.turn.complete':
        final jobId = event['job_id'] as String;
        final updated = state.activeSimulations.map((s) {
          if (s.jobId != jobId) return s;
          return s.copyWith(activeAgentId: null);
        }).toList();
        state = state.copyWith(activeSimulations: updated);
      case 'sim.completed':
        final jobId = event['job_id'] as String;
        final updated = state.activeSimulations.map((s) {
          if (s.jobId != jobId) return s;
          return SimulationEntry(
            jobId: s.jobId,
            otherUserId: s.otherUserId,
            x: s.x,
            y: s.y,
            status: SimulationStatus.completed,
            compatibility: (event['compatibility'] as num).toDouble(),
          );
        }).toList();
        state = state.copyWith(activeSimulations: updated);
      case 'sim.failed':
        final jobId = event['job_id'] as String;
        final updated = state.activeSimulations
            .where((s) => s.jobId != jobId)
            .toList();
        state = state.copyWith(activeSimulations: updated);
    }
  }

  Future<void> startSearch() async {
    final userId = await localStorage.getUserId();
    if (userId == null) return;
    final resp =
        await apiClient.post('/search/start', data: {'user_id': userId});
    final sessionId = resp.data['session_id'] as String;
    state = state.copyWith(sessionId: sessionId, isSearching: true, searchDone: false);
    _connectWebSocket(sessionId);
  }

  void _connectWebSocket(String sessionId) {
    final wsBase = apiClient.baseUrl.replaceFirst('http', 'ws');
    _channel = WebSocketChannel.connect(
        Uri.parse('$wsBase/ws/stream/$sessionId'));
    _channel!.stream.cast<String>().listen((raw) {
      final event = jsonDecode(raw) as Map<String, dynamic>;
      handleEvent(event);
    }, onDone: () {
      if (mounted) {
        state = state.copyWith(isSearching: false, searchDone: true);
      }
    }, onError: (_) {
      if (mounted) {
        state = state.copyWith(isSearching: false, searchDone: true);
      }
    });
  }

  Future<void> stopSearch() async {
    final userId = await localStorage.getUserId();
    if (userId != null) {
      await apiClient.delete('/search/stop', queryParams: {'user_id': userId});
    }
    _channel?.sink.close();
    state = const MapState();
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }
}

final mapControllerProvider =
    StateNotifierProvider<MapController, MapState>((_) => MapController());
