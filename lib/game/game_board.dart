import 'dart:async';
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

class GameBoard extends StatefulWidget {
  const GameBoard({super.key});

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> {
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

  @override
  void initState() {
    super.initState();
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
    _initializeGame();
  }

  void _initializeGame() async {
    gameState.initBoard(); // 先初始化遊戲板
    await gameState.initializeAudio();
    await _startGame();
  }

  @override
  void dispose() {
    _dropTimer?.cancel();
    controllerHandler.dispose();
    gameState.dispose();
    super.dispose();
  }

  Future<void> _startGame() async {
    await gameState.startGame();
    _currentSpeed = gameState.dropSpeed;
    _startGameTimer();
    setState(() {});
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
    showDialog(
      context: context,
      builder: (dialogContext) => SettingsPanel(
        gameState: gameState,
        onGameModeToggle: () => setState(() => gameState.toggleGameMode()),
        onGhostPieceToggle: () => setState(() => gameState.toggleGhostPiece()),
        onStateChange: () => setState(() {}),
        gameContext: context,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
                        // 遊戲棋盤
                        Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: GameTheme.boardBorder,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: GameTheme.accentBlue.withOpacity(0.3),
                          blurRadius: 32,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        children: [
                          SizedBox(
                            width: GameState.colCount * cellSize,
                            height: GameState.rowCount * cellSize,
                            child: CustomPaint(
                              painter: BoardPainter(
                                gameState.board,
                                gameState.currentTetromino,
                                ghostPiece: gameLogic.shouldShowGhostPiece()
                                    ? gameLogic.calculateGhostPiece()
                                    : null,
                                cellSize: cellSize,
                              ),
                            ),
                          ),

                          // 暫停或 Game Over 蓋板
                          if (gameState.isPaused && !gameState.isGameOver)
                            GameUIComponents.overlayText(
                                'PAUSED', GameTheme.highlight),
                          if (gameState.isGameOver)
                            GameUIComponents.overlayText(
                                'GAME OVER', GameTheme.highlight),
                        ],
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
                    child: Container(
                      height: GameState.rowCount * cellSize, // 與遊戲場高度對齊
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // NEXT 和 SCORE 面板 (頂部固定)
                    GameUIComponents.nextAndScorePanel(
                      gameState.nextTetromino, 
                      gameState.score, 
                      gameState.nextTetrominos
                    ),
                    const SizedBox(height: 16),

                    // 可擴展的中間區域
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            // 傳統模式的遊戲狀態（僅在非 Marathon 模式顯示）
                            if (!gameState.isMarathonMode) ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: GameUIComponents.infoBox(
                                        '${gameState.speedLevel}',
                                        label: 'LEVEL'),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: GameUIComponents.infoBox(
                                        '${gameState.dropSpeed}ms',
                                        label: 'SPEED'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                            ],

                            // 得分系統狀態指示器
                            GameUIComponents.gameStatusIndicators(
                              combo: gameState.scoringService.currentCombo,
                              isBackToBackReady: gameState.scoringService.isBackToBackReady,
                              comboRank: gameState.scoringService.comboRankDescription,
                            ),
                            const SizedBox(height: 12),

                            // 連擊特效指示器（高連擊時顯示）
                            if (gameState.scoringService.currentCombo >= 4)
                              GameUIComponents.comboEffectIndicator(
                                combo: gameState.scoringService.currentCombo,
                                comboRank: gameState.scoringService.comboRankDescription,
                              ),
                            const SizedBox(height: 12),

                            // 最後一次得分結果
                            GameUIComponents.scoringInfoPanel(gameState.lastScoringResult),
                            const SizedBox(height: 16),

                            // 整合統計面板（Marathon + COMBO）
                            GameUIComponents.integratedStatsPanel(
                              gameState.scoringService,
                              gameState.isMarathonMode ? gameState.marathonSystem : null,
                              gameState.isMarathonMode,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 控制按鈕 (底部固定)
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // 設置按鈕
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(right: 4),
                            child: ElevatedButton(
                              onPressed: () => _showSettingsPanel(),
                              style: GameTheme.primaryButtonStyle.copyWith(
                                backgroundColor: MaterialStateProperty.all(
                                  GameTheme.accentBlue.withOpacity(0.8),
                                ),
                                padding: MaterialStateProperty.all(
                                  const EdgeInsets.symmetric(vertical: 10),
                                ),
                              ),
                              child: Icon(Icons.settings, size: 18),
                            ),
                          ),
                        ),
                        
                        // 暫停/繼續按鈕
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            child: ElevatedButton(
                              onPressed: () => setState(() {
                                gameState.isPaused = !gameState.isPaused;
                                if (gameState.isPaused) {
                                  gameState.audioService.pauseBackgroundMusic();
                                } else {
                                  gameState.audioService.resumeBackgroundMusic();
                                }
                              }),
                              style: (gameState.isPaused
                                  ? GameTheme.secondaryButtonStyle
                                  : GameTheme.primaryButtonStyle).copyWith(
                                padding: MaterialStateProperty.all(
                                  const EdgeInsets.symmetric(vertical: 10),
                                ),
                              ),
                              child: Icon(
                                gameState.isPaused ? Icons.play_arrow : Icons.pause,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                        
                        // 重新開始按鈕
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(left: 4),
                            child: ElevatedButton(
                              onPressed: _startGame,
                              style: GameTheme.primaryButtonStyle.copyWith(
                                backgroundColor: MaterialStateProperty.all(
                                  GameTheme.buttonDanger,
                                ),
                                padding: MaterialStateProperty.all(
                                  const EdgeInsets.symmetric(vertical: 10),
                                ),
                              ),
                              child: Icon(Icons.refresh, size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                    ],
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
        ],
      ),
    );
  }
}
