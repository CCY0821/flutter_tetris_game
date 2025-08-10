import 'package:flutter/services.dart';
import 'game_state.dart';
import 'game_logic.dart';

class InputHandler {
  final GameState gameState;
  final GameLogic gameLogic;
  final VoidCallback onStateChange;
  final Future<void> Function() onGameStart;

  InputHandler({
    required this.gameState,
    required this.gameLogic,
    required this.onStateChange,
    required this.onGameStart,
  });

  void handleKey(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      final key = event.logicalKey.keyLabel.toLowerCase();

      if (key == 'p' && !gameState.isGameOver) {
        gameState.isPaused = !gameState.isPaused;
        // 控制背景音樂暫停/恢復
        if (gameState.isPaused) {
          gameState.audioService.pauseBackgroundMusic();
        } else {
          gameState.audioService.resumeBackgroundMusic();
        }
        onStateChange();
      } else if (key == 'r') {
        onGameStart();
      } else if (!gameState.isPaused && !gameState.isGameOver) {
        switch (key) {
          case 'arrow left':
            gameLogic.moveLeft();
            onStateChange();
            break;
          case 'arrow right':
            gameLogic.moveRight();
            onStateChange();
            break;
          case 'arrow down':
            gameLogic.moveDown();
            onStateChange();
            break;
          case ' ':
            gameLogic.rotate();
            onStateChange();
            break;
        }
      }
    }
  }
}
