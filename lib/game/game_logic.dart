import 'package:flutter/material.dart';
import '../models/tetromino.dart';
import '../services/high_score_service.dart';
import '../services/scoring_service.dart';
import 'game_state.dart';
import 'srs_system.dart';
import 'rune_system.dart';

class GameLogic {
  final GameState gameState;

  // SRS 相關狀態
  bool lastRotationWasWallKick = false;
  String lastKickType = '';

  GameLogic(this.gameState);

  /// 每邏輯幀更新（由 GameBoard 調用）
  void onLogicFrameStart() {
    // 更新符文系統狀態
    gameState.runeSystem.onLogicFrameStart();

    // 執行符文系統的批處理操作
    executeRuneBatch();
  }

  /// 執行符文系統的批處理操作
  void executeRuneBatch() {
    debugPrint('GameLogic: executeRuneBatch called');
    gameState.runeSystem.executeBatch(gameState.board);
  }

  /// 符文施法
  RuneCastResult castRune(int slotIndex) {
    // 創建遊戲上下文對象供符文使用
    final gameContext = _GameContext(this);

    return gameState.runeSystem.castRune(
      slotIndex,
      board: gameState.board,
      gameContext: gameContext,
    );
  }

  bool canMove(Tetromino tetro,
      {int dx = 0, int dy = 0, List<Offset>? overrideShape}) {
    for (final point in overrideShape ?? tetro.shape) {
      final x = tetro.x + point.dx.toInt() + dx;
      final y = tetro.y + point.dy.toInt() + dy;

      // 檢查水平邊界
      if (x < 0 || x >= GameState.colCount) {
        return false;
      }

      // 檢查垂直邊界（使用總矩陣高度，包含緩衝區）
      if (y >= GameState.totalRowCount) {
        return false;
      }

      // 檢查與已存在方塊的碰撞（允許在緩衝區上方）
      if (y >= 0 && gameState.board[y][x] != null) {
        return false;
      }
    }
    return true;
  }

  void lockTetromino() {
    for (final point in gameState.currentTetromino!.shape) {
      final x = gameState.currentTetromino!.x + point.dx.toInt();
      final y = gameState.currentTetromino!.y + point.dy.toInt();
      if (x >= 0 &&
          x < GameState.colCount &&
          y >= 0 &&
          y < GameState.totalRowCount) {
        gameState.board[y][x] = gameState.currentTetromino!.color;
      }
    }
    clearFullRows();
  }

  void clearFullRows() {
    List<List<Color?>> newBoard = [];
    int clearedRows = 0;

    // 檢查整個矩陣（包含緩衝區）
    for (int y = 0; y < GameState.totalRowCount; y++) {
      if (gameState.board[y].every((cell) => cell != null)) {
        clearedRows++;
      } else {
        newBoard.add(List<Color?>.from(gameState.board[y]));
      }
    }

    // 總是調用得分計算來正確處理COMBO邏輯（包括重置）
    final scoringResult = gameState.scoringService.calculateLineScore(
      linesCleared: clearedRows,
      currentLevel: gameState.speedLevel,
      isTSpin:
          lastRotationWasWallKick && gameState.currentTetromino?.isT == true,
      tSpinType: _determineTSpinType(),
      tetromino: gameState.currentTetromino,
      origin: ScoreOrigin.natural, // 🎯 標記為自然消行
    );

    if (clearedRows > 0) {
      gameState.score += scoringResult.points;

      // 🔧 修復：添加消行能量獲得 (每消行1行 = +50分，每100分 = 1格能量)
      gameState.runeEnergyManager.addScore(clearedRows);

      // 即時檢查高分更新
      _checkHighScoreRealtime();

      // 觸發震動特效
      gameState.triggerScreenShake();

      // 更新 Marathon 系統的行數計算
      gameState.updateLinesCleared(clearedRows);

      // 播放相應音效（優先級：T-Spin > 連擊 > Tetris > 一般消行）
      if (scoringResult.achievements.any((a) => a.contains('T-Spin'))) {
        gameState.audioService.playSoundEffect('t_spin'); // 如果有的話
      } else if (scoringResult.comboCount >= 4) {
        // 高連擊特殊音效
        gameState.audioService.playSoundEffect('combo_high'); // 如果有的話
      } else if (scoringResult.comboCount > 0) {
        // 一般連擊音效
        gameState.audioService.playSoundEffect('combo'); // 如果有的話
      } else if (clearedRows == 4) {
        gameState.audioService.playSoundEffect('tetris'); // 如果有的話
      } else {
        gameState.audioService.playSoundEffect('line_clear');
      }

      // 在矩陣頂部添加新的空行
      for (int i = 0; i < clearedRows; i++) {
        newBoard.insert(0, List.generate(GameState.colCount, (_) => null));
      }

      gameState.board = newBoard;
    }

    // 總是儲存最後一次得分結果供 UI 顯示（即使是0分也要顯示COMBO重置）
    gameState.lastScoringResult = scoringResult;
  }

