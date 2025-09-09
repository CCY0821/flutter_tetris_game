import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'game_state.dart';
import 'game_logic.dart';

class InputHandler {
  final GameState gameState;
  final GameLogic gameLogic;
  final VoidCallback onStateChange;
  final Future<void> Function() onGameStart;
  final BuildContext? context;

  InputHandler({
    required this.gameState,
    required this.gameLogic,
    required this.onStateChange,
    required this.onGameStart,
    this.context,
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
      } else if (key == 'g') {
        gameState.toggleGhostPiece();
        onStateChange();
      } else if (key == 'h' && context != null) {
        // 顯示控制說明對話框
        showDialog(
          context: context!,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Colors.black87,
              title: const Text(
                '🎮 遊戲控制說明',
                style: TextStyle(color: Colors.white),
              ),
              content: Container(
                width: 400,
                child: const SingleChildScrollView(
                  child: Text(
                    '''⌨️ 標準鍵盤控制：
← →  移動方塊
↑    順時針旋轉
↓    軟降（非鎖定）
空白   硬降（瞬間落地並鎖定）
Z    逆時針旋轉
X    順時針旋轉（備用）
P    暫停/恢復
R    重新開始
G    切換Ghost Piece
H    顯示此說明

🎮 WASD控制：
A/D  移動方塊
W    硬降
S    軟降
Q    逆時針旋轉
E    順時針旋轉

🔢 數字鍵盤控制：
4/6  移動方塊
8    硬降（瞬間落地）
2    軟降
1    逆時針旋轉
3    順時針旋轉
0    硬降
.    暫停
-    切換Ghost Piece''',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('確定'),
                ),
              ],
            );
          },
        );
      } else if (!gameState.isPaused && !gameState.isGameOver) {
        switch (key) {
          case 'arrow left':
            // 左箭頭：左移
            gameLogic.moveLeft();
            onStateChange();
            break;
          case 'arrow right':
            // 右箭頭：右移
            gameLogic.moveRight();
            onStateChange();
            break;
          case 'arrow up':
            // 上箭頭：順時針旋轉
            gameLogic.rotate();
            onStateChange();
            break;
          case 'arrow down':
            // 下箭頭：軟降（非鎖定）
            gameLogic.moveDown();
            onStateChange();
            break;
          case ' ':
            // 空白鍵：硬降（鎖定）
            gameLogic.hardDrop();
            onStateChange();
            break;
          case 'z':
            // Z鍵：逆時針旋轉
            gameLogic.rotateCounterClockwise();
            onStateChange();
            break;
          case 'x':
            // X鍵：順時針旋轉（備用）
            gameLogic.rotate();
            onStateChange();
            break;
        }
      }
    }
  }
}
