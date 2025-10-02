import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'game_state.dart';
import 'game_logic.dart';
import 'input_handler.dart';
import 'controller_handler.dart';
import 'game_ui_components.dart';
import 'board_painter.dart';
import 'touch_controls.dart';
import '../theme/game_theme.dart';
import '../widgets/settings_panel.dart';
import '../widgets/ad_banner.dart';
import '../widgets/rune_energy_hud.dart';
import '../theme/hud_spacing.dart';
import '../core/pixel_snap.dart';
import '../core/constants.dart';
import 'rune_events.dart';

class GameBoard extends StatefulWidget {
  const GameBoard({super.key});

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  double _calculateCellSize(BoxConstraints constraints) {
    // 響應式計算格子大小 - 左側區域約佔60%寬度
    final gameAreaWidth = constraints.maxWidth * 0.6 - 32; // 60%減去padding
    final calculatedCellSize = gameAreaWidth / GameState.colCount;
    return calculatedCellSize.clamp(14.0, 22.0); // 限制在合理範圍內
  }

  late GameState gameState;
  late GameLogic gameLogic;
  late InputHandler inputHandler;
  late ControllerHandler controllerHandler;
  Timer? _dropTimer;
  int _currentSpeed = 500; // 追蹤當前速度

  // 震動特效相關
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  Timer? _shakeTimer;
  Timer? _timeChangeTimer;
  Timer? _blessedComboTimer;

  // RuneEventBus 訂閱
  StreamSubscription<RuneEvent>? _runeEventSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    gameState = GameState();
    gameLogic = GameLogic(gameState);
    inputHandler = InputHandler(
      gameState: gameState,
      gameLogic: gameLogic,
      onStateChange: () => setState(() {}),
      onGameStart: _startGame,
      context: context,
    );
    controllerHandler = ControllerHandler(
      gameState: gameState,
      gameLogic: gameLogic,
      onStateChange: () => setState(() {}),
    );