  void drop() {
    if (gameState.currentTetromino == null) return;

    if (canMove(gameState.currentTetromino!, dy: 1)) {
      gameState.currentTetromino!.y++;
    } else {
      // 播放方塊落地音效
      gameState.audioService.playSoundEffect('piece_drop');
      lockTetromino();
      spawnTetromino();
    }
  }

  void spawnTetromino() {
    final newTetro = gameState.nextTetromino!;
    debugPrint('[GameLogic] Spawning tetromino type: ${newTetro.type}');

    // 在緩衝區中設置生成位置
    newTetro.x = GameState.colCount ~/ 2;
    // 在緩衝區內生成：I型在第18行，其他在第19行
    newTetro.y = newTetro.isI ? 18 : 19;
    newTetro.rotation = 0;

    if (canMove(newTetro)) {
      gameState.currentTetromino = newTetro;

      // 使用方塊供應器系統生成下一個方塊
      final nextType = gameState.pieceProviderStack.getNext();
      debugPrint('[GameLogic] Generated next piece type: $nextType');
      gameState.nextTetromino = Tetromino.fromType(
        nextType,
        GameState.colCount
      );
      
      // 更新預覽隊列
      gameState.updatePreviewQueue();
    } else {
      gameState.isGameOver = true;
      // 播放遊戲結束音效
      gameState.audioService.playSoundEffect('game_over');
      // 停止背景音樂
      gameState.audioService.stopBackgroundMusic();
    }
  }

  void moveLeft() {
    if (canMove(gameState.currentTetromino!, dx: -1)) {
      gameState.currentTetromino!.x--;
    }
  }

  void moveRight() {
    if (canMove(gameState.currentTetromino!, dx: 1)) {
      gameState.currentTetromino!.x++;
    }
  }

  void moveDown() {
    if (canMove(gameState.currentTetromino!, dy: 1)) {
      gameState.currentTetromino!.y++;
      // 軟降得分
      int softDropPoints = gameState.scoringService.calculateSoftDropScore(1);
      gameState.score += softDropPoints;

      // 即時檢查高分更新
      _checkHighScoreRealtime();
    }
  }

  /// 硬降 (Hard Drop) - 瞬間將方塊降到最底部並鎖定
  void hardDrop() {
    if (gameState.currentTetromino == null) return;

    int dropDistance = 0;

    // 計算可以下降的距離
    while (canMove(gameState.currentTetromino!, dy: 1)) {
      gameState.currentTetromino!.y++;
      dropDistance++;
    }

    // 硬降獲得額外分數
    int hardDropPoints =
        gameState.scoringService.calculateHardDropScore(dropDistance);
    gameState.score += hardDropPoints;

    // 即時檢查高分更新
    _checkHighScoreRealtime();

    // 立即鎖定方塊
    lockTetromino();
    spawnTetromino();

    // 播放硬降音效
    gameState.audioService.playSoundEffect('hard_drop');
  }

  /// SRS 旋轉系統 - 順時針旋轉
  void rotate() {
    rotatePiece(clockwise: true);
  }

  /// SRS 旋轉系統 - 逆時針旋轉
  void rotateCounterClockwise() {
    rotatePiece(clockwise: false);
  }

  /// 使用 SRS 系統執行旋轉
  void rotatePiece({bool clockwise = true}) {
    if (gameState.currentTetromino == null) return;

    final currentPiece = gameState.currentTetromino!;

    // 嘗試 SRS 旋轉
    final result = SRSSystem.attemptRotation(
      currentPiece,
      gameState.board,
      clockwise,
    );

    if (result.success) {
      // 更新方塊狀態
      currentPiece.updateState(
        newX: result.newX,
        newY: result.newY,
        newRotation: result.newRotation,
        newShape: result.newShape,
      );

      // 記錄壁踢資訊
      lastRotationWasWallKick = result.usedWallKick;
      lastKickType = result.kickDescription;

      // 播放適當的音效
      if (result.usedWallKick) {
        gameState.audioService.playSoundEffect('wall_kick'); // 如果有的話
      } else {
        gameState.audioService.playSoundEffect('piece_rotate');
      }

      // 檢查 T-Spin
      if (currentPiece.isT && result.usedWallKick) {
        _checkTSpin(currentPiece);
      }
    }
  }

