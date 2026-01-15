import 'package:flutter_test/flutter_test.dart';
import 'package:giftgame/models/grid_cell.dart';
import 'package:giftgame/models/game_state.dart';
import 'package:giftgame/models/player.dart';
import 'package:giftgame/providers/game_provider.dart';

void main() {
  group('GameProvider.movePlayer', () {
    test('opens gift only at player position and stores gift id', () {
      // Prepare grid: all box1
      List<List<GridCell>> grid = List.generate(5, (x) => List.generate(8, (y) => GridCell(type: CellType.box1)));
      // Set a gift at (2,0)
      grid[2][0] = GridCell(type: CellType.gift, isOpened: false, contentId: 'gift_red');
      // Set a monster at (1,0)
      grid[1][0] = GridCell(type: CellType.monster, isOpened: false);
      // Set a door at (3,0)
      grid[3][0] = GridCell(type: CellType.door, isOpened: false);

      GameState state = GameState(grid: grid, player: Player(x: 2, y: -1), obtainedGifts: []);
      GameProvider provider = GameProvider();
      provider.setGameStateForTest(state);

      // Move down into gift at (2,0)
      List<CellType> opened = provider.movePlayer(0, 1);
      expect(opened.length, 1);
      expect(opened[0], CellType.gift);
      expect(provider.gameState!.grid[2][0].isOpened, isTrue);
      expect(provider.gameState!.player.steps, equals(19));
      expect(provider.gameState!.obtainedGifts.contains('gift_red'), isTrue);
      expect(provider.lastOpenedContentId, equals('gift_red'));

      // Move left into monster at (1,0)
      opened = provider.movePlayer(-1, 0);
      expect(opened.length, 1);
      expect(opened[0], CellType.monster);
      expect(provider.gameState!.grid[1][0].isOpened, isTrue);
      expect(provider.gameState!.player.health, equals(9));

      // Move right twice to (3,0) door
      opened = provider.movePlayer(2, 0);
      expect(opened.length, 1);
      expect(opened[0], CellType.door);
      expect(provider.gameState!.grid[3][0].isOpened, isTrue);
    });

    test('does nothing when stepping into already opened cell', () {
      List<List<GridCell>> grid = List.generate(5, (x) => List.generate(8, (y) => GridCell(type: CellType.box1)));
      grid[0][0] = GridCell(type: CellType.gift, isOpened: true, contentId: 'gift_blue');
      GameState state = GameState(grid: grid, player: Player(x: 0, y: -1), obtainedGifts: ['gift_blue']);
      GameProvider provider = GameProvider();
      provider.setGameStateForTest(state);

      List<CellType> opened = provider.movePlayer(0, 1); // move into already opened gift
      expect(opened.isEmpty, isTrue);
      expect(provider.gameState!.player.steps, equals(19));
      // obtained gifts should not add another entry
      expect(provider.gameState!.obtainedGifts.where((id) => id == 'gift_blue').length, equals(1));
    });

    test('horizontal move from spawn enters row 0 and opens cell', () {
      List<List<GridCell>> grid = List.generate(5, (x) => List.generate(8, (y) => GridCell(type: CellType.box1)));
      GameState state = GameState(grid: grid, player: Player(x: 2, y: -1), obtainedGifts: []);
      GameProvider provider = GameProvider();
      provider.setGameStateForTest(state);

      // move right from spawn
      List<CellType> opened = provider.movePlayer(1, 0);
      expect(provider.gameState!.player.x, equals(3));
      expect(provider.gameState!.player.y, equals(0));
      expect(provider.gameState!.grid[3][0].isOpened, isTrue);
      expect(opened.isNotEmpty, isTrue);
      expect(provider.gameState!.player.steps, equals(19));
    });
  });
}
