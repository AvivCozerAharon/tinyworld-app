import 'package:flame/components.dart';
import 'package:tinyworld_app/features/map/game/map_generator.dart';

// Converts isometric grid (col, row) to screen position.
// origin is the screen position of tile (0,0)'s top corner.
Vector2 isoToScreen(int col, int row, double halfW, double halfH, Vector2 origin) {
  return Vector2(
    origin.x + (col - row) * halfW,
    origin.y + (col + row) * halfH,
  );
}

class IsometricMapComponent extends PositionComponent {
  final MapLayout layout;
  final double tileHalfWidth;
  final double tileHalfHeight;
  final Vector2 origin;

  IsometricMapComponent({
    required this.layout,
    required this.tileHalfWidth,
    required this.tileHalfHeight,
    required this.origin,
  });

  static String _assetForTile(TileType type) => switch (type) {
    TileType.grass   => 'city/grounds/tile_ground_grass.png',
    TileType.asphalt => 'city/grounds/tile_ground_asphalt_normal.png',
    TileType.water   => 'city/grounds/tile_ground_water.png',
  };

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final tileSize = Vector2(tileHalfWidth * 2, tileHalfHeight * 2);

    // Load all distinct sprites concurrently
    final assetPaths = <String>{
      ...layout.tiles.map((t) => _assetForTile(t.type)),
      ...layout.buildings.map((b) => b.assetPath),
    };
    final spriteEntries = await Future.wait(
      assetPaths.map((p) async => MapEntry(p, await Sprite.load(p))),
    );
    final sprites = Map.fromEntries(spriteEntries);

    for (final tile in layout.tiles) {
      final pos = isoToScreen(tile.col, tile.row, tileHalfWidth, tileHalfHeight, origin);
      add(
        SpriteComponent(
          sprite: sprites[_assetForTile(tile.type)]!,
          position: pos,
          size: tileSize,
          anchor: Anchor.topCenter,
        )..priority = tile.col + tile.row,
      );
    }

    for (final bld in layout.buildings) {
      final pos = isoToScreen(bld.col, bld.row, tileHalfWidth, tileHalfHeight, origin);
      final bldSize = Vector2(tileSize.x, tileSize.y * 2);
      add(
        SpriteComponent(
          sprite: sprites[bld.assetPath]!,
          position: pos,
          size: bldSize,
          anchor: Anchor.bottomCenter,
        )..priority = bld.col + bld.row + 1,
      );
    }
  }

  // Returns the screen center of a grid tile (for NPC placement).
  Vector2 tileCenter(int col, int row) {
    return isoToScreen(col, row, tileHalfWidth, tileHalfHeight, origin)
      + Vector2(0, tileHalfHeight); // shift down to visual center of diamond
  }
}
