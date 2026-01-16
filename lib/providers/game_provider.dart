import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import '../models/game_state.dart';
import '../models/player.dart';
import '../models/grid_cell.dart';
import '../models/leaderboard_entry.dart';

// Conditional import for http client
import 'http_helper.dart' if (dart.library.html) 'http_helper_web.dart' as httpHelper;

class GameProvider with ChangeNotifier {
  GameState? _gameState;

  // URL parameters from web (uid, token)
  String? _uid;
  String? _token;

  // User info from API
  String? _userAvatar;
  String? _userNickname;
  bool _isLoadingUserInfo = false;

  String? get uid => _uid;
  String? get token => _token;
  String? get userAvatar => _userAvatar;
  String? get userNickname => _userNickname;
  bool get isLoadingUserInfo => _isLoadingUserInfo;

  // Set URL parameters (called from main.dart on web)
  void setUrlParams(String? uid, String? token) {
    _uid = uid;
    _token = token;
    // Fetch user info when params are set
    if (uid != null && token != null) {
      fetchUserInfo();
    }
  }

  // Fetch user info from API
  Future<void> fetchUserInfo() async {
    debugPrint('fetchUserInfo $_uid $_token');
    if (_uid == null || _token == null) return;

    _isLoadingUserInfo = true;
    notifyListeners();

    try {
      final response = await httpHelper.httpGet(
        'https://app.test.horovoice.com/api/charge_reward_api/get_activity_user_rank',
        {
          'uid': _uid!,
          'token': _token!,
          'event_id': '14',
          'gift_id': '409',
          'type': '2',
          'language': 'en',
        },
      );
      debugPrint('fetchUserInfo ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 1 && data['data'] != null) {
          _userAvatar = data['data']['user']['avatar'];
          _userNickname = data['data']['user']['user_nickname'];
          debugPrint('User info loaded: avatar=$_userAvatar, nickname=$_userNickname');
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch user info: $e');
    } finally {
      _isLoadingUserInfo = false;
      notifyListeners();
    }
  }

  // For UI animation: last opened cell position and content id
  int? lastOpenedX;
  int? lastOpenedY;
  String? lastOpenedContentId;

  // Swipe settings (px thresholds)
  // defaults chosen to reasonable values; user can change with Settings screen
  double hThresholdTouch = 3.0;
  double hThresholdTrackpad = 2.0;
  double hThresholdDesktop = 5.0;
  double vThresholdTouch = 16.0;
  double vThresholdTrackpad = 12.0;
  double vThresholdDesktop = 20.0;
  double flingThreshold = 600.0; // px/s

  GameState? get gameState => _gameState;

  Future<void> initializeGame() async {
    _gameState ??= await GameState.load();
    if (_gameState == null) {
      _gameState = GameState(
        grid: GameState.generateGrid(),
        player: Player(),
      );
    }
    // load saved settings
    await _loadSettings();

    // Clamp player coordinates to valid range
    if (_gameState!.player.x < 0 || _gameState!.player.x >= GameState.COLS) {
      _gameState!.player.x = (GameState.COLS / 2).floor();
    }
    if (_gameState!.player.y < 0 || _gameState!.player.y >= GameState.ROWS) {
      _gameState!.player.y = 0;
    }
    // Ensure the player's starting cell is always an opened empty box
    if (_gameState!.player.y >= 0 && _gameState!.player.y < GameState.ROWS) {
      _gameState!.grid[_gameState!.player.x][_gameState!.player.y] = GridCell(type: CellType.boxOpen, isOpened: true);
    }
    notifyListeners();
  }

  // Persistent settings helpers
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      hThresholdTouch = prefs.getDouble('hThresholdTouch') ?? hThresholdTouch;
      hThresholdTrackpad = prefs.getDouble('hThresholdTrackpad') ?? hThresholdTrackpad;
      hThresholdDesktop = prefs.getDouble('hThresholdDesktop') ?? hThresholdDesktop;
      vThresholdTouch = prefs.getDouble('vThresholdTouch') ?? vThresholdTouch;
      vThresholdTrackpad = prefs.getDouble('vThresholdTrackpad') ?? vThresholdTrackpad;
      vThresholdDesktop = prefs.getDouble('vThresholdDesktop') ?? vThresholdDesktop;
      flingThreshold = prefs.getDouble('flingThreshold') ?? flingThreshold;
      notifyListeners();
    } catch (e) {
      // ignore load errors
      print('Failed to load settings: $e');
    }
  }

  Future<void> saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('hThresholdTouch', hThresholdTouch);
      await prefs.setDouble('hThresholdTrackpad', hThresholdTrackpad);
      await prefs.setDouble('hThresholdDesktop', hThresholdDesktop);
      await prefs.setDouble('vThresholdTouch', vThresholdTouch);
      await prefs.setDouble('vThresholdTrackpad', vThresholdTrackpad);
      await prefs.setDouble('vThresholdDesktop', vThresholdDesktop);
      await prefs.setDouble('flingThreshold', flingThreshold);
    } catch (e) {
      print('Failed to save settings: $e');
    }
  }

  double getHorizontalThreshold(PointerDeviceKind? kind, {bool isWeb = false}) {
    if (isWeb) {
      if (kind == PointerDeviceKind.touch) return hThresholdTouch;
      return hThresholdTrackpad;
    }
    return hThresholdDesktop;
  }

  double getVerticalThreshold(PointerDeviceKind? kind, {bool isWeb = false}) {
    if (isWeb) {
      if (kind == PointerDeviceKind.touch) return vThresholdTouch;
      return vThresholdTrackpad;
    }
    return vThresholdDesktop;
  }

  double getFlingThreshold() => flingThreshold;

  // setters for settings
  void updateHThresholdTouch(double v) { hThresholdTouch = v; notifyListeners(); }
  void updateHThresholdTrackpad(double v) { hThresholdTrackpad = v; notifyListeners(); }
  void updateHThresholdDesktop(double v) { hThresholdDesktop = v; notifyListeners(); }
  void updateVThresholdTouch(double v) { vThresholdTouch = v; notifyListeners(); }
  void updateVThresholdTrackpad(double v) { vThresholdTrackpad = v; notifyListeners(); }
  void updateVThresholdDesktop(double v) { vThresholdDesktop = v; notifyListeners(); }
  void updateFlingThreshold(double v) { flingThreshold = v; notifyListeners(); }

  // Move player and open only the box at the player's new position
  List<CellType> movePlayer(int dx, int dy) {
    if (_gameState == null) return [];
    int curX = _gameState!.player.x;
    int curY = _gameState!.player.y;
    int newX = curX + dx;
    int newY = curY + dy;

    // If player is at spawn above the grid (y == -1) and moving horizontally, enter row 0
    if (curY == -1 && dy == 0 && dx != 0) {
      newY = 0;
    }

    if (newX < 0 || newX >= GameState.COLS || newY < -1 || newY >= GameState.ROWS) return [];

    // If player cannot move due to steps/health, don't change state here (UI should check canMove)
    // Update player position and steps
    _gameState!.player.x = newX;
    _gameState!.player.y = newY;
    _gameState!.player.steps--;

    // Debug log
    print('movePlayer -> moved from ($curX,$curY) to ($newX,$newY). steps=${_gameState!.player.steps}, health=${_gameState!.player.health}');

    // Reset last opened tracking
    lastOpenedX = null;
    lastOpenedY = null;
    lastOpenedContentId = null;

    List<CellType> opened = [];
    if (newY >= 0 && newY < GameState.ROWS) {
      var cell = _gameState!.grid[newX][newY];
      bool wasOpened = cell.isOpened;

      // Always mark the cell as opened visually immediately
      cell.isOpened = true;

      // Debug log cell
      print('movePlayer -> cell at ($newX,$newY) type=${cell.type} wasOpened=$wasOpened nowOpened=${cell.isOpened} contentId=${cell.contentId}');

      if (cell.type == CellType.door) {
        // always notify about door so UI can prompt every time
        opened.add(CellType.door);
        lastOpenedX = newX;
        lastOpenedY = newY;
        lastOpenedContentId = cell.contentId;
      } else if (!wasOpened) {
        // only apply effects (monster/gift) when it was previously unopened
        opened.add(cell.type);
        lastOpenedX = newX;
        lastOpenedY = newY;
        lastOpenedContentId = cell.contentId;
        if (cell.type == CellType.monster) {
          _gameState!.player.health--;
          print('movePlayer -> monster encountered, health now ${_gameState!.player.health}');
        } else if (cell.type == CellType.gift) {
          if (cell.contentId != null) {
            _gameState!.obtainedGifts = List.from(_gameState!.obtainedGifts)..add(cell.contentId!);
          } else {
            _gameState!.obtainedGifts = List.from(_gameState!.obtainedGifts)..add('gift_unknown');
          }
          print('movePlayer -> gift obtained: ${_gameState!.obtainedGifts.last}');
        }
      }
    }

    notifyListeners();
    return opened;
  }

  List<CellType> openNearbyBoxes() {
    // Deprecated: retained for compatibility but now opens nothing.
    return [];
  }

  void nextLevel() {
    if (_gameState == null) return;
    _gameState!.level++;
    _gameState!.grid = GameState.generateGrid();
    _gameState!.player = Player(); // reset position
    // open starting cell for the new level and make it an empty open box
    if (_gameState!.player.y >= 0 && _gameState!.player.y < GameState.ROWS) {
      _gameState!.grid[_gameState!.player.x][_gameState!.player.y] = GridCell(type: CellType.boxOpen, isOpened: true);
    }
    notifyListeners();
  }

  void rechargeHealth() {
    if (_gameState == null) return;
    _gameState!.player.health += 10;
    notifyListeners();
  }

  void rechargeSteps() {
    if (_gameState == null) return;
    _gameState!.player.steps += 10;
    notifyListeners();
  }

  Future<void> saveGame() async {
    await _gameState?.save();
  }

  // Ensure current player's cell is an opened empty box
  void ensureStartCellOpen() {
    if (_gameState == null) return;
    int x = _gameState!.player.x;
    int y = _gameState!.player.y;
    if (x < 0 || x >= GameState.COLS || y < 0 || y >= GameState.ROWS) return;
    var cell = _gameState!.grid[x][y];
    if (!(cell.type == CellType.boxOpen && cell.isOpened)) {
      _gameState!.grid[x][y] = GridCell(type: CellType.boxOpen, isOpened: true);
      notifyListeners();
    }
  }

  // Test helper: set game state directly (used by unit tests)
  void setGameStateForTest(GameState state) {
    _gameState = state;
    ensureStartCellOpen();
    notifyListeners();
  }

  // Reset the game to initial state (end current game)
  void endGame() {
    _gameState = GameState(grid: GameState.generateGrid(), player: Player(), obtainedGifts: []);
    // clear any animation tracking
    lastOpenedX = null;
    lastOpenedY = null;
    lastOpenedContentId = null;
    notifyListeners();
  }

  // Check if the player can move by dx,dy (within bounds and player has steps and health)
  bool canMove(int dx, int dy) {
    if (_gameState == null) return false;
    if (_gameState!.player.steps <= 0 || _gameState!.player.health <= 0) return false;

    int curX = _gameState!.player.x;
    int curY = _gameState!.player.y;
    int newX = curX + dx;
    int newY = curY + dy;

    // If player is at spawn above the grid (y == -1) and moving horizontally, entering row 0 is allowed
    if (curY == -1 && dy == 0 && dx != 0) {
      newY = 0;
    }

    // Match movePlayer's allowed range: y may be -1 (spawn) up to ROWS-1
    if (newX < 0 || newX >= GameState.COLS || newY < 0 || newY >= GameState.ROWS) return false;
    return true;
  }

  // Return a sample leaderboard (in-memory). In future this can be backed by network or storage.
  List<LeaderboardEntry> getLeaderboard() {
    // Lazy import use: create data here to avoid circular imports at top
    return [
      LeaderboardEntry(avatarAsset: 'lib/assets/ic_mine.webp', name: 'You', score: _gameState?.player.steps ?? 0),
      LeaderboardEntry(avatarAsset: 'lib/assets/ic_gift.webp', name: 'Alice', score: 120),
      LeaderboardEntry(avatarAsset: 'lib/assets/ic_gift2.webp', name: 'Bob', score: 95),
      LeaderboardEntry(avatarAsset: 'lib/assets/ic_gift3.webp', name: 'Carol', score: 80),
    ];
  }
}
