import 'dart:math';
import 'package:flame/game.dart';
import 'package:tinyworld_app/features/map/game/components/isometric_map_component.dart';
import 'package:tinyworld_app/features/map/game/components/npc_component.dart';
import 'package:tinyworld_app/features/map/game/map_generator.dart';
import 'package:tinyworld_app/features/map/map_controller.dart';

class TinyWorldGame extends FlameGame {
  final _generator = MapGenerator();
  MapLayout? _layout;
  IsometricMapComponent? _mapComponent;

  final Map<String, NpcComponent> _npcs = {};
  final Map<String, (int col, int row)> _npcSlots = {};

  double _tileHalfWidth = 32;
  double _tileHalfHeight = 16;
  Vector2 _origin = Vector2.zero();

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    images.prefix = 'assets/';
    _generateAndRenderMap();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _tileHalfWidth = (size.x - 16) / (2 * (MapGenerator.gridSize - 1));
    _tileHalfHeight = _tileHalfWidth / 2;
    _origin = Vector2(size.x / 2, _tileHalfHeight * 2);
  }

  void _generateAndRenderMap() {
    final seed = Random().nextInt(100000);
    _layout = _generator.generate(seed);

    _mapComponent = IsometricMapComponent(
      layout: _layout!,
      tileHalfWidth: _tileHalfWidth,
      tileHalfHeight: _tileHalfHeight,
      origin: _origin,
    );
    add(_mapComponent!);
  }

  (int col, int row)? _nextFreeSlot(MapLayout layout) {
    final usedSlots = _npcSlots.values.toSet();
    for (final slot in layout.npcSlots) {
      if (!usedSlots.contains(slot)) return slot;
    }
    return null;
  }

  void updateState(MapState state) {
    final map = _mapComponent;
    final layout = _layout;
    if (map == null || layout == null) return;

    final activeIds = state.activeSimulations.map((s) => s.jobId).toSet();

    _npcs.removeWhere((id, npc) {
      if (!activeIds.contains(id)) {
        npc.removeFromParent();
        _npcSlots.remove(id);
        return true;
      }
      return false;
    });

    for (final sim in state.activeSimulations) {
      if (!_npcSlots.containsKey(sim.jobId)) {
        final slot = _nextFreeSlot(layout);
        if (slot == null) continue;
        _npcSlots[sim.jobId] = slot;
      }

      final slot = _npcSlots[sim.jobId]!;
      final screenPos = map.tileCenter(slot.$1, slot.$2);

      if (_npcs.containsKey(sim.jobId)) {
        _npcs[sim.jobId]!.updateFrom(sim);
      } else {
        final npc = NpcComponent(sim, screenPos);
        npc.priority = slot.$1 + slot.$2 + 2;
        _npcs[sim.jobId] = npc;
        add(npc);
      }
    }
  }
}