    // 初始化震動動畫控制器
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // 創建震動動畫（左右快速抖動）
    _shakeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));

    _initializeGame();
  }

  void _initializeGame() async {
    // 設置震動回調
    gameState.setShakeCallback(() {
      triggerShakeAnimation();
    });

    await gameState.initializeAudio();

    // 設置符文事件監聽
    _setupRuneEventListeners();

    // 嘗試從本地存儲載入遊戲狀態
    bool stateLoaded = false;
    try {
      stateLoaded = await gameState.loadState();
      if (stateLoaded) {
        debugPrint('Game: Successfully loaded saved game state');
        // 載入成功，保持暫停狀態並啟動定時器
        _currentSpeed = gameState.dropSpeed;
        if (!gameState.isGameOver) {
          _startGameTimer();
        }
        setState(() {}); // 更新 UI
        return;
      }
    } catch (e) {
      debugPrint('Game: Error loading saved state: $e');
      stateLoaded = false;
    }

    // 無有有效的保存狀態，檢查是否需要初始化新遊戲
    bool needsNewGame = false;

    if (gameState.board.isEmpty) {
      // 棋盤未初始化，需要新遊戲
      needsNewGame = true;
    } else if (gameState.isGameOver) {
      // 遊戲已結束，但不自動開始新遊戲，等待玩家手動開始
      needsNewGame = false;
    } else if (!gameState.isValidGameInProgress()) {
      // 當前狀態無效，需要新遊戲
      needsNewGame = true;
    }

    if (needsNewGame) {
      debugPrint('Game: Starting new game (no valid saved state)');
      await _startGame();
    } else {
      // 保持當前狀態，只確保定時器正常
      debugPrint('Game: Maintaining current game state');
      if (!gameState.isGameOver) {
        _startGameTimer();
      }
    }
  }

  // 公開的震動方法供外部調用
  void triggerShakeAnimation() {
    if (mounted && !_shakeController.isAnimating) {
      _shakeController.reset();
      _shakeController.repeat(reverse: true);

      // 取消現有計時器
      _shakeTimer?.cancel();

      // 400ms後停止震動
      _shakeTimer = Timer(const Duration(milliseconds: 400), () {
        if (mounted) {
          _shakeController.stop();
          _shakeController.reset();
        }
        _shakeTimer = null;
      });
    }
  }

  /// 設置符文事件監聽器
  void _setupRuneEventListeners() {
    // 監聽所有符文事件並過濾 Time Change
    _runeEventSubscription = RuneEventBus.events.listen((event) {
      if (!mounted) return;

      if (event.runeType == RuneType.timeChange &&
          event.type == RuneEventType.effectStart) {
        // 🎯 時間類符文互斥：結束任何其他正在進行的時間效果
        if (gameState.isBlessedComboActive) {
          RuneEventBus.emitEffectEnd(RuneType.blessedCombo);
        }

        gameState.activateTimeChange();
        // 更新遊戲計時器速度
        if (!gameState.isPaused && !gameState.isGameOver) {
          _restartTimerWithCurrentSpeed();
        }

        // 設置10秒自動結束計時器
        _timeChangeTimer?.cancel();
        _timeChangeTimer = Timer(const Duration(seconds: 10), () {
          if (mounted) {
            RuneEventBus.emitEffectEnd(RuneType.timeChange);
          }
          _timeChangeTimer = null;
        });

        debugPrint(
            'GameBoard: Time Change effect activated for 10 seconds (mutually exclusive with other time effects)');
      } else if (event.runeType == RuneType.timeChange &&
          event.type == RuneEventType.effectEnd) {
        // 取消計時器
        _timeChangeTimer?.cancel();
        _timeChangeTimer = null;

        gameState.deactivateTimeChange();
        // 恢復正常遊戲計時器速度
        if (!gameState.isPaused && !gameState.isGameOver) {
          _restartTimerWithCurrentSpeed();
        }
        debugPrint('GameBoard: Time Change effect deactivated');
      } else if (event.runeType == RuneType.blessedCombo &&
          event.type == RuneEventType.effectStart) {
        // 🎯 時間類符文互斥：結束任何其他正在進行的時間效果
        if (gameState.isTimeChangeActive) {
          RuneEventBus.emitEffectEnd(RuneType.timeChange);
        }

        gameState.activateBlessedCombo();

        // 設置10秒自動結束計時器
        _blessedComboTimer?.cancel();
        _blessedComboTimer = Timer(const Duration(seconds: 10), () {
          if (mounted) {
            RuneEventBus.emitEffectEnd(RuneType.blessedCombo);
          }
          _blessedComboTimer = null;
        });

        debugPrint(
            'GameBoard: Blessed Combo effect activated for 10 seconds (mutually exclusive with other time effects)');
      } else if (event.runeType == RuneType.blessedCombo &&
          event.type == RuneEventType.effectEnd) {
        // 取消計時器
        _blessedComboTimer?.cancel();
        _blessedComboTimer = null;

        gameState.deactivateBlessedCombo();
        debugPrint('GameBoard: Blessed Combo effect deactivated');
      }
    });
  }

  /// 以當前速度重啟計時器
  void _restartTimerWithCurrentSpeed() {
    _currentSpeed = gameState.dropSpeed;
    _startGameTimer();
    debugPrint('GameBoard: Timer restarted with speed: ${_currentSpeed}ms');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dropTimer?.cancel();
    _shakeTimer?.cancel();
    _timeChangeTimer?.cancel();
    _blessedComboTimer?.cancel();
    _shakeController.dispose();

    // 清理符文事件監聽器
    _runeEventSubscription?.cancel();

    controllerHandler.dispose();
    gameState.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        // 應用恢復時，保持暫停狀態，讓玩家手動決定是否繼續
        debugPrint('Game: App resumed, maintaining pause state');

        // 確保定時器在遊戲進行中時正常運行 (但不自動恢復)
        if (!gameState.isGameOver && _dropTimer?.isActive != true) {
          debugPrint('Game: Restarting timer after app resume');
          _startGameTimer();
        }

        // 恢復背景音樂（僅當遊戲未暫停且音樂已啟用時）
        if (!gameState.isGameOver &&
            !gameState.isPaused &&
            gameState.audioService.isMusicEnabled) {
          debugPrint('Game: Resuming background music after app resume');
          gameState.audioService.resumeBackgroundMusic();
        }
        break;

      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // 應用暫停或失去焦點時，自動暫停遊戲並保存狀態
        if (!gameState.isGameOver) {
          if (!gameState.isPaused) {
            debugPrint('Game: Auto-pausing due to app state change');
            gameState.isPaused = true;
            gameState.audioService.pauseBackgroundMusic();
            setState(() {});
          }

          // 保存遊戲狀態到本地存儲
          if (gameState.isValidGameInProgress()) {
            gameState.saveState().then((success) {
              if (success) {
                debugPrint('Game: State saved successfully on app pause');
              } else {
                debugPrint('Game: Failed to save state on app pause');
              }
            });
          }
        }
        break;

      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // 應用進程被系統終止前，確保保存狀態
        if (!gameState.isGameOver && gameState.isValidGameInProgress()) {
          gameState.saveState();
          debugPrint('Game: State saved on app detached/hidden');
        }
        break;
    }
  }

  /// Handle ad click by pausing the game immediately
  void _pauseGameForAdClick() {
    if (!gameState.isGameOver && !gameState.isPaused) {
      debugPrint('Game: Pausing for ad click');
      gameState.isPaused = true;
      gameState.audioService.pauseBackgroundMusic();
      setState(() {});
    }
  }

  Future<void> _startGame() async {
    // 開始新遊戲時清除保存的狀態
    await gameState.clearSavedState();
    await gameState.startGame();
    _currentSpeed = gameState.dropSpeed;
    _startGameTimer();
    setState(() {});
    debugPrint('Game: New game started, saved state cleared');
  }

  void _startGameTimer() {
    // 確保先取消現有的timer
    _dropTimer?.cancel();

    // 驗證速度值的有效性
    if (_currentSpeed <= 0) {
      _currentSpeed = 500; // 設置默認值
    }

    _dropTimer = Timer.periodic(Duration(milliseconds: _currentSpeed), (_) {
      if (!gameState.isPaused && !gameState.isGameOver) {
        setState(() {
          gameLogic.drop();

          // 檢查速度是否需要更新
          int newSpeed = gameState.dropSpeed;
          if (newSpeed != _currentSpeed && newSpeed > 0) {
            _currentSpeed = newSpeed;
            _startGameTimer(); // 重新啟動計時器使用新速度
          }

          if (gameState.isGameOver) {
            _dropTimer?.cancel();
          }
        });
      }
    });
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      // 直接處理KeyEvent，修改InputHandler和ControllerHandler
      _handleModernKey(event);
      return KeyEventResult.handled; // 表示事件已處理
    }
    return KeyEventResult.ignored;
  }

  void _handleModernKey(KeyDownEvent event) {
    final key = event.logicalKey;

    // 處理系統鍵
    if (key == LogicalKeyboardKey.keyP && !gameState.isGameOver) {
      gameState.isPaused = !gameState.isPaused;
      if (gameState.isPaused) {
        gameState.audioService.pauseBackgroundMusic();
      } else {
        gameState.audioService.resumeBackgroundMusic();
      }
      setState(() {});
      return;
    } else if (key == LogicalKeyboardKey.keyR) {
      _startGame();
      return;
    } else if (key == LogicalKeyboardKey.keyG) {
      gameState.toggleGhostPiece();
      setState(() {});
      return;
    }

    // 處理遊戲控制（只在遊戲運行時）
    if (!gameState.isPaused && !gameState.isGameOver) {
      bool stateChanged = false;

      // 方向鍵控制
      if (key == LogicalKeyboardKey.arrowLeft) {
        gameLogic.moveLeft();
        stateChanged = true;
      } else if (key == LogicalKeyboardKey.arrowRight) {
        gameLogic.moveRight();
        stateChanged = true;
      } else if (key == LogicalKeyboardKey.arrowUp) {
        gameLogic.rotate();
        stateChanged = true;
      } else if (key == LogicalKeyboardKey.arrowDown) {
        gameLogic.moveDown();
        stateChanged = true;
      } else if (key == LogicalKeyboardKey.space) {
        gameLogic.hardDrop();
        stateChanged = true;
      } else if (key == LogicalKeyboardKey.keyZ) {
        gameLogic.rotateCounterClockwise();
        stateChanged = true;
      } else if (key == LogicalKeyboardKey.keyX) {
        gameLogic.rotate();
        stateChanged = true;
      }
      // WASD 控制
      else if (key == LogicalKeyboardKey.keyA) {
        gameLogic.moveLeft();
        stateChanged = true;
      } else if (key == LogicalKeyboardKey.keyD) {
        gameLogic.moveRight();
        stateChanged = true;
      } else if (key == LogicalKeyboardKey.keyW) {
        gameLogic.hardDrop();
        stateChanged = true;
      } else if (key == LogicalKeyboardKey.keyS) {
        gameLogic.moveDown();
        stateChanged = true;
      } else if (key == LogicalKeyboardKey.keyQ) {
        gameLogic.rotateCounterClockwise();
        stateChanged = true;
      } else if (key == LogicalKeyboardKey.keyE) {
        gameLogic.rotate();
        stateChanged = true;
      }
      // 數字鍵盤控制
      else if (key == LogicalKeyboardKey.numpad4) {
        gameLogic.moveLeft();
        stateChanged = true;
      } else if (key == LogicalKeyboardKey.numpad6) {
        gameLogic.moveRight();
        stateChanged = true;
      } else if (key == LogicalKeyboardKey.numpad8) {
        gameLogic.hardDrop();
        stateChanged = true;
      } else if (key == LogicalKeyboardKey.numpad2) {
        gameLogic.moveDown();
        stateChanged = true;
      } else if (key == LogicalKeyboardKey.numpad1) {
        gameLogic.rotateCounterClockwise();
        stateChanged = true;
      } else if (key == LogicalKeyboardKey.numpad3) {
        gameLogic.rotate();
        stateChanged = true;
      } else if (key == LogicalKeyboardKey.numpad0) {
        gameLogic.hardDrop();
        stateChanged = true;
      } else if (key == LogicalKeyboardKey.numpadDecimal) {
        gameState.isPaused = !gameState.isPaused;
        if (gameState.isPaused) {
          gameState.audioService.pauseBackgroundMusic();
        } else {
          gameState.audioService.resumeBackgroundMusic();
        }
        stateChanged = true;
      } else if (key == LogicalKeyboardKey.numpadSubtract) {
        gameState.toggleGhostPiece();
        stateChanged = true;
      }

      if (stateChanged) {
        setState(() {});
      }
    }
  }

  void _showSettingsPanel() {
    // 暫停遊戲和背景音樂（如果遊戲正在進行）
    bool wasGameRunning = !gameState.isGameOver && !gameState.isPaused;
    if (wasGameRunning) {
      gameState.isPaused = true;
      gameState.audioService.pauseBackgroundMusic();
    }

    showDialog(
      context: context,
      builder: (dialogContext) => SettingsPanel(
        gameState: gameState,
        onGhostPieceToggle: () => setState(() => gameState.toggleGhostPiece()),
        onStateChange: () => setState(() {}),
        gameContext: context,
      ),
    ).then((_) {
      // 設定面板關閉後，恢復遊戲狀態（如果之前在運行）
      if (wasGameRunning) {
        // 注意：不自動恢復遊戲，讓玩家手動決定
        // 但要恢復背景音樂（如果音樂是啟用的）
        if (gameState.audioService.isMusicEnabled && !gameState.isPaused) {
          gameState.audioService.resumeBackgroundMusic();
        }
      }
      // 觸發 UI 更新
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 分數面板 - 保持在頂部原位置
          // RepaintBoundary: 隔離分數模組，只在得分時更新
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: RepaintBoundary(
              child: GameUIComponents.scoreInfoPanel(
                gameState.score,
                gameState.highScore,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // 主遊戲區域
          LayoutBuilder(
            builder: (context, constraints) {
              final cellSize = _calculateCellSize(constraints);
              return Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 左側區域（棋盤 + 觸控按鈕）
                  Flexible(
                    flex: 3,
                    child: Column(
                      children: [
                        // 遊戲棋盤（附震動特效）
                        AnimatedBuilder(
                          animation: _shakeAnimation,
                          builder: (context, child) {
                            // 計算震動偏移值（左右快速抖動）
                            double shakeOffset = 0.0;
                            if (_shakeController.isAnimating) {
                              // 使用sin函數產生快速左右震動效果
                              shakeOffset = (math.sin(
                                      _shakeAnimation.value * math.pi * 8) *
                                  6);
                            }

                            return Transform.translate(
                              offset: Offset(shakeOffset, 0),
                              child: child,
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              // 🌃 Neon Gradient - 深色到藍紫的線性漸層背景
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  cyberpunkBgDeep, // 深層背景
                                  cyberpunkAccent.withOpacity(0.05), // 電光紫極淡
                                  cyberpunkPrimary.withOpacity(0.03), // 霓虹青極淡
                                ],
                                stops: const [0.0, 0.7, 1.0],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              // 🔮 HUD Border - 霓虹描邊與輕微外發光
                              border: Border.all(
                                color: Color.lerp(
                                    cyberpunkPrimary,
                                    cyberpunkSecondary,
                                    0.5)!, // cyan/magenta 混合
                                width: 1, // 1px 霓虹描邊
                              ),
                              boxShadow: [
                                // 原有陰影保留
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.5),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                                // 霓虹外發光 - 青色
                                BoxShadow(
                                  color: cyberpunkPrimary.withOpacity(0.3),
                                  blurRadius: cyberpunkGlowSoft, // 輕微外發光
                                  offset: const Offset(0, 0),
                                ),
                                // 霓虹外發光 - 洋紅
                                BoxShadow(
                                  color: cyberpunkSecondary.withOpacity(0.2),
                                  blurRadius: cyberpunkGlowSoft,
                                  offset: const Offset(0, 0),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Stack(
                                children: [
                                  RepaintBoundary(
                                    child: SizedBox(
                                      width: GameState.colCount * cellSize,
                                      height: GameState.rowCount * cellSize,
                                      child: CustomPaint(
                                        painter: BoardPainter(
                                          gameState.board,
                                          gameState.currentTetromino,
                                          ghostPiece: gameLogic
                                                  .shouldShowGhostPiece()
                                              ? gameLogic.calculateGhostPiece()
                                              : null,
                                          cellSize: cellSize,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // 暫停或 Game Over 蓋板
                                  if (gameState.isPaused &&
                                      !gameState.isGameOver)
                                    GameUIComponents.overlayText(
                                        'PAUSED', GameTheme.highlight),
                                  if (gameState.isGameOver)
                                    GameUIComponents.overlayText(
                                        'GAME OVER', GameTheme.highlight),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 16),

                  // 右側控制區
                  Flexible(
                    flex: 2,
                    child: SafeArea(
                      bottom: true,
                      child: RepaintBoundary(
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 遊戲狀態指示器
                            GameUIComponents.gameStatusIndicators(
                              combo: gameState.scoringService.currentCombo,
                              isBackToBackReady:
                                  gameState.scoringService.isBackToBackReady,
                              comboRank:
                                  gameState.scoringService.comboRankDescription,
                            ),
                            const SizedBox(height: HudSpacing.kHudGap),

                            // 控制按鈕 (水平排列，提升視覺層次)
                            // RepaintBoundary: 隔離控制按鈕，幾乎不變
                            RepaintBoundary(
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: GameTheme.primaryDark.withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color:
                                        GameTheme.accentBlue.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    // 設置按鈕
                                    Expanded(
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 2),
                                        child: ElevatedButton(
                                          onPressed: () => _showSettingsPanel(),
                                          style: GameTheme.primaryButtonStyle
                                              .copyWith(
                                            backgroundColor:
                                                WidgetStateProperty.all(
                                              GameTheme.accentBlue
                                                  .withOpacity(0.8),
                                            ),
                                            padding: WidgetStateProperty.all(
                                              const EdgeInsets.symmetric(
                                                  vertical: 8),
                                            ),
                                            minimumSize:
                                                WidgetStateProperty.all(
                                              const Size(0, 36),
                                            ),
                                          ),
                                          child: const Icon(Icons.settings,
                                              size: 16),
                                        ),
                                      ),
                                    ),

                                    // 暫停/繼續按鈕
                                    Expanded(
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 2),
                                        child: ElevatedButton(
                                          onPressed: () => setState(() {
                                            gameState.isPaused =
                                                !gameState.isPaused;
                                            if (gameState.isPaused) {
                                              gameState.audioService
                                                  .pauseBackgroundMusic();
                                            } else {
                                              gameState.audioService
                                                  .resumeBackgroundMusic();
                                            }
                                          }),
                                          style: (gameState.isPaused
                                                  ? GameTheme
                                                      .secondaryButtonStyle
                                                  : GameTheme
                                                      .primaryButtonStyle)
                                              .copyWith(
                                            padding: WidgetStateProperty.all(
                                              const EdgeInsets.symmetric(
                                                  vertical: 8),
                                            ),
                                            minimumSize:
                                                WidgetStateProperty.all(
                                              const Size(0, 36),
                                            ),
                                          ),
                                          child: Icon(
                                            gameState.isPaused
                                                ? Icons.play_arrow
                                                : Icons.pause,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ),

                                    // 重新開始按鈕
                                    Expanded(
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 2),
                                        child: ElevatedButton(
                                          onPressed: _startGame,
                                          style: GameTheme.primaryButtonStyle
                                              .copyWith(
                                            backgroundColor:
                                                WidgetStateProperty.all(
                                              GameTheme.buttonDanger,
                                            ),
                                            padding: WidgetStateProperty.all(
                                              const EdgeInsets.symmetric(
                                                  vertical: 8),
                                            ),
                                            minimumSize:
                                                WidgetStateProperty.all(
                                              const Size(0, 36),
                                            ),
                                          ),
                                          child: const Icon(Icons.refresh,
                                              size: 16),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: HudSpacing.kHudGap),

                            // 統計數據區域 (2×2網格布局，提升空間利用率)
                            // RepaintBoundary: 隔離統計數據，低頻更新
                            RepaintBoundary(
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color:
                                      GameTheme.secondaryDark.withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: GameTheme.gridLine.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    // 第一行：行數 + 關卡
                                    Row(
                                      children: [
                                        Expanded(
                                          child: GameUIComponents
                                              .linesStatComponent(
                                            gameState.marathonSystem
                                                .totalLinesCleared,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: GameUIComponents
                                              .levelStatComponent(
                                            gameState
                                                .marathonSystem.currentLevel,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),

                                    // 第二行：Combo + 最後得分
                                    Row(
                                      children: [
                                        Expanded(
                                          child: GameUIComponents
                                              .comboStatComponent(
                                            gameState
                                                .scoringService.currentCombo,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: GameUIComponents
                                              .lastScoreStatComponent(
                                            gameState
                                                .lastScoringResult?.description,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: HudSpacing.kHudGap),

                            // NEXT 預覽模組
                            // RepaintBoundary: 隔離 NEXT 預覽，只在換方塊時更新
                            RepaintBoundary(
                              child: GameUIComponents.nextPiecePreview(
                                gameState.nextTetromino,
                                gameState.nextTetrominos,
                              ),
                            ),

                            const SizedBox(height: HudSpacing.kHudGap),

                            // 符文能量區域 (全寬布局，優化空間利用)
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: GameTheme.primaryDark.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: GameTheme.accentBlue.withOpacity(0.4),
                                  width: 1,
                                ),
                              ),
                              child: RuneEnergyHUD(
                                energyStatus:
                                    gameState.runeEnergyManager.getStatus(),
                                gap: snap(4.0,
                                    MediaQuery.of(context).devicePixelRatio),
                              ),
                            ),

                            // 保留与触控按钮区的安全间距
                            SizedBox(
                              height: snap(12.0,
                                  MediaQuery.of(context).devicePixelRatio),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 16),

          // 觸控按鈕區域 - 置中顯示
          Center(
            child: TouchControls(
              gameLogic: gameLogic,
              gameState: gameState,
              onStateChange: () => setState(() {}),
            ),
          ),

          // 底部橫幅廣告 - 不影響遊戲佈局
          AdBanner(
            showDebugInfo: true, // 開發模式顯示平台信息
            onGamePauseRequested: _pauseGameForAdClick, // 廣告點擊時暫停遊戲
          ),
        ],
      ),
    );
  }
}
