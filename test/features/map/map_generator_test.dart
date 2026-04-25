import 'package:flutter_test/flutter_test.dart';
import 'package:tinyworld_app/features/map/game/map_generator.dart';

void main() {
  late MapGenerator generator;

  setUp(() => generator = MapGenerator());

  group('MapGenerator', () {
    test('generates exactly gridSize*gridSize tiles', () {
      final layout = generator.generate(42);
      expect(layout.tiles.length, equals(MapGenerator.gridSize * MapGenerator.gridSize));
    });

    test('all tiles are within grid bounds', () {
      final layout = generator.generate(42);
      for (final tile in layout.tiles) {
        expect(tile.col, inInclusiveRange(0, MapGenerator.gridSize - 1));
        expect(tile.row, inInclusiveRange(0, MapGenerator.gridSize - 1));
      }
    });

    test('generates at least 4 and at most 10 buildings', () {
      final layout = generator.generate(42);
      expect(layout.buildings.length, inInclusiveRange(8, 10));
    });

    test('buildings only placed on grass tiles', () {
      final layout = generator.generate(42);
      final asphaltAndWater = layout.tiles
          .where((t) => t.type == TileType.asphalt || t.type == TileType.water)
          .map((t) => (t.col, t.row))
          .toSet();
      for (final b in layout.buildings) {
        expect(asphaltAndWater.contains((b.col, b.row)), isFalse);
      }
    });

    test('npc slots are on grass and not occupied by buildings', () {
      final layout = generator.generate(42);
      final buildingPositions = layout.buildings.map((b) => (b.col, b.row)).toSet();
      final asphaltAndWater = layout.tiles
          .where((t) => t.type != TileType.grass)
          .map((t) => (t.col, t.row))
          .toSet();
      for (final slot in layout.npcSlots) {
        expect(buildingPositions.contains(slot), isFalse);
        expect(asphaltAndWater.contains(slot), isFalse);
      }
    });

    test('same seed produces same layout', () {
      final a = generator.generate(99);
      final b = generator.generate(99);
      expect(a.tiles.map((t) => t.type).toList(),
          equals(b.tiles.map((t) => t.type).toList()));
    });

    test('different seeds produce different layouts', () {
      final a = generator.generate(1);
      final b = generator.generate(2);
      final typesA = a.tiles.map((t) => t.type).toList();
      final typesB = b.tiles.map((t) => t.type).toList();
      expect(typesA, isNot(equals(typesB)));
    });
  });
}
