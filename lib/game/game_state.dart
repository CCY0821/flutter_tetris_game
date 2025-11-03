import 'dart:async';
import 'package:flutter/material.dart';
import '../models/tetromino.dart';
import '../services/audio_service.dart';
import '../services/scoring_service.dart';
import '../services/high_score_service.dart';
import '../core/game_persistence.dart';
import '../core/ui_constants.dart';
import 'marathon_system.dart';
import 'rune_energy_manager.dart';
import 'rune_system.dart';
import 'rune_loadout.dart';
import 'rune_events.dart';
import 'monotonic_timer.dart';
import 'piece_provider.dart';
import 'demon_spawn_manager.dart';

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
    // H型方塊設為稀有方塊：每30個方塊隨機出現1次
    // 🔥 Demon 方塊不應該被隨機生成，只能通過 DemonSpawnManager 觸發
    final bagWithoutSpecial = BagProvider(excludedTypes: {
      TetrominoType.H,
      TetrominoType.demon
    }); // 排除 H 和 Demon，剩餘 8 種標準方塊
    final rareH = RareBlockInterceptor(
      baseProvider: bagWithoutSpecial,
      rareType: TetrominoType.H,
      cycleLength: 30, // 每30個方塊出現1次H型
    );
    pieceProviderStack = PieceProviderStack(baseProvider: rareH);
  }

  // 工廠構造函數
  factory GameState() => instance;

  // 🛡️ 遊戲世代計數器（防止異步殘留事件）
  int _gameEpoch = 0;
  int get gameEpoch => _gameEpoch;

  // 🛡️ 輸入凍結機制（防止重複按鍵事件）
  DateTime? _inputFrozenUntil;

  bool get isInputFrozen {
    if (_inputFrozenUntil == null) return false;
    if (DateTime.now().isBefore(_inputFrozenUntil!)) return true;
    _inputFrozenUntil = null;
    return false;
  }

  void freezeInput(Duration duration) {
    _inputFrozenUntil = DateTime.now().add(duration);
    debugPrint('[GameState] Input frozen for ${duration.inMilliseconds}ms');
  }

  /// Tetris 標準可視區域高度（GUIDELINE 規範）
  /// 玩家可見的遊戲區域為 20 行
  static const int visibleRowCount = 20;

  /// Tetris 標準寬度（GUIDELINE 規範）
  /// 遊戲區域寬度固定為 10 列
  static const int colCount = 10;

  /// SRS 系統所需的緩衝區高度
  /// 用於方塊生成、旋轉檢測和 T-Spin 判定
  /// 緩衝區位於可視區域上方，不顯示給玩家
  static const int bufferRowCount = 20;

  /// 總矩陣大小（包含緩衝區和可視區域）
  /// 40 行 = 20 行緩衝區 + 20 行可視區域
  /// 10 列（無水平緩衝區）
  static const int totalRowCount = bufferRowCount + visibleRowCount;

  /// 向後兼容的行數常數（等同於 visibleRowCount）
  /// @deprecated 使用 visibleRowCount 替代以保持語義清晰
  static const int rowCount = visibleRowCount;

  /// 檢查座標是否在遊戲板有效範圍內（包含緩衝區）
  /// 返回 true 如果座標在有效範圍內
  static bool isValidCoordinate(int x, int y) {
    return x >= 0 && x < colCount && y >= 0 && y < totalRowCount;
  }

  /// 檢查座標是否在可視區域內（不包含緩衝區）
  /// 返回 true 如果座標在可視區域內
  static bool isInVisibleArea(int y) {
    return y >= bufferRowCount && y < totalRowCount;
  }

  List<List<Color?>> board = [];
  List<List<TetrominoType?>> boardTypes = []; // 儲存每個格子的方塊類型（用於渲染）
  Tetromino? currentTetromino;
  Tetromino? nextTetromino;
  List<Tetromino> nextTetrominos = []; // 下三個方塊預覽隊列

  // 方塊供應器系統（用於實現 Gravity Reset 等符文）
  late PieceProviderStack pieceProviderStack;
  final AudioService audioService = AudioService();
  final MarathonSystem marathonSystem = MarathonSystem();
  final ScoringService scoringService = ScoringService();
  final RuneEnergyManager runeEnergyManager = RuneEnergyManager();

  // 惡魔方塊系統
  final DemonSpawnManager demonSpawnManager = DemonSpawnManager();

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

  // 📊 遊戲統計數據（用於結算畫面）
  int totalPiecesPlaced = 0; // 總放置方塊數
  int totalSpellsCast = 0; // 總施放法術次數
  DateTime? gameStartTime; // 遊戲開始時間

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

  // 惡魔方塊分數加成系統
  double scoreMultiplier = 1.0; // 分數乘數（1.0 或 3.0）
  DateTime? multiplierEndTime; // 加成結束時間

  // 遊戲模式：固定使用 Marathon 模式

  void initBoard() {
    // 創建包含緩衝區的完整矩陣 (40行 x 10列)
    board = List.generate(
      totalRowCount,
      (_) => List.generate(colCount, (_) => null),
    );
    boardTypes = List.generate(
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
      debugPrint('[GameState] Board changed by rune system');
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
    debugPrint('[GameState] Blessed Combo modifier initialized');

    _runeSystemInitialized = true;
    debugPrint('[GameState] Rune system initialized');
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
      debugPrint('[GameState] Loaded saved rune loadout - $runeLoadout');
    } else {
      // 使用預設空配置
      debugPrint('[GameState] Using default empty rune loadout');
    }
  }

  /// 保存符文配置並重新載入符文系統
  Future<void> saveRuneLoadout() async {
    await GamePersistence.saveRuneLoadout(runeLoadout);
    // 重新初始化符文系統槽位
    if (_runeSystemInitialized) {
      runeSystem.reloadLoadout();
      debugPrint('[GameState] Rune loadout saved and system reloaded');
    }
  }

  Future<void> startGame() async {
    // ✅ 遞增遊戲世代，使所有舊的異步事件失效
    _gameEpoch++;
    debugPrint('[GameState] Starting new game, epoch = $_gameEpoch');

    // ✅ 凍結輸入，防止重複事件
    freezeInput(AnimationConstants.inputFreezeDuration);

    initBoard();
    score = 0;
    isGameOver = false;
    isPaused = false;

    // 📊 重置統計數據
    totalPiecesPlaced = 0;
    totalSpellsCast = 0;
    gameStartTime = DateTime.now();

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

    // 重置惡魔方塊系統
    debugPrint('[GameState] Resetting demon spawn manager...');
    demonSpawnManager.reset();
    scoreMultiplier = 1.0;
    multiplierEndTime = null;
    debugPrint(
        '[GameState] Score reset to: $score, Multiplier: $scoreMultiplier');

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

  // ==================== 惡魔方塊分數加成系統 ====================

  /// 啟動分數加成（支援疊加）
  /// 當惡魔方塊放置後調用，啟動 10 秒的 ×3 分數加成
  ///
  /// [duration] 加成持續時間（預設 10 秒）
  ///
  /// 疊加規則：
  /// - 如果當前仍在加成期間，新的加成時間會疊加到剩餘時間上
  /// - 例如：剩餘 5 秒時再次觸發，總時間變為 15 秒
  void startScoreMultiplier({Duration duration = const Duration(seconds: 10)}) {
    final now = DateTime.now();

    if (multiplierEndTime != null && now.isBefore(multiplierEndTime!)) {
      // 當前仍在加成期間，疊加時間
      final remaining = multiplierEndTime!.difference(now);
      multiplierEndTime = now.add(remaining + duration);

      debugPrint(
          '[GameState] Score multiplier stacked! Total time: ${remaining.inSeconds + duration.inSeconds}s');
    } else {
      // 加成已結束或未啟動，重新開始
      multiplierEndTime = now.add(duration);
      debugPrint(
          '[GameState] Score multiplier activated! Duration: ${duration.inSeconds}s');
    }

    scoreMultiplier = 3.0;
  }

  /// 檢查分數加成是否到期
  /// 應該在遊戲循環中每幀調用（或使用 Timer）
  void checkMultiplierExpiry() {
    if (multiplierEndTime != null) {
      final now = DateTime.now();
      // 使用 !isBefore 來包含相等的情況（處理零持續時間）
      if (!now.isBefore(multiplierEndTime!)) {
        // 加成時間到期
        scoreMultiplier = 1.0;
        multiplierEndTime = null;
        debugPrint('[GameState] Score multiplier expired');
      }
    }
  }

  /// 獲取分數加成剩餘時間（秒）
  /// 返回 null 表示沒有加成
  double? getMultiplierRemainingSeconds() {
    if (multiplierEndTime == null) return null;

    final remaining = multiplierEndTime!.difference(DateTime.now());
    if (remaining.isNegative) return null;

    return remaining.inMilliseconds / 1000.0;
  }

  /// 檢查是否有分數加成激活
  bool get hasActiveMultiplier =>
      multiplierEndTime != null && DateTime.now().isBefore(multiplierEndTime!);

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
    debugPrint('[GameState] Time Change activated - speed multiplier: ×10');
  }

  /// 停用 Time Change 效果
  void deactivateTimeChange() {
    _isTimeChangeActive = false;
    debugPrint('[GameState] Time Change deactivated - speed restored');
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

      // 震動結束後重置狀態
      _shakeTimer = Timer(
          const Duration(milliseconds: AnimationConstants.shakeDurationMs), () {
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
