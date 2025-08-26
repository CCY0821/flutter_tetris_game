import 'dart:async';
import 'package:flutter/material.dart';
import '../models/tetromino.dart';
import '../services/audio_service.dart';
import '../services/scoring_service.dart';
import '../services/high_score_service.dart';
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
  List<Tetromino> nextTetrominos = []; // 下三個方塊預覽隊列
  final AudioService audioService = AudioService();
  final MarathonSystem marathonSystem = MarathonSystem();
  final ScoringService scoringService = ScoringService();

  int score = 0;
  int highScore = 0;
  bool isGameOver = false;
  bool isPaused = false;

  // Ghost piece 設定
  bool isGhostPieceEnabled = true;

  // 最後一次得分結果
  ScoringResult? lastScoringResult;

  // 震動特效相關
  bool _isScreenShaking = false;
  VoidCallback? _onShakeRequested;
  Timer? _shakeTimer;

  // 遊戲模式：固定使用 Marathon 模式

  void initBoard() {
    // 創建包含緩衝區的完整矩陣 (40行 x 10列)
    board = List.generate(
      totalRowCount,
      (_) => List.generate(colCount, (_) => null),
    );
  }

  // 設置震動回調
  void setShakeCallback(VoidCallback callback) {
    _onShakeRequested = callback;
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
    await _loadHighScore();
  }

  Future<void> _loadHighScore() async {
    await HighScoreService.instance.initialize();
    highScore = HighScoreService.instance.highScore;
  }

  Future<void> startGame() async {
    initBoard();
    score = 0;
    isGameOver = false;
    isPaused = false;
    currentTetromino = Tetromino.random(colCount);
    nextTetromino = Tetromino.random(colCount);

    // 初始化下三個方塊預覽隊列
    nextTetrominos.clear();
    for (int i = 0; i < 3; i++) {
      nextTetrominos.add(Tetromino.random(colCount));
    }

    // 重置 Marathon 系統和得分系統
    marathonSystem.reset();
    scoringService.reset();

    // 重新開始時播放背景音樂
    if (audioService.isMusicEnabled) {
      await audioService.playBackgroundMusic();
    }
  }

  // 獲取當前遊戲速度 (毫秒)
  int get dropSpeed {
    return marathonSystem.getDropInterval();
  }

  // 獲取當前速度等級
  int get speedLevel {
    return marathonSystem.currentLevel;
  }

  // 獲取下一個速度等級所需分數 (Marathon 模式不基於分數升級)
  int get nextLevelScore {
    return score + 1000; // 顯示用的假值
  }

  // 獲取到下一個等級還需要的分數 (Marathon 模式不基於分數升級)
  int get scoreToNextLevel {
    return 0;
  }

  /// 更新消除行數
  void updateLinesCleared(int lines) {
    if (lines > 0) {
      bool leveledUp = marathonSystem.updateLinesCleared(lines);
      if (leveledUp) {
        // 可以在這裡添加升級音效或特效
        audioService.playSoundEffect('level_up'); // 如果有的話
      }
    }
  }


  /// 獲取當前關卡進度
  double get levelProgress {
    return marathonSystem.levelProgress;
  }

  /// 獲取到下一關的行數需求
  int get linesToNextLevel {
    return marathonSystem.linesToNextLevel;
  }

  /// 切換Ghost piece顯示狀態
  void toggleGhostPiece() {
    isGhostPieceEnabled = !isGhostPieceEnabled;
  }

  /// 觸發畫面震動特效
  void triggerScreenShake() {
    if (!_isScreenShaking && _onShakeRequested != null) {
      _isScreenShaking = true;
      _onShakeRequested!();

      // 取消現有的計時器
      _shakeTimer?.cancel();

      // 400ms後重置狀態
      _shakeTimer = Timer(const Duration(milliseconds: 400), () {
        _isScreenShaking = false;
        _shakeTimer = null;
      });
    }
  }

  Future<void> dispose() async {
    // 取消震動計時器
    _shakeTimer?.cancel();
    _shakeTimer = null;

    await audioService.dispose();
  }
}
