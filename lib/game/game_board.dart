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
  static const double cellSize = 20;

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
    RawKeyboard.instance.addListener(_handleKey);
  }

  void _initializeGame() async {
    gameState.initBoard(); // 先初始化遊戲板
    await gameState.initializeAudio();
    await _startGame();
  }

  @override
  void dispose() {
    RawKeyboard.instance.removeListener(_handleKey);
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

  void _handleKey(RawKeyEvent event) {
    // 優先處理鍵盤輸入
    inputHandler.handleKey(event);

    // 同時處理手把輸入
    controllerHandler.handleGamepadInput(event);
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
    return IntrinsicHeight(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 主遊戲區域
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 左側區域（棋盤 + 觸控按鈕）
              Column(
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

                  const SizedBox(height: 12),

                  // 觸控按鈕區域
                  TouchControls(
                    gameLogic: gameLogic,
                    gameState: gameState,
                    onStateChange: () => setState(() {}),
                  ),
                ],
              ),

              const SizedBox(width: 16),

              // 右側控制區
              Container(
                width: 180,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 合併的 NEXT 和 SCORE 面板
                    GameUIComponents.nextAndScorePanel(gameState.nextTetromino, gameState.score),
                    const SizedBox(height: 12),

                    // Marathon 模式資訊或傳統資訊
                    if (gameState.isMarathonMode) ...[
                      GameUIComponents.marathonInfoPanel(
                          gameState.marathonSystem),
                      const SizedBox(height: 12),
                    ] else ...[
                      // 傳統模式的遊戲狀態
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
                      const SizedBox(height: 12),
                    ],

                    // 得分系統狀態指示器
                    GameUIComponents.gameStatusIndicators(
                      combo: gameState.scoringService.currentCombo,
                      isBackToBackReady: gameState.scoringService.isBackToBackReady,
                      comboRank: gameState.scoringService.comboRankDescription,
                    ),
                    const SizedBox(height: 8),

                    // 連擊特效指示器（高連擊時顯示）
                    if (gameState.scoringService.currentCombo >= 4)
                      GameUIComponents.comboEffectIndicator(
                        combo: gameState.scoringService.currentCombo,
                        comboRank: gameState.scoringService.comboRankDescription,
                      ),
                    const SizedBox(height: 8),

                    // 最後一次得分結果
                    GameUIComponents.scoringInfoPanel(gameState.lastScoringResult),
                    const SizedBox(height: 12),

                    // 設置按鈕
                    ElevatedButton(
                      onPressed: () => _showSettingsPanel(),
                      style: GameTheme.primaryButtonStyle.copyWith(
                        backgroundColor: MaterialStateProperty.all(
                          GameTheme.accentBlue.withOpacity(0.8),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.settings, size: 18),
                          const SizedBox(width: 6),
                          Text('Settings'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 控制按鈕
                    ElevatedButton(
                      onPressed: () => setState(
                          () => gameState.isPaused = !gameState.isPaused),
                      style: gameState.isPaused
                          ? GameTheme.secondaryButtonStyle
                          : GameTheme.primaryButtonStyle,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            gameState.isPaused ? Icons.play_arrow : Icons.pause,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(gameState.isPaused ? 'Resume' : 'Pause'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _startGame,
                      style: GameTheme.primaryButtonStyle.copyWith(
                        backgroundColor:
                            MaterialStateProperty.all(GameTheme.buttonDanger),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.refresh, size: 18),
                          const SizedBox(width: 6),
                          Text('Restart'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 連擊統計面板
                    GameUIComponents.comboStatsPanel(gameState.scoringService),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
