import 'package:flutter/services.dart';
import 'game_state.dart';
import 'game_logic.dart';

/// 遊戲控制器/手把支援系統
class ControllerHandler {
  final GameState gameState;
  final GameLogic gameLogic;
  final VoidCallback onStateChange;

  // 按鍵重複輸入控制
  final Map<LogicalKeyboardKey, DateTime> _lastPressTime = {};
  static const Duration _repeatDelay = Duration(milliseconds: 150);

  ControllerHandler({
    required this.gameState,
    required this.gameLogic,
    required this.onStateChange,
  });

  /// 處理手把輸入事件
  void handleGamepadInput(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final key = event.logicalKey;
    final now = DateTime.now();

    // 檢查按鍵重複輸入間隔
    if (_lastPressTime.containsKey(key)) {
      final timeSinceLastPress = now.difference(_lastPressTime[key]!);
      if (timeSinceLastPress < _repeatDelay) {
        return; // 太快的重複輸入，忽略
      }
    }
    _lastPressTime[key] = now;

    // 遊戲控制邏輯
    if (gameState.isPaused || gameState.isGameOver) return;

    _handleGamepadControls(key);
  }

  /// 標準手把控制映射
  void _handleGamepadControls(LogicalKeyboardKey key) {
    // 數字鍵盤模擬手把控制
    if (key == LogicalKeyboardKey.numpad4) {
      // 數字4：左移（模擬搖桿左）
      gameLogic.moveLeft();
      onStateChange();
    } else if (key == LogicalKeyboardKey.numpad6) {
      // 數字6：右移（模擬搖桿右）
      gameLogic.moveRight();
      onStateChange();
    } else if (key == LogicalKeyboardKey.numpad8) {
      // 數字8：硬降（模擬搖桿上）
      gameLogic.hardDrop();
      onStateChange();
    } else if (key == LogicalKeyboardKey.numpad2) {
      // 數字2：軟降（模擬搖桿下）
      gameLogic.moveDown();
      onStateChange();
    } else if (key == LogicalKeyboardKey.numpad1) {
      // 數字1：逆時針旋轉（模擬左肩鍵）
      gameLogic.rotateCounterClockwise();
      onStateChange();
    } else if (key == LogicalKeyboardKey.numpad3) {
      // 數字3：順時針旋轉（模擬右肩鍵）
      gameLogic.rotate();
      onStateChange();
    } else if (key == LogicalKeyboardKey.numpad0) {
      // 數字0：硬降（模擬X鈕）
      gameLogic.hardDrop();
      onStateChange();
    } else if (key == LogicalKeyboardKey.numpadDecimal) {
      // 小數點：暫停（模擬Start鈕）
      gameState.isPaused = !gameState.isPaused;
      if (gameState.isPaused) {
        gameState.audioService.pauseBackgroundMusic();
      } else {
        gameState.audioService.resumeBackgroundMusic();
      }
      onStateChange();
    } else if (key == LogicalKeyboardKey.numpadSubtract) {
      // 減號：切換Ghost piece（模擬Select鈕）
      gameState.toggleGhostPiece();
      onStateChange();
    }

    // WASD 控制（第二套控制方案）
    else if (key == LogicalKeyboardKey.keyA) {
      // A：左移
      gameLogic.moveLeft();
      onStateChange();
    } else if (key == LogicalKeyboardKey.keyD) {
      // D：右移
      gameLogic.moveRight();
      onStateChange();
    } else if (key == LogicalKeyboardKey.keyW) {
      // W：硬降
      gameLogic.hardDrop();
      onStateChange();
    } else if (key == LogicalKeyboardKey.keyS) {
      // S：軟降
      gameLogic.moveDown();
      onStateChange();
    } else if (key == LogicalKeyboardKey.keyQ) {
      // Q：逆時針旋轉
      gameLogic.rotateCounterClockwise();
      onStateChange();
    } else if (key == LogicalKeyboardKey.keyE) {
      // E：順時針旋轉
      gameLogic.rotate();
      onStateChange();
    }
  }

  /// 獲取控制說明文字
  static String getControlHelp() {
    return '''
🎮 模擬手把控制（數字鍵盤）：
4/6：移動方塊
8：硬降（瞬間落地）
2：軟降
1：逆時針旋轉
3：順時針旋轉
0：硬降
.：暫停
-：切換Ghost Piece

🎮 WASD控制：
A/D：移動方塊
W：硬降
S：軟降
Q：逆時針旋轉
E：順時針旋轉

⌨️ 鍵盤控制：
←→：移動方塊
↑：順時針旋轉
↓：軟降
空白鍵：硬降
Z：逆時針旋轉
X：順時針旋轉
P：暫停
R：重新開始
G：切換Ghost Piece
H：顯示說明
''';
  }

  /// 清理資源
  void dispose() {
    _lastPressTime.clear();
  }
}
