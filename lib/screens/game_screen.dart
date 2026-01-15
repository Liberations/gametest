import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../models/grid_cell.dart';
import 'leaderboard_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  AnimationController? _flyController;
  // Animation<Offset>? _flyAnimation; // removed unused field
  // track animated gift widget
  String? _animatingGiftAsset;
  Offset? _startOffset;
  Offset? _endOffset;

  // store last computed cell size so we can start animations immediately after move
  double? _cellWidth;
  double? _cellHeight;

  // grid global key to compute global coordinates for overlay animation
  final GlobalKey _gridKey = GlobalKey();
  OverlayEntry? _giftOverlay;
  VoidCallback? _overlayListener;
  // keys for bottom gift slots to compute precise target coords
  final List<GlobalKey> _giftSlotKeys = [];

  void _ensureGiftSlotKeys(int count) {
    if (_giftSlotKeys.length < count) {
      for (int i = _giftSlotKeys.length; i < count; i++) {
        _giftSlotKeys.add(GlobalKey());
      }
    } else if (_giftSlotKeys.length > count) {
      _giftSlotKeys.removeRange(count, _giftSlotKeys.length);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GameProvider>().initializeGame();
    });
    WidgetsBinding.instance.addObserver(this);
    _flyController = AnimationController(vsync: this, duration: Duration(milliseconds: 600));
    _flyController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // clear anim state after finishing
        setState(() {
          _animatingGiftAsset = null;
        });
        _flyController!.reset();
        // clear provider lastOpened tracking so animation won't repeat
        var provider = context.read<GameProvider>();
        provider.lastOpenedX = null;
        provider.lastOpenedY = null;
        provider.lastOpenedContentId = null;
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _flyController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      context.read<GameProvider>().saveGame();
    }
  }

  String _giftIdToAsset(String id) {
    // Map gift ids to asset file names
    switch (id) {
      case 'gift_1':
        return 'lib/assets/ic_gift.webp';
      case 'gift_2':
        return 'lib/assets/ic_gift2.webp';
      case 'gift_3':
        return 'lib/assets/ic_gift3.webp';
      default:
        return 'lib/assets/ic_gift.webp';
    }
  }

  // Start animation for a specific cell coordinate and gift id
  void _startFlyAnimationAt(int sx, int sy, String contentId) {
    if (contentId.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // small delay to ensure layout is fully settled
      await Future.delayed(Duration(milliseconds: 16));

      double localStartX;
      double localStartY;
      if (_cellWidth != null && _cellHeight != null) {
        localStartX = sx * _cellWidth! + (_cellWidth! - 40) / 2;
        localStartY = sy * _cellHeight! + (_cellHeight! - 40) / 2;
      } else {
        // fallback to screen-based calculation
        double cellWidth = MediaQuery.of(context).size.width / 5;
        double cellHeight = MediaQuery.of(context).size.height / 8;
        localStartX = sx * cellWidth + (cellWidth - 40) / 2;
        localStartY = sy * cellHeight + (cellHeight - 40) / 2;
      }

      // compute global start position using grid key
      RenderBox? gridBox = _gridKey.currentContext?.findRenderObject() as RenderBox?;
      Offset gridOrigin = Offset.zero;
      if (gridBox != null) {
        gridOrigin = gridBox.localToGlobal(Offset.zero);
      }
      final startGlobal = gridOrigin + Offset(localStartX, localStartY);

      // compute global end position using the gift slot key if available
      double screenHeight = MediaQuery.of(context).size.height;
      double endGlobalX;
      double endGlobalY = screenHeight - 50;
      // target slot is last obtained gift
      int targetIndex = (context.read<GameProvider>().gameState?.obtainedGifts.length ?? 1) - 1;
      if (targetIndex >= 0 && targetIndex < _giftSlotKeys.length) {
        final slotKey = _giftSlotKeys[targetIndex];
        RenderBox? slotBox = slotKey.currentContext?.findRenderObject() as RenderBox?;
        if (slotBox != null) {
          Offset slotOrigin = slotBox.localToGlobal(Offset.zero);
          endGlobalX = slotOrigin.dx + (slotBox.size.width - 40) / 2;
          endGlobalY = slotOrigin.dy + (slotBox.size.height - 40) / 2;
        } else {
          endGlobalX = 25.0 + targetIndex * 50.0;
        }
      } else {
        endGlobalX = 25.0 + targetIndex * 50.0;
      }

      // create overlay entry
      _giftOverlay?.remove();
      _giftOverlay = OverlayEntry(builder: (context) {
        final t = _flyController?.value ?? 0.0;
        final x = startGlobal.dx + (endGlobalX - startGlobal.dx) * Curves.easeInOut.transform(t);
        final y = startGlobal.dy + (endGlobalY - startGlobal.dy) * Curves.easeInOut.transform(t);
        return Positioned(
          left: x,
          top: y,
          child: Opacity(
            opacity: 1.0 - t,
            child: Image.asset(_giftIdToAsset(contentId), width: 40, height: 40),
          ),
        );
      });

      // clear provider flags to avoid duplicate triggers
      var provider = context.read<GameProvider>();
      provider.lastOpenedX = null;
      provider.lastOpenedY = null;
      provider.lastOpenedContentId = null;

      // remove previous listener
      if (_overlayListener != null) {
        _flyController?.removeListener(_overlayListener!);
        _overlayListener = null;
      }
      // attach listener before inserting overlay so it rebuilds on ticks
      _overlayListener = () {
        _giftOverlay?.markNeedsBuild();
      };
      _flyController?.addListener(_overlayListener!);

      // insert overlay and animate
      Overlay.of(context).insert(_giftOverlay!);

      if (_flyController!.isAnimating) {
        _flyController!.stop();
        _flyController!.reset();
      }
      // listen for completion via status listener so we can cleanup reliably
      void statusListener(AnimationStatus status) {
        if (status == AnimationStatus.completed) {
          // cleanup
          _giftOverlay?.remove();
          _giftOverlay = null;
          if (_overlayListener != null) {
            _flyController?.removeListener(_overlayListener!);
            _overlayListener = null;
          }
          _flyController?.removeStatusListener(statusListener);
          _flyController?.reset();
        }
      }
      _flyController?.addStatusListener(statusListener);
      _flyController!.forward(from: 0.0);
      // force an immediate repaint so the overlay shows on this frame
      _giftOverlay?.markNeedsBuild();
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text('Gift Game', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(Icons.leaderboard, color: Colors.white),
            tooltip: 'Leaderboard',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => LeaderboardScreen()));
            },
          ),
          IconButton(
            icon: Icon(Icons.directions_walk, color: Colors.white),
            tooltip: 'Add steps',
            onPressed: () => context.read<GameProvider>().rechargeSteps(),
          ),
          IconButton(
            icon: Icon(Icons.favorite, color: Colors.white),
            tooltip: 'Add health',
            onPressed: () => context.read<GameProvider>().rechargeHealth(),
          ),
          IconButton(
            icon: Icon(Icons.exit_to_app, color: Colors.white),
            tooltip: 'End game',
            onPressed: () => context.read<GameProvider>().endGame(),
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<GameProvider>(
          builder: (context, provider, child) {
            if (provider.gameState == null) {
              return Center(child: CircularProgressIndicator());
            }

            return Column(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // compute actual grid area size inside Expanded
                      double gridWidth = constraints.maxWidth;
                      double gridHeight = constraints.maxHeight;
                      double cellWidth = gridWidth / 5;
                      double cellHeight = gridHeight / 8;

                      // save sizes for immediate animation triggering after moves
                      _cellWidth = cellWidth;
                      _cellHeight = cellHeight;

                      return GestureDetector(
                        onPanEnd: (details) {
                          double velocityX = details.velocity.pixelsPerSecond.dx;
                          double velocityY = details.velocity.pixelsPerSecond.dy;
                          if (velocityX.abs() > velocityY.abs()) {
                            if (velocityX > 0) {
                              _move(1, 0);
                            } else {
                              _move(-1, 0);
                            }
                          } else {
                            if (velocityY > 0) {
                              _move(0, 1);
                            } else {
                              _move(0, -1);
                            }
                          }
                        },
                        onTap: () {},
                        onTapDown: (_) {},
                        child: Stack(
                          key: _gridKey,
                          children: [
                            GridView.builder(
                              physics: NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 5,
                                childAspectRatio: 1,
                              ),
                              itemCount: 40, // 5*8
                              itemBuilder: (context, index) {
                                int x = index % 5;
                                int y = index ~/ 5;
                                GridCell cell = provider.gameState!.grid[x][y];
                                bool showOpenBase = cell.isOpened;
                                return Container(
                                  key: ValueKey('cell_${x}_${y}_${cell.isOpened}'),
                                  margin: EdgeInsets.all(2),
                                  child: showOpenBase
                                      ? Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            Image.asset('lib/assets/ic_box_open.webp'),
                                            if (cell.isOpened && _getContentImage(cell).isNotEmpty)
                                              Image.asset(_getContentImage(cell)),
                                          ],
                                        )
                                      : Image.asset('lib/assets/ic_box1.webp'),
                                );
                              },
                            ),
                            // Player: centered in cell using actual cell dimensions
                            Positioned(
                              left: provider.gameState!.player.x * cellWidth + (cellWidth - 50) / 2,
                              top: provider.gameState!.player.y * cellHeight + (cellHeight - 50) / 2,
                              child: Image.asset('lib/assets/ic_mine.webp', width: 50, height: 50),
                            ),
                            // Flying gift animation, compute positions relative to grid area
                            if (_animatingGiftAsset != null && _startOffset != null && _endOffset != null)
                              AnimatedBuilder(
                                animation: _flyController!,
                                builder: (context, child) {
                                  double t = _flyController!.value;
                                  double x = _startOffset!.dx + (_endOffset!.dx - _startOffset!.dx) * Curves.easeInOut.transform(t);
                                  double y = _startOffset!.dy + (_endOffset!.dy - _startOffset!.dy) * Curves.easeInOut.transform(t);
                                  return Positioned(
                                    left: x,
                                    top: y,
                                    child: Opacity(
                                      opacity: 1.0 - t,
                                      child: Image.asset(_animatingGiftAsset!, width: 40, height: 40),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  height: 100,
                  color: Colors.black,
                  child: Row(
                    children: [
                      Expanded(
                        child: Builder(builder: (context) {
                          // ensure we have keys for each obtained gift slot
                          _ensureGiftSlotKeys(provider.gameState!.obtainedGifts.length);
                          return ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: provider.gameState!.obtainedGifts.length,
                            itemBuilder: (context, index) {
                              String id = provider.gameState!.obtainedGifts[index];
                              return Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4),
                                child: Container(
                                  key: _giftSlotKeys[index],
                                  width: 50,
                                  height: 50,
                                  child: Image.asset(_giftIdToAsset(id), width: 50),
                                ),
                              );
                            },
                          );
                        }),
                      ),
                      DefaultTextStyle(
                        style: TextStyle(color: Colors.white),
                        child: Row(
                          children: [
                            Text('Steps: ${provider.gameState!.player.steps}'),
                            SizedBox(width: 10),
                            Text('Level: ${provider.gameState!.level}'),
                            SizedBox(width: 10),
                            Text('Health: ${provider.gameState!.player.health}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _move(int dx, int dy) {
    var provider = context.read<GameProvider>();
    // Prevent movement when player has no steps or health
    if (!provider.canMove(dx, dy)) {
      _showRechargeDialog();
      return;
    }
    List<CellType> opened = provider.movePlayer(dx, dy);
    // Start animation only if move opened a gift (opened list contains gift)
    if (opened.contains(CellType.gift)) {
      int px = provider.gameState!.player.x;
      int py = provider.gameState!.player.y;
      if (py >= 0 && py < 8 && px >= 0 && px < 5) {
        var cell = provider.gameState!.grid[px][py];
        if (cell.contentId != null) {
          if (_cellWidth != null && _cellHeight != null) {
            _startFlyAnimationAt(px, py, cell.contentId!);
          } else {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _startFlyAnimationAt(px, py, cell.contentId!);
            });
          }
        }
      }
    }

    if (opened.contains(CellType.door)) {
      _showDoorDialog();
    }
    if (provider.gameState!.player.steps <= 0 || provider.gameState!.player.health <= 0) {
      _showRechargeDialog();
    }
  }

  void _showDoorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Door Opened'),
        content: Text('Choose to enter next level or continue exploring.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<GameProvider>().nextLevel();
            },
            child: Text('Next Level'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showRechargeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Recharge'),
        content: Text('Steps or health low. Recharge health or steps.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<GameProvider>().rechargeHealth();
            },
            child: Text('Recharge Health (+10)'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<GameProvider>().rechargeSteps();
            },
            child: Text('Gift Steps (+10)'),
          ),
        ],
      ),
    );
  }

  String _getContentImage(GridCell cell) {
    // Return the image asset for the content of the cell, if any.
    switch (cell.type) {
      case CellType.door:
        return 'lib/assets/ic_door.webp';
      case CellType.gift:
        // If gift has a contentId, map it
        if (cell.contentId != null) {
          return _giftIdToAsset(cell.contentId!);
        }
        return 'lib/assets/ic_gift.webp';
      case CellType.monster:
        return 'lib/assets/ic_guaiwu.webp';
      default:
        return '';
    }
  }
}
