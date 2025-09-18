import 'dart:async';
import 'package:flutter/material.dart';
import '../models/tetromino.dart';
import '../services/audio_service.dart';
import '../services/scoring_service.dart';
import '../services/high_score_service.dart';
import '../core/game_persistence.dart';
import 'marathon_system.dart';
import 'rune_energy_manager.dart';
import 'rune_system.dart';
import 'rune_loadout.dart';
import 'rune_events.dart';
import 'monotonic_timer.dart';
import 'piece_provider.dart';

class GameState {
  // 單例模式
  static GameState? _instance;
  static GameState get instance {
    _instance ??= GameState._internal();
    return _instance!;
  }

  // 私有構造函數
  GameState._internal() {
    // 初始化方塊供應器系統
    pieceProviderStack = PieceProviderStack(baseProvider: BagProvider());
  }

  // 工廠構造函數
  factory GameState() => instance;

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

  // 方塊供應器系統（用於實現 Gravity Reset 等符文）
  late PieceProviderStack pieceProviderStack;
  final AudioService audioService = AudioService();
  final MarathonSystem marathonSystem = MarathonSystem();
  final ScoringService scoringService = ScoringService();
  final RuneEnergyManager runeEnergyManager = RuneEnergyManager();

  // 符文系統
  final RuneLoadout runeLoadout = RuneLoadout();
  late RuneSystem runeSystem;
  bool _runeSystemInitialized = false;

  // Getter for rune system initialization status
  bool get hasRuneSystemInitialized => _runeSystemInitialized;

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

  // UI更新回調
  VoidCallback? _notifyUIUpdate;

  // Time Change 效果狀態
  bool _isTimeChangeActive = false;

  // Blessed Combo 效果狀態
  bool _isBlessedComboActive = false;
  late BlessedComboModifier _blessedComboModifier;

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

  // 設置UI更新回調
  void setUIUpdateCallback(VoidCallback callback) {
    _notifyUIUpdate = callback;
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
    await _loadRuneLoadout();
    _initializeRuneSystem();
  }

  /// 初始化符文系統
  void _initializeRuneSystem() {
    // 初始化事件總線
    RuneEventBus.initialize();

    // 創建符文系統實例
    runeSystem = RuneSystem(runeLoadout);
    runeSystem.setEnergyManager(runeEnergyManager);
    runeSystem.setBoardChangeCallback(() {
      // 棋盤變化通知，觸發UI更新
      debugPrint('GameState: Board changed by rune system');
      _notifyUIUpdate?.call();
    });

    // 設置能量變化回調來觸發UI更新
    runeEnergyManager.setOnEnergyChanged(() {
      debugPrint('Energy changed! Triggering UI update...');
      // 觸發UI更新 - 這會讓依賴GameState的Widget重新構建
      _notifyUIUpdate?.call();
    });

    // 啟動單調時鐘
    MonotonicTimer.start();

    // 初始化 Blessed Combo 修改器
    _blessedComboModifier = BlessedComboModifier(() => _isBlessedComboActive);
    scoringService.addModifier(_blessedComboModifier);
    debugPrint('GameState: Blessed Combo modifier initialized');

    _runeSystemInitialized = true;
    debugPrint('GameState: Rune system initialized');
  }

  Future<void> _loadHighScore() async {
    await HighScoreService.instance.initialize();
    highScore = HighScoreService.instance.highScore;
  }

  /// 載入符文配置
  Future<void> _loadRuneLoadout() async {
    final savedLoadout = await GamePersistence.loadRuneLoadout();
    if (savedLoadout != null) {
      // 載入保存的配置
      runeLoadout.slots = List<RuneType?>.from(savedLoadout.slots);
      debugPrint('GameState: Loaded saved rune loadout - $runeLoadout');
    } else {
      // 使用預設空配置
      debugPrint('GameState: Using default empty rune loadout');
    }
  }

  /// 保存符文配置並重新載入符文系統
  Future<void> saveRuneLoadout() async {
    await GamePersistence.saveRuneLoadout(runeLoadout);
    // 重新初始化符文系統槽位
    if (_runeSystemInitialized) {
      runeSystem.reloadLoadout();
      debugPrint('GameState: Rune loadout saved and system reloaded');
    }
  }

