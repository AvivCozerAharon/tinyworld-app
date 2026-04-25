import 'dart:math';

enum TileType { grass, asphalt, water }

class MapTile {
  final int col;
  final int row;
  final TileType type;
  const MapTile({required this.col, required this.row, required this.type});
}

class BuildingPlacement {
  final int col;
  final int row;
  final String assetPath;
  const BuildingPlacement({
    required this.col,
    required this.row,
    required this.assetPath,
  });
}

class MapLayout {
  final List<MapTile> tiles;
  final List<BuildingPlacement> buildings;
  final List<(int col, int row)> npcSlots;
  const MapLayout({
    required this.tiles,
    required this.buildings,
    required this.npcSlots,
  });
}

class MapGenerator {
  static const int gridSize = 9;

  static const List<String> _buildingAssets = [
    'city/Buildings/bld_cafe_pink_SE_normal.png',
    'city/Buildings/bld_house2_blue_SE_normal.png',
    'city/Buildings/bld_house2_brown_SE_normal.png',
    'city/Buildings/bld_barbershop_purple_SE_normal.png',
    'city/Buildings/bld_clinic_mint_SE_normal.png',
    'city/Buildings/bld_gasstation_green_SE_normal.png',
    'city/Buildings/bld_house3_blue_SE_normal.png',
    'city/Buildings/bld_house3_green_SE_normal.png',
    'city/Buildings/bld_fruitstand_neutral_SE_normal.png',
    'city/Buildings/bld_barn_red_SE_normal.png',
  ];

  MapLayout generate(int seed) {
    final rng = Random(seed);
    final grid = List.generate(gridSize, (_) => List.filled(gridSize, TileType.grass));

    // L-shaped asphalt road
    final roadRow = 2 + rng.nextInt(4);
    final roadCol = 2 + rng.nextInt(4);
    for (int c = 0; c < gridSize; c++) grid[roadRow][c] = TileType.asphalt;
    for (int r = 0; r < gridSize; r++) grid[r][roadCol] = TileType.asphalt;

    // 2x2 water cluster in a random corner
    final corners = [
      (0, 0),
      (0, gridSize - 2),
      (gridSize - 2, 0),
      (gridSize - 2, gridSize - 2),
    ];
    final (wr, wc) = corners[rng.nextInt(corners.length)];
    for (int dr = 0; dr < 2; dr++) {
      for (int dc = 0; dc < 2; dc++) {
        grid[wr + dr][wc + dc] = TileType.water;
      }
    }

    // Buildings on grass tiles adjacent to asphalt
    final occupied = <(int, int)>{};
    final buildings = <BuildingPlacement>[];
    final shuffledAssets = List<String>.from(_buildingAssets)..shuffle(rng);

    for (int r = 0; r < gridSize && buildings.length < 8; r++) {
      for (int c = 0; c < gridSize && buildings.length < 8; c++) {
        if (grid[r][c] != TileType.grass) continue;
        if (!_adjacentToAsphalt(grid, r, c)) continue;
        buildings.add(BuildingPlacement(
          col: c,
          row: r,
          assetPath: shuffledAssets[buildings.length % shuffledAssets.length],
        ));
        occupied.add((r, c));
      }
    }

    // NPC slots: free grass tiles not occupied by buildings
    final npcSlots = <(int, int)>[];
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        if (grid[r][c] == TileType.grass && !occupied.contains((r, c))) {
          npcSlots.add((c, r));
        }
      }
    }
    npcSlots.shuffle(rng);

    final tiles = <MapTile>[];
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        tiles.add(MapTile(col: c, row: r, type: grid[r][c]));
      }
    }

    return MapLayout(
      tiles: tiles,
      buildings: buildings,
      npcSlots: npcSlots.take(10).toList(),
    );
  }

  bool _adjacentToAsphalt(List<List<TileType>> grid, int r, int c) {
    for (final (dr, dc) in [(-1, 0), (1, 0), (0, -1), (0, 1)]) {
      final nr = r + dr;
      final nc = c + dc;
      if (nr >= 0 && nr < gridSize && nc >= 0 && nc < gridSize) {
        if (grid[nr][nc] == TileType.asphalt) return true;
      }
    }
    return false;
  }
}