  /// 檢查 T-Spin（簡化版本）
  void _checkTSpin(Tetromino tPiece) {
    // 這個方法現在主要用於標記 T-Spin 狀態
    // 實際得分計算在 clearFullRows 中處理
  }

  /// 確定 T-Spin 類型
  String _determineTSpinType() {
    if (!lastRotationWasWallKick || gameState.currentTetromino?.isT != true) {
      return 'normal';
    }

    // 簡化的 T-Spin 檢測邏輯
    // 在實際實現中，這裡會有更複雜的角落檢查
    final tPiece = gameState.currentTetromino!;
    int filledCorners = 0;

    final corners = [
      Offset(tPiece.x - 1, tPiece.y - 1), // 左上
      Offset(tPiece.x + 1, tPiece.y - 1), // 右上
      Offset(tPiece.x - 1, tPiece.y + 1), // 左下
      Offset(tPiece.x + 1, tPiece.y + 1), // 右下
    ];

    for (final corner in corners) {
      final x = corner.dx.toInt();
      final y = corner.dy.toInt();

      if (x < 0 ||
          x >= GameState.colCount ||
          y < 0 ||
          y >= GameState.totalRowCount) {
        filledCorners++; // 邊界算作填充
      } else if (y >= 0 && gameState.board[y][x] != null) {
        filledCorners++;
      }
    }

    // 簡化判斷：3個以上角落填充為普通 T-Spin，否則為 Mini T-Spin
    return filledCorners >= 3 ? 'normal' : 'mini';
  }

  /// 獲取最後一次旋轉的壁踢資訊
  String getLastRotationInfo() {
    if (lastRotationWasWallKick) {
      return 'Wall Kick: $lastKickType';
    }
    return 'Normal Rotation';
  }

  /// 計算Ghost piece的落地位置
  /// 返回當前方塊如果直接下落會到達的最終位置
  Tetromino? calculateGhostPiece() {
    if (gameState.currentTetromino == null) return null;

    // 創建當前方塊的副本作為Ghost piece
    final ghostPiece = gameState.currentTetromino!.copy();

    // 不斷向下移動直到無法移動為止
    while (canMove(ghostPiece, dy: 1)) {
      ghostPiece.y++;
    }

    // 如果Ghost piece和當前方塊位置相同，則不顯示Ghost piece
    if (ghostPiece.y == gameState.currentTetromino!.y) {
      return null;
    }

    return ghostPiece;
  }

  /// 檢查Ghost piece是否應該顯示
  bool shouldShowGhostPiece() {
    return gameState.isGhostPieceEnabled &&
        !gameState.isPaused &&
        !gameState.isGameOver &&
        gameState.currentTetromino != null;
  }

  /// 檢查並更新高分
  Future<void> _checkAndUpdateHighScore() async {
    final isNewRecord =
        await HighScoreService.instance.updateHighScore(gameState.score);
    if (isNewRecord) {
      // 更新 GameState 中的高分快取
      gameState.highScore = gameState.score;
      // TODO: 可以在這裡添加新紀錄的特效或音效
    }
  }

  /// 即時檢查並更新高分（非阻塞，用於遊戲進行中）
  void _checkHighScoreRealtime() {
    final isNewRecord = HighScoreService.instance
        .checkAndUpdateHighScoreRealtime(gameState.score);
    if (isNewRecord) {
      // 立即更新 GameState 中的高分快取，觸發 UI 刷新
      gameState.highScore = gameState.score;
    }
  }
}

/// 遊戲上下文類
/// 為符文系統提供必要的遊戲邏輯訪問接口
class _GameContext {
  final GameLogic gameLogic;

  _GameContext(this.gameLogic);

  /// 獲取當前方塊
  Tetromino? get currentTetromino => gameLogic.gameState.currentTetromino;

  /// 計算影子方塊位置
  Tetromino? calculateGhostPiece() => gameLogic.calculateGhostPiece();
}
