import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinyworld_app/core/api/rest_client.dart';
import 'package:tinyworld_app/core/storage/local_storage.dart';
import 'map_ws_service.dart';

enum SimulationStatus { chatting, completed }

enum MapZone { forest, town, lake, meadow }

class SimulationEntry {
  final String jobId;
  final String otherUserId;
  final double x;
  final double y;
  final MapZone zone;
  final SimulationStatus status;
  final double? compatibility;
  final String? activeAgentId;
  final String? lastTurnText;

  const SimulationEntry({
    required this.jobId,
    required this.otherUserId,
    required this.x,
    required this.y,
    required this.zone,
    this.status = SimulationStatus.chatting,
    this.compatibility,
    this.activeAgentId,
    this.lastTurnText,
  });

  SimulationEntry copyWith({
    SimulationStatus? status,
    double? compatibility,
    String? activeAgentId,
    bool clearActiveAgent = false,
    String? lastTurnText,
    bool clearTurnText = false,
  }) =>
      SimulationEntry(
        jobId: jobId,
        otherUserId: otherUserId,
        x: x,
        y: y,
        zone: zone,
        status: status ?? this.status,
        compatibility: compatibility ?? this.compatibility,
        activeAgentId: clearActiveAgent ? null : (activeAgentId ?? this.activeAgentId),
        lastTurnText: clearTurnText ? null : (lastTurnText ?? this.lastTurnText),
      );
}

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

MapZone _zoneFor(String userId) {
  final hash = userId.codeUnits.fold(0, (a, b) => a ^ b);
  return MapZone.values[hash.abs() % MapZone.values.length];
}

(double, double) _positionInZone(MapZone zone, String jobId) {
  final rng = Random(jobId.hashCode);
  return switch (zone) {
    MapZone.forest => (0.05 + rng.nextDouble() * 0.17, 0.30 + rng.nextDouble() * 0.22),
    MapZone.town   => (0.22 + rng.nextDouble() * 0.23, 0.50 + rng.nextDouble() * 0.20),
    MapZone.lake   => (0.65 + rng.nextDouble() * 0.25, 0.52 + rng.nextDouble() * 0.24),
    MapZone.meadow => (0.15 + rng.nextDouble() * 0.40, 0.74 + rng.nextDouble() * 0.14),
  };
}

class MapController extends StateNotifier<MapState> {
  MapWsService? _wsService;

  MapController() : super(const MapState());

  void _handleEvent(Map<String, dynamic> event) {
    final type = event['event'] as String?;
    switch (type) {
      case 'sim.started':
        final jobId = event['job_id'] as String;
        final otherUserId = event['other_user_id'] as String;
        final zone = _zoneFor(otherUserId);
        final (x, y) = _positionInZone(zone, jobId);
        state = state.copyWith(
          activeSimulations: [
            ...state.activeSimulations,
            SimulationEntry(jobId: jobId, otherUserId: otherUserId, x: x, y: y, zone: zone),
          ],
        );

      case 'sim.turn.start':
        final jobId = event['job_id'] as String?;
        if (jobId == null) return;
        final agentId = event['agent_id'] as String?;
        state = state.copyWith(
          activeSimulations: state.activeSimulations.map((s) {
            if (s.jobId != jobId) return s;
            return s.copyWith(activeAgentId: agentId, clearTurnText: true);
          }).toList(),
        );

      case 'sim.turn.complete':
        final jobId = event['job_id'] as String?;
        if (jobId == null) return;
        final turn = event['turn'] as Map<String, dynamic>?;
        final raw = turn?['resposta'] as String?;
        final text = raw != null && raw.length > 60 ? '${raw.substring(0, 57)}...' : raw;
        state = state.copyWith(
          activeSimulations: state.activeSimulations.map((s) {
            if (s.jobId != jobId) return s;
            return s.copyWith(clearActiveAgent: true, lastTurnText: text);
          }).toList(),
        );

      case 'sim.completed':
        final jobId = event['job_id'] as String;
        state = state.copyWith(
          activeSimulations: state.activeSimulations.map((s) {
            if (s.jobId != jobId) return s;
            return SimulationEntry(
              jobId: s.jobId,
              otherUserId: s.otherUserId,
              x: s.x,
              y: s.y,
              zone: s.zone,
              status: SimulationStatus.completed,
              compatibility: (event['compatibility'] as num).toDouble(),
            );
          }).toList(),
        );

      case 'sim.failed':
        final jobId = event['job_id'] as String;
        state = state.copyWith(
          activeSimulations: state.activeSimulations.where((s) => s.jobId != jobId).toList(),
        );
    }
  }

  Future<void> startSearch() async {
    final userId = await localStorage.getUserId();
    if (userId == null) return;
    final resp = await apiClient.post('/search/start', data: {'user_id': userId});
    final sessionId = resp.data['session_id'] as String;
    state = state.copyWith(sessionId: sessionId, isSearching: true, searchDone: false);

    final wsBase = apiClient.baseUrl.replaceFirst('http', 'ws');
    final token = await localStorage.getIdToken() ?? '';
    _wsService = MapWsService(sessionId: sessionId, token: token, wsBaseUrl: wsBase);
    _wsService!.events.listen(
      _handleEvent,
      onDone: () {
        if (mounted) state = state.copyWith(isSearching: false, searchDone: true);
      },
    );
    _wsService!.connect();
  }

  Future<void> stopSearch() async {
    final userId = await localStorage.getUserId();
    if (userId != null) {
      await apiClient.delete('/search/stop', queryParams: {'user_id': userId});
    }
    _wsService?.dispose();
    _wsService = null;
    state = const MapState();
  }

  @override
  void dispose() {
    _wsService?.dispose();
    super.dispose();
  }
}

final mapControllerProvider =
    StateNotifierProvider<MapController, MapState>((_) => MapController());
