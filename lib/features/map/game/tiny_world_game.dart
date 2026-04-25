import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:tinyworld_app/features/map/game/components/npc_component.dart';
import 'package:tinyworld_app/features/map/map_controller.dart';

class TinyWorldGame extends FlameGame {
  static const double _zoom = 3.5;
  static const double _tileSize = 8.0;
  static const double _camCenterCol = 27.0;
  static const double _camCenterRow = 15.0;

  // Open ground tiles visible in the camera window (cols ~20–34, all rows).
  // Adjust any slot that visually lands on a building/prop after first run.
  static final Vector2 _worldCenter = Vector2(_camCenterCol * _tileSize, _camCenterRow * _tileSize);

  static const List<(int, int)> _npcSlots = [
    (22, 4),  (24, 7),  (26, 2),  (28, 5),  (30, 9),
    (21, 12), (25, 15), (27, 18), (29, 22), (23, 25),
    (31, 11), (20, 19),
  ];

  final Map<String, NpcComponent> _npcs = {};
  final Map<String, (int, int)> _npcSlotAssignments = {};

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final tiled = await TiledComponent.load(
      'sample-map.tmx',
      Vector2.all(_tileSize),
      prefix: 'assets/city/Tiled/',
    );
    world.add(tiled);
    camera.viewfinder.zoom = _zoom;
    camera.viewfinder.anchor = Anchor.center;
    camera.viewfinder.position = Vector2(
      _camCenterCol * _tileSize,
      _camCenterRow * _tileSize,
    );
  }

  Vector2 _tileCenter(int col, int row) => Vector2(
    col * _tileSize + _tileSize / 2,
    row * _tileSize + _tileSize / 2,
  );

  // World → screen using the fixed camera constants.
  Vector2 _worldToScreen(Vector2 worldPos) {
    final screenCenter = size / 2;
    return (worldPos - _worldCenter) * _zoom + screenCenter;
  }

  (int, int)? _nextFreeSlot() {
    final usedSlots = _npcSlotAssignments.values.toSet();
    for (final slot in _npcSlots) {
      if (!usedSlots.contains(slot)) return slot;
    }
    return null;
  }

  void updateState(MapState state) {
    if (size == Vector2.zero()) return;
    final activeIds = state.activeSimulations.map((s) => s.jobId).toSet();

    _npcs.removeWhere((id, npc) {
      if (!activeIds.contains(id)) {
        npc.removeFromParent();
        _npcSlotAssignments.remove(id);
        return true;
      }
      return false;
    });

    for (final sim in state.activeSimulations) {
      if (!_npcSlotAssignments.containsKey(sim.jobId)) {
        final slot = _nextFreeSlot();
        if (slot == null) continue;
        _npcSlotAssignments[sim.jobId] = slot;
      }

      final slot = _npcSlotAssignments[sim.jobId]!;
      final screenPos = _worldToScreen(_tileCenter(slot.$1, slot.$2));

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
