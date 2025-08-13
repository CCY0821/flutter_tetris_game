import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'game_state.dart';
import 'game_logic.dart';
import 'input_handler.dart';
import 'game_ui_components.dart';
import 'board_painter.dart';

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
  Timer? gameTimer;

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
    gameTimer?.cancel();
    gameState.dispose();
    super.dispose();
  }

  Future<void> _startGame() async {
    await gameState.startGame();
    gameTimer?.cancel();
    gameTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!gameState.isPaused && !gameState.isGameOver) {
        setState(() {
          gameLogic.drop();
          if (gameState.isGameOver) {
            gameTimer?.cancel();
          }
        });
      }
    });
    setState(() {});
  }

  void _handleKey(RawKeyEvent event) {
    inputHandler.handleKey(event);
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 左側主遊戲區
          Stack(
            children: [
              SizedBox(
                width: GameState.colCount * cellSize,
                height: GameState.rowCount * cellSize,
                child: CustomPaint(
                  painter:
                      BoardPainter(gameState.board, gameState.currentTetromino),
                ),
              ),

              // 暫停或 Game Over 蓋板
              if (gameState.isPaused && !gameState.isGameOver)
                GameUIComponents.overlayText('PAUSED', Colors.amber),
              if (gameState.isGameOver)
                GameUIComponents.overlayText('GAME OVER', Colors.redAccent),
            ],
          ),

          const SizedBox(width: 16),

          // 右側控制區
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GameUIComponents.infoBox('Score: ${gameState.score}'),
              const SizedBox(height: 16),
              GameUIComponents.infoBox('Next'),
              const SizedBox(height: 8),
              GameUIComponents.nextBlockPreview(gameState.nextTetromino),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    setState(() => gameState.isPaused = !gameState.isPaused),
                child: Text(gameState.isPaused ? 'Resume (P)' : 'Pause (P)'),
              ),
              ElevatedButton(
                onPressed: _startGame,
                child: const Text('Restart (R)'),
              ),
              const SizedBox(height: 16),
              GameUIComponents.audioControlButton(),
            ],
          ),
        ],
      ),
    );
  }
}
