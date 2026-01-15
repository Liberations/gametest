import 'package:flutter_test/flutter_test.dart';
import 'package:giftgame/models/grid_cell.dart';
import 'package:giftgame/models/game_state.dart';
import 'package:giftgame/models/player.dart';
import 'package:giftgame/providers/game_provider.dart';

void main() {
  test('start cell is forced to boxOpen when loading game state', () {
    // Prepare grid with a gift under starting player position
    List<List<GridCell>> grid = List.generate(5, (x) => List.generate(8, (y) => GridCell(type: CellType.box1)));
    grid[2][0] = GridCell(type: CellType.gift, isOpened: false, contentId: 'gift_red');
    GameState state = GameState(grid: grid, player: Player(x: 2, y: 0), obtainedGifts: []);
    GameProvider provider = GameProvider();
    provider.setGameStateForTest(state);

    var cell = provider.gameState!.grid[2][0];
    expect(cell.type, equals(CellType.boxOpen));
    expect(cell.isOpened, isTrue);
  });
}

