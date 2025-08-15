import 'dart:async';
import 'package:flutter/material.dart';
import '../models/tetromino.dart';
import '../services/audio_service.dart';
import 'marathon_system.dart';

class GameState {
  // 可見遊戲區域：10寬 x 20高
  static const int visibleRowCount = 20;
  static const int colCount = 10;

  // 緩衝區：在可見區域上方20行
  static const int bufferRowCount = 20;

  // 總矩陣大小：10寬 x 40高 (20緩衝 + 20可見)
  static const int totalRowCount = bufferRowCount + visibleRowCount;

  // 為了向後兼容，保留原rowCount但標註為可見區域
  static const int rowCount = visibleRowCount;

  List<List<Color?>> board = [];
  Tetromino? currentTetromino;
  Tetromino? nextTetromino;
  final AudioService audioService = AudioService();
  final MarathonSystem marathonSystem = MarathonSystem();

  int score = 0;
  bool isGameOver = false;
  bool isPaused = false;

  // Ghost piece 設定
  bool isGhostPieceEnabled = true;

  // 遊戲模式
  bool isMarathonMode = true; // 預設使用 Marathon 模式

  // 速度系統相關
  static const int baseSpeed = 500; // 起始速度 (毫秒)
  static const int maxSpeed = 300; // 最高速度 (毫秒)
  static const int speedIncrease = 20; // 每階段加速 (毫秒)
  static const int scorePerLevel = 1000; // 每級所需分數

  void initBoard() {
    // 創建包含緩衝區的完整矩陣 (40行 x 10列)
    board = List.generate(
      totalRowCount,
      (_) => List.generate(colCount, (_) => null),
    );
  }

  /// 獲取可見遊戲區域的矩陣 (不包含緩衝區)
  /// 返回從第20行開始的20行數據
  List<List<Color?>> get visibleBoard {
    return board.sublist(bufferRowCount, totalRowCount);
  }

  /// 檢查指定行是否在緩衝區內
  bool isInBufferZone(int row) {
    return row < bufferRowCount;
  }

  /// 檢查指定行是否在可見區域內
  bool isInVisibleZone(int row) {
    return row >= bufferRowCount && row < totalRowCount;
  }

  /// 將緩衝區座標轉換為可見區域座標
  int bufferToVisibleRow(int bufferRow) {
    return bufferRow - bufferRowCount;
  }

  /// 將可見區域座標轉換為緩衝區座標
  int visibleToBufferRow(int visibleRow) {
    return visibleRow + bufferRowCount;
  }

  Future<void> initializeAudio() async {
    await audioService.initialize();
  }

  Future<void> startGame() async {
    initBoard();
    score = 0;
    isGameOver = false;
    isPaused = false;
    currentTetromino = Tetromino.random(colCount);
    nextTetromino = Tetromino.random(colCount);

    // 重置 Marathon 系統
    marathonSystem.reset();

    // 不自動播放背景音樂，等待用戶互動
    // await audioService.playBackgroundMusic();
  }

  // 獲取當前遊戲速度 (毫秒)
  int get dropSpeed {
    if (isMarathonMode) {
      return marathonSystem.getDropInterval();
    } else {
      // 傳統速度系統
      int level = score ~/ scorePerLevel;
      int currentSpeed = baseSpeed - (level * speedIncrease);
      return currentSpeed < maxSpeed ? maxSpeed : currentSpeed;
    }
  }

  // 獲取當前速度等級
  int get speedLevel {
    if (isMarathonMode) {
      return marathonSystem.currentLevel;
    } else {
      return (score ~/ scorePerLevel) + 1;
    }
  }

  // 獲取下一個速度等級所需分數
  int get nextLevelScore {
    if (isMarathonMode) {
      // Marathon 模式不基於分數升級
      return score + 1000; // 顯示用的假值
    } else {
      int currentLevel = score ~/ scorePerLevel;
      return (currentLevel + 1) * scorePerLevel;
    }
  }

  // 獲取到下一個等級還需要的分數
  int get scoreToNextLevel {
    if (isMarathonMode) {
      return 0; // Marathon 模式不基於分數升級
    } else {
      return nextLevelScore - score;
    }
  }

  /// 更新消除行數（Marathon 模式用）
  void updateLinesCleared(int lines) {
    if (isMarathonMode && lines > 0) {
      bool leveledUp = marathonSystem.updateLinesCleared(lines);
      if (leveledUp) {
        // 可以在這裡添加升級音效或特效
        audioService.playSoundEffect('level_up'); // 如果有的話
      }
    }
  }

  /// 切換遊戲模式
  void toggleGameMode() {
    isMarathonMode = !isMarathonMode;
    if (isMarathonMode) {
      marathonSystem.reset();
    }
  }

  /// 獲取當前關卡進度（Marathon 模式用）
  double get levelProgress {
    return isMarathonMode ? marathonSystem.levelProgress : 0.0;
  }

  /// 獲取到下一關的行數需求（Marathon 模式用）
  int get linesToNextLevel {
    return isMarathonMode ? marathonSystem.linesToNextLevel : 0;
  }

  /// 切換Ghost piece顯示狀態
  void toggleGhostPiece() {
    isGhostPieceEnabled = !isGhostPieceEnabled;
  }

  Future<void> dispose() async {
    await audioService.dispose();
  }
}