  Future<void> startGame() async {
    initBoard();
    score = 0;
    isGameOver = false;
    isPaused = false;

    // 重置方塊供應器系統（清除所有攔截器）
    pieceProviderStack.clear();

    // 使用方塊供應器系統生成初始方塊
    currentTetromino = _createTetrominoFromType(pieceProviderStack.getNext());
    nextTetromino = _createTetrominoFromType(pieceProviderStack.getNext());

    // 初始化下三個方塊預覽隊列
    nextTetrominos.clear();
    final previewTypes = pieceProviderStack.preview(3);
    for (int i = 0; i < 3; i++) {
      if (i < previewTypes.length) {
        nextTetrominos.add(_createTetrominoFromType(previewTypes[i]));
      } else {
        // 備用逆向兼容
        nextTetrominos.add(Tetromino.random(colCount));
      }
    }

    // 重置 Marathon 系統、得分系統和符文能量系統
    marathonSystem.reset();
    scoringService.reset();
    runeEnergyManager.reset();

    // 重新載入符文配置（清除運行時狀態）
    runeSystem.reloadLoadout();

    // 重新開始時播放背景音樂
    if (audioService.isMusicEnabled) {
      await audioService.playBackgroundMusic();
    }
  }

  /// 從方塊供應器系統生成一個 Tetromino 實例
  Tetromino _createTetrominoFromType(TetrominoType type) {
    return Tetromino.fromType(type, colCount);
  }

  /// 更新預覽隊列（當有新的攔截器時調用）
  void updatePreviewQueue() {
    final previewTypes = pieceProviderStack.preview(3);
    nextTetrominos.clear();

    for (int i = 0; i < 3; i++) {
      if (i < previewTypes.length) {
        nextTetrominos.add(_createTetrominoFromType(previewTypes[i]));
      } else {
        // 備用逆向兼容
        nextTetrominos.add(Tetromino.random(colCount));
      }
    }

    debugPrint(
        'GameState: Updated preview queue: ${previewTypes.map((t) => t.name).join(', ')}');
  }

  // 獲取當前遊戲速度 (毫秒)
  int get dropSpeed {
    int baseSpeed = marathonSystem.getDropInterval();

    // 如果 Time Change 效果激活，速度變為 0.5 倍（間隔變為 2 倍）
    if (_isTimeChangeActive) {
      return baseSpeed * 2;
    }

    return baseSpeed;
  }

  // 獲取當前速度等級
  int get speedLevel {
    return marathonSystem.currentLevel;
  }

  /// 激活 Time Change 效果
  void activateTimeChange() {
    _isTimeChangeActive = true;
    // 原始速度由 marathonSystem 管理，不需要額外存儲
    debugPrint('GameState: Time Change activated - speed multiplier: ×10');
  }

  /// 停用 Time Change 效果
  void deactivateTimeChange() {
    _isTimeChangeActive = false;
    debugPrint('GameState: Time Change deactivated - speed restored');
  }

  /// 檢查 Time Change 是否激活
  bool get isTimeChangeActive => _isTimeChangeActive;

  /// 激活 Blessed Combo 效果
  void activateBlessedCombo() {
    _isBlessedComboActive = true;
    debugPrint(
        'GameState: Blessed Combo activated - natural line clear score ×3 for 10 seconds');
  }

  /// 停用 Blessed Combo 效果
  void deactivateBlessedCombo() {
    _isBlessedComboActive = false;
    debugPrint(
        'GameState: Blessed Combo deactivated - score multiplier restored');
  }

  /// 檢查 Blessed Combo 是否激活
  bool get isBlessedComboActive => _isBlessedComboActive;

  // 獲取下一個速度等級所需分數 (Marathon 模式不基於分數升級)
  int get nextLevelScore {
    return score + 1000; // 顯示用的假值
  }

  // 獲取到下一個等級還需要的分數 (Marathon 模式不基於分數升級)
  int get scoreToNextLevel {
    return 0;
  }

