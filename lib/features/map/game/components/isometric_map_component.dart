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

class IsometricMapComponent extends PositionComponent with HasGameReference {
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
    TileType.grass   => 'city/Roads and Grounds/tile_ground_grass.png',
    TileType.asphalt => 'city/Roads and Grounds/tile_ground_asphalt_normal.png',
    TileType.water   => 'city/Roads and Grounds/tile_ground_water.png',
  };

  @override
  Future<void> onLoad() async {
    final tileSize = Vector2(tileHalfWidth * 2, tileHalfHeight * 2);

    // Ground tiles — rendered back to front via priority = col + row
    for (final tile in layout.tiles) {
      final sprite = await Sprite.load(_assetForTile(tile.type));
      final pos = isoToScreen(tile.col, tile.row, tileHalfWidth, tileHalfHeight, origin);
      add(
        SpriteComponent(
          sprite: sprite,
          position: pos,
          size: tileSize,
          anchor: Anchor.topCenter,
        )..priority = tile.col + tile.row,
      );
    }

    // Buildings — rendered above tiles at same grid position
    for (final bld in layout.buildings) {
      final sprite = await Sprite.load(bld.assetPath);
      final pos = isoToScreen(bld.col, bld.row, tileHalfWidth, tileHalfHeight, origin);
      // Buildings are taller: 2x tile height
      final bldSize = Vector2(tileSize.x, tileSize.y * 2);
      add(
        SpriteComponent(
          sprite: sprite,
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
