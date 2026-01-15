import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'grid_cell.dart';
import 'player.dart';

class GameState {
  int level;
  List<List<GridCell>> grid; // 5x8
  Player player;
  List<String> obtainedGifts; // list of gift ids

  GameState({
    this.level = 1,
    required this.grid,
    required this.player,
    this.obtainedGifts = const [],
  });

  // Generate random grid with exactly one door
  static List<List<GridCell>> generateGrid() {
    final rand = Random();
    // Example gift ids we may pick from (match UI mapping)
    List<String> giftIds = ['gift_1', 'gift_2', 'gift_3'];

    List<List<GridCell>> newGrid = List.generate(5, (i) => List.generate(8, (j) => GridCell(type: CellType.box1, isOpened: false)));

    // Place exactly one door at a random position
    int doorX = rand.nextInt(5);
    int doorY = rand.nextInt(8);
    newGrid[doorX][doorY] = GridCell(type: CellType.door, isOpened: false);

    // Fill other cells with probabilistic contents
    for (int i = 0; i < 5; i++) {
      for (int j = 0; j < 8; j++) {
        if (i == doorX && j == doorY) continue;
        double r = rand.nextDouble();
        if (r < 0.15) {
          // assign a gift id
          String id = giftIds[rand.nextInt(giftIds.length)];
          newGrid[i][j] = GridCell(type: CellType.gift, isOpened: false, contentId: id);
        } else if (r < 0.25) {
          newGrid[i][j] = GridCell(type: CellType.monster, isOpened: false);
        } else if (r < 0.65) {
          // roughly 40% opened boxes at initialization
          newGrid[i][j] = GridCell(type: CellType.boxOpen, isOpened: true);
        } else {
          newGrid[i][j] = GridCell(type: CellType.box1, isOpened: false);
        }
      }
    }

    return newGrid;
  }

  // Save to prefs
  Future<void> save() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('level', level);
    prefs.setString('player', jsonEncode({'x': player.x, 'y': player.y, 'health': player.health, 'steps': player.steps}));
    List<String> gridData = [];
    for (var col in grid) {
      for (var cell in col) {
        // store type index, opened flag, and optional contentId (empty if null)
        gridData.add('${cell.type.index},${cell.isOpened ? 1 : 0},${cell.contentId ?? ''}');
      }
    }
    prefs.setStringList('grid', gridData);
    prefs.setStringList('gifts', obtainedGifts);
  }

  // Load from prefs
  static Future<GameState?> load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int level = prefs.getInt('level') ?? 1;
    String? playerStr = prefs.getString('player');
    if (playerStr == null) return null;
    Map<String, dynamic> playerData = jsonDecode(playerStr);
    Player player = Player(
      x: playerData['x'],
      y: playerData['y'],
      health: playerData['health'],
      steps: playerData['steps'],
    );
    List<String>? gridData = prefs.getStringList('grid');
    if (gridData == null) return null;
    List<List<GridCell>> grid = [];
    for (int i = 0; i < 5; i++) {
      List<GridCell> col = [];
      for (int j = 0; j < 8; j++) {
        String cellStr = gridData[i * 8 + j];
        List<String> parts = cellStr.split(',');
        CellType type = CellType.values[int.parse(parts[0])];
        bool opened = parts[1] == '1';
        String content = parts.length > 2 && parts[2].isNotEmpty ? parts[2] : '';
        col.add(GridCell(type: type, isOpened: opened, contentId: content.isNotEmpty ? content : null));
      }
      grid.add(col);
    }
    List<String> gifts = prefs.getStringList('gifts') ?? [];

    // Clamp loaded player coordinates
    if (player.x < 0 || player.x >= 5) player.x = 2;
    if (player.y < 0 || player.y >= 8) player.y = 0;
    // Ensure starting cell is an opened empty box
    grid[player.x][player.y] = GridCell(type: CellType.boxOpen, isOpened: true);

    return GameState(level: level, grid: grid, player: player, obtainedGifts: gifts);
  }
}