  /// 更新消除行數 (自然消除，非法术清除)
  void updateLinesCleared(int lines) {
    if (lines > 0) {
      bool leveledUp = marathonSystem.updateLinesCleared(lines);
      if (leveledUp) {
        // 可以在這裡添加升級音效或特效
        audioService.playSoundEffect('level_up'); // 如果有的話
      }

      // 自然消除行数产生符文能量
      // 注意: 法术造成的清除不可调用此方法
      runeEnergyManager.addScore(lines);
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

  /// 保存當前遊戲狀態到本地存儲
  Future<bool> saveState() async {
    try {
      final gameData = GameStateData(
        board: List.from(board.map((row) => List<Color?>.from(row))),
        currentTetromino: currentTetromino?.copy(),
        nextTetromino: nextTetromino?.copy(),
        nextTetrominos: nextTetrominos.map((t) => t.copy()).toList(),
        score: score,
        highScore: highScore,
        isGameOver: isGameOver,
        isPaused: isPaused,
        isGhostPieceEnabled: isGhostPieceEnabled,
        marathonCurrentLevel: marathonSystem.currentLevel,
        marathonTotalLinesCleared: marathonSystem.totalLinesCleared,
        marathonLinesInCurrentLevel: marathonSystem.linesInCurrentLevel,
        scoringComboCount: scoringService.currentCombo,
        scoringLastWasDifficultClear: scoringService.isBackToBackReady,
        scoringTotalLinesCleared: scoringService.totalLinesCleared,
        scoringMaxCombo: scoringService.maxCombo,
        scoringStatistics: scoringService.getStatistics(),
      );
      return await GamePersistence.saveGameState(gameData);
    } catch (e) {
      debugPrint('Failed to save game state: $e');
      return false;
    }
  }

  /// 從本地存儲載入遊戲狀態
  Future<bool> loadState() async {
    try {
      final gameData = await GamePersistence.loadGameState();
      if (gameData == null || !gameData.isValidGameInProgress()) {
        debugPrint('No valid saved game state found');
        return false;
      }

      // 恢復基本遊戲狀態
      board = List.from(gameData.board.map((row) => List<Color?>.from(row)));
      currentTetromino = gameData.currentTetromino?.copy();
      nextTetromino = gameData.nextTetromino?.copy();
      nextTetrominos = gameData.nextTetrominos.map((t) => t.copy()).toList();
      score = gameData.score;
      highScore = gameData.highScore;
      isGameOver = gameData.isGameOver;
      isPaused = gameData.isPaused; // 保持暫停狀態
      isGhostPieceEnabled = gameData.isGhostPieceEnabled;

      // 恢復 Marathon 系統狀態
      marathonSystem.setLevel(
        gameData.marathonCurrentLevel,
        totalLines: gameData.marathonTotalLinesCleared,
      );
      marathonSystem
          .setLinesInCurrentLevel(gameData.marathonLinesInCurrentLevel);

      // 恢復 Scoring 服務狀態
      scoringService.restoreState(
        comboCount: gameData.scoringComboCount,
        lastWasDifficultClear: gameData.scoringLastWasDifficultClear,
        totalLinesCleared: gameData.scoringTotalLinesCleared,
        maxCombo: gameData.scoringMaxCombo,
        statistics: gameData.scoringStatistics,
      );

      debugPrint('Game state loaded successfully: $gameData');
      return true;
    } catch (e) {
      debugPrint('Failed to load game state: $e');
      return false;
    }
  }

  /// 清除保存的遊戲狀態 (開始新遊戲時調用)
  Future<void> clearSavedState() async {
    await GamePersistence.clearGameState();
    debugPrint('Saved game state cleared');
  }

  /// 檢查是否有有效的保存狀態
  Future<bool> hasSavedState() async {
    try {
      final gameData = await GamePersistence.loadGameState();
      return gameData != null && gameData.isValidGameInProgress();
    } catch (e) {
      debugPrint('Error checking saved state: $e');
      return false;
    }
  }

  /// 檢查當前遊戲狀態是否有效 (非全新狀態)
  bool isValidGameInProgress() {
    // 嚴格檢查：必須同時滿足以下條件才認為是有效的進行中遊戲
    return !isGameOver &&
        currentTetromino != null &&
        nextTetromino != null &&
        (score > 0 || marathonSystem.totalLinesCleared > 0 || !_isBoardEmpty());
  }

  /// 檢查棋盤是否為空
  bool _isBoardEmpty() {
    for (final row in board) {
      for (final cell in row) {
        if (cell != null) return false;
      }
    }
    return true;
  }

  Future<void> dispose() async {
    // 取消震動計時器
    _shakeTimer?.cancel();
    _shakeTimer = null;

    // 清理符文系統
    runeSystem.dispose();
    RuneEventBus.dispose();
    MonotonicTimer.stop();

    await audioService.dispose();
  }
}
