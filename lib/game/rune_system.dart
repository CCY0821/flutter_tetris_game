import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../models/tetromino.dart';
import '../core/dual_logger.dart';
import 'monotonic_timer.dart';
import 'rune_events.dart';
import 'rune_definitions.dart';
import 'rune_loadout.dart';
import 'rune_batch_processor.dart';
import 'rune_energy_manager.dart';

/// 重力模式枚舉
enum GravityMode {
  /// Row Gravity: 整列下移，保留列內空洞
  row,

  /// Column Gravity: 逐列壓實，消除縱向空洞
  column,
}

/// 符文施法錯誤類型
enum RuneCastError {
  success,
  energyInsufficient, // 能量不足
  cooldownActive, // 冷卻中
  temporalMutualExclusive, // 時間系互斥
  frameThrottled, // 單幀節流
  slotEmpty, // 槽位為空
  ghostInvalid, // 影子無效（Column Breaker專用）
  noValidTargets, // 無有效目標（Dragon Roar專用）
  systemError, // 系統錯誤
}

/// 符文施法結果
class RuneCastResult {
  final RuneCastError error;
  final String message;
  final bool energyRefunded;
  final Map<String, dynamic> data;

  const RuneCastResult({
    required this.error,
    required this.message,
    this.energyRefunded = false,
    this.data = const {},
  });

  bool get isSuccess => error == RuneCastError.success;
  bool get isFailure => !isSuccess;

  // 快捷構造方法
  static const RuneCastResult success = RuneCastResult(
    error: RuneCastError.success,
    message: '施法成功',
  );

  static RuneCastResult failure(RuneCastError error, String message) {
    return RuneCastResult(error: error, message: message);
  }

  static RuneCastResult refund(String message) {
    return RuneCastResult(
      error: RuneCastError.success,
      message: message,
      energyRefunded: true,
    );
  }
}

/// 符文槽狀態
enum RuneSlotState {
  empty, // 空槽
  ready, // 準備就緒
  cooling, // 冷卻中
  active, // 效果激活中
  disabled, // 被禁用（如時間系互斥）
}

/// 符文槽狀態管理
class RuneSlot {
  RuneType? runeType;
  RuneSlotState state = RuneSlotState.empty;
  int cooldownStartTime = 0;
  int cooldownEndTime = 0;
  int effectStartTime = 0;
  int effectEndTime = 0;

  /// 獲取符文定義
  RuneDefinition? get definition =>
      runeType != null ? RuneConstants.getDefinition(runeType!) : null;

  /// 是否可以施法
  bool get canCast => state == RuneSlotState.ready;

  /// 是否在冷卻中
  bool get isCooling => state == RuneSlotState.cooling;

  /// 是否效果激活中
  bool get isActive => state == RuneSlotState.active;

  /// 是否被禁用
  bool get isDisabled => state == RuneSlotState.disabled;

  /// 獲取冷卻剩餘時間（毫秒）
  int get cooldownRemaining => _getCooldownRemaining(MonotonicTimer.now);

  /// 內部方法：用統一的 nowMs 計算剩餘時間
  int _getCooldownRemaining(int nowMs) {
    if (cooldownEndTime <= 0) return 0;
    final raw = cooldownEndTime - nowMs;
    const kCooldownEpsilonMs = 16; // 一幀誤差容忍
    return (raw <= kCooldownEpsilonMs) ? 0 : raw;
  }

  /// 獲取效果剩餘時間（毫秒）
  int get effectRemaining => math.max(0, effectEndTime - MonotonicTimer.now);

  /// 獲取冷卻進度 (0.0 - 1.0)
  double get cooldownProgress {
    return _getCooldownProgress(MonotonicTimer.now);
  }

  /// 內部方法：用統一的邏輯計算冷卻進度
  double _getCooldownProgress(int nowMs) {
    final total = cooldownEndTime - cooldownStartTime;
    if (total <= 0) return 1.0;

    final remaining = _getCooldownRemaining(nowMs);
    return (1.0 - remaining / total).clamp(0.0, 1.0);
  }

  /// 獲取效果進度 (0.0 - 1.0)
  double get effectProgress {
    if (!isActive || effectEndTime <= effectStartTime) return 0.0;
    final remaining = effectRemaining;
    final total = effectEndTime - effectStartTime;
    return (remaining / total).clamp(0.0, 1.0);
  }

  /// 更新狀態（每幀調用）
  void update() {
    if (runeType == null) {
      state = RuneSlotState.empty;
      return;
    }

    final now = MonotonicTimer.now;

    // 檢查效果是否結束
    if (effectEndTime > 0 && now >= effectEndTime) {
      effectEndTime = 0;
      effectStartTime = 0;
    }

    // 🔥 關鍵修復：用統一的 clamp 邏輯計算剩餘時間
    final cooldownRemainingMs = _getCooldownRemaining(now);

    // 檢查冷卻是否結束（用 clamp 後的結果判斷）
    if (cooldownEndTime > 0 && cooldownRemainingMs == 0) {
      cooldownEndTime = 0;
      cooldownStartTime = 0;
      logCrit('RuneSlot.update: Cooldown completed, resetting times');
    }

    // 更新狀態（用同一套邏輯：clamp 後的剩餘時間）
    final oldState = state;
    if (effectEndTime > now) {
      state = RuneSlotState.active;
    } else if (cooldownRemainingMs > 16) {
      // 🔥 修復：必須有明顯剩餘時間才算冷卻中
      state = RuneSlotState.cooling;
    } else {
      state = RuneSlotState.ready;
      // 🔥 ChatGPT核心修復：狀態轉換為ready時強制清除冷卻時間，確保完全同步
      if (cooldownEndTime > 0) {
        cooldownEndTime = 0;
        cooldownStartTime = 0;
        logCrit('RuneSlot.update: ChatGPT修復 + 邏輯修復 - 強制清除冷卻時間與狀態同步');
      }
    }

    // 調試日誌：狀態變化
    if (oldState != state) {
      logCrit(
          'RuneSlot.update: State changed from $oldState to $state (remaining=${cooldownRemainingMs}ms)');
    }

    // 自癒保險：防呆檢測（理論上不應該再觸發）
    if (state == RuneSlotState.cooling && cooldownRemainingMs == 0) {
      logCrit('RuneSlot.update: AUTO-HEAL - forcing cooling->ready');
      state = RuneSlotState.ready;
    }
  }

  /// 開始冷卻
  void startCooldown(int durationMs) {
    final now = MonotonicTimer.now;
    cooldownStartTime = now;
    cooldownEndTime = now + durationMs;
    debugPrint(
        'RuneSlot: Cooldown started - now=$now, endTime=$cooldownEndTime, duration=${durationMs}ms');
  }

  /// 開始效果
  void startEffect(int durationMs) {
    if (durationMs > 0) {
      final now = MonotonicTimer.now;
      effectStartTime = now;
      effectEndTime = now + durationMs;
    }
  }

  /// 設置禁用狀態
  void setDisabled(bool disabled) {
    if (disabled && state == RuneSlotState.ready) {
      state = RuneSlotState.disabled;
    } else if (!disabled && state == RuneSlotState.disabled) {
      state = RuneSlotState.ready;
    }
  }

  /// 重置槽位
  void reset() {
    state = runeType == null ? RuneSlotState.empty : RuneSlotState.ready;
    cooldownStartTime = 0;
    cooldownEndTime = 0;
    effectStartTime = 0;
    effectEndTime = 0;
  }
}

/// 重力處理器
/// 負責執行清列後的重力效果，支援兩種重力模式
class GravityProcessor {
  /// 應用重力效果到指定的清除行
  ///
  /// [board] 遊戲棋盤
  /// [clearedRows] 被清除的行號列表（必須由下而上排序）
  /// [mode] 重力模式
  /// 返回移動的方塊數量
  static int applyGravity(
    List<List<Color?>> board,
    List<int> clearedRows,
    GravityMode mode,
  ) {
    if (clearedRows.isEmpty || board.isEmpty) return 0;

    // 確保由下而上處理（從最大row開始）
    final sortedRows = List<int>.from(clearedRows)
      ..sort((a, b) => b.compareTo(a));

    switch (mode) {
      case GravityMode.row:
        return _applyRowGravity(board, sortedRows);
      case GravityMode.column:
        return _applyColumnGravity(board, sortedRows);
    }
  }

  /// Row Gravity: 整列下移，保留列內空洞結構
  static int _applyRowGravity(List<List<Color?>> board, List<int> sortedRows) {
    int totalMoved = 0;
    final boardHeight = board.length;
    final boardWidth = board[0].length;

    // 對每個被清除的行，從下往上處理
    for (final clearedRow in sortedRows) {
      if (clearedRow < 0 || clearedRow >= boardHeight) continue;

      // 將該行之上的所有行整列下移
      for (int row = clearedRow; row > 0; row--) {
        for (int col = 0; col < boardWidth; col++) {
          board[row][col] = board[row - 1][col];
          if (board[row][col] != null) totalMoved++;
        }
      }

      // 最上方補空行
      for (int col = 0; col < boardWidth; col++) {
        board[0][col] = null;
      }
    }

    return totalMoved;
  }

  /// Column Gravity: 逐列壓實，消除所有縱向空洞
  static int _applyColumnGravity(
      List<List<Color?>> board, List<int> sortedRows) {
    int totalMoved = 0;
    final boardHeight = board.length;
    final boardWidth = board[0].length;

    // 對每一列進行壓實
    for (int col = 0; col < boardWidth; col++) {
      final columnBlocks = <Color?>[];

      // 收集該列中所有非空的方塊
      for (int row = boardHeight - 1; row >= 0; row--) {
        if (board[row][col] != null) {
          columnBlocks.add(board[row][col]);
        }
      }

      // 清空該列
      for (int row = 0; row < boardHeight; row++) {
        board[row][col] = null;
      }

      // 將方塊從底部開始填回（壓實效果）
      for (int i = 0; i < columnBlocks.length; i++) {
        board[boardHeight - 1 - i][col] = columnBlocks[i];
        totalMoved++;
      }
    }

    return totalMoved;
  }
}

/// 符文系統主類
/// 管理3個符文槽的運行時狀態，處理施法邏輯、時間系互斥、單幀節流等
class RuneSystem {
  /// 符文配置
  final RuneLoadout loadout;

  /// 符文槽狀態
  final List<RuneSlot> slots = List.generate(3, (_) => RuneSlot());

  /// 批處理系統
  final RuneBatchProcessor batchProcessor = RuneBatchProcessor();

  /// 能量管理器引用
  RuneEnergyManager? _energyManager;

  /// 當前激活的時間系符文
  RuneType? _activeTemporalRune;
  Timer? _temporalEffectTimer;

  /// 基於時間的節流（毫秒）
  static const int _castThrottleMs = 250; // 250ms節流間隔
  int _lastCastTime = 0;

  /// 事件訂閱
  StreamSubscription<RuneEvent>? _eventSubscription;

  RuneSystem(this.loadout) {
    _initializeSlots();
    _subscribeToEvents();
  }

  /// 設置能量管理器
  void setEnergyManager(RuneEnergyManager energyManager) {
    _energyManager = energyManager;
  }

  /// 設置棋盤變化回調
  void setBoardChangeCallback(VoidCallback callback) {
    batchProcessor.setOnBoardChanged(callback);
  }

  /// 初始化符文槽
  void _initializeSlots() {
    debugPrint('RuneSystem: Initializing slots...');
    for (int i = 0; i < slots.length; i++) {
      final runeType = loadout.getSlot(i);
      debugPrint('RuneSystem: Slot $i - runeType: $runeType');
      slots[i].runeType = runeType;
      slots[i].reset();
      debugPrint('RuneSystem: Slot $i - after reset: state=${slots[i].state}');
    }
    _updateTemporalMutex();
    debugPrint('RuneSystem: Slots initialized');
  }

  /// 訂閱事件
  void _subscribeToEvents() {
    if (RuneEventBus.isInitialized) {
      _eventSubscription = RuneEventBus.events.listen(_handleEvent);
    }
  }

  /// 處理事件
  void _handleEvent(RuneEvent event) {
    switch (event.type) {
      case RuneEventType.effectEnd:
        if (event.runeType == _activeTemporalRune) {
          _deactivateTemporalEffect();
        }
        break;
      default:
        break;
    }
  }

  /// 每邏輯幀更新（由 GameLogic 調用）
  void onLogicFrameStart() {
    // 節流現在基於時間，不需要重置標誌

    // 更新所有槽位狀態
    for (final slot in slots) {
      slot.update();
    }

    // 更新時間系互斥狀態
    _updateTemporalMutex();

    // 執行批處理操作（如果有的話）
    // 注意：棋盤參數由外部傳入
  }

  /// 執行批處理操作
  void executeBatch(List<List<Color?>> board) {
    debugPrint(
        'RuneSystem: executeBatch called, pending operations: ${batchProcessor.pendingOperationCount}');
    batchProcessor.execute(board);
  }

  /// 嘗試施法
  RuneCastResult castRune(int slotIndex,
      {required List<List<Color?>> board, dynamic gameContext}) {
    // 基礎檢查
    if (slotIndex < 0 || slotIndex >= slots.length) {
      return RuneCastResult.failure(RuneCastError.systemError, '槽位索引無效');
    }

    final slot = slots[slotIndex];

    // 檢查槽位是否為空
    if (slot.runeType == null) {
      return RuneCastResult.failure(RuneCastError.slotEmpty, '槽位為空');
    }

    // 基於時間的節流檢查
    final now = MonotonicTimer.now;
    if (now - _lastCastTime < _castThrottleMs) {
      return RuneCastResult.failure(RuneCastError.frameThrottled, '施法冷卻中');
    }

    final definition = RuneConstants.getDefinition(slot.runeType!);

    // 狀態檢查
    if (slot.isCooling) {
      return RuneCastResult.failure(
        RuneCastError.cooldownActive,
        '冷卻中 (剩餘${(slot.cooldownRemaining / 1000).ceil()}秒)',
      );
    }

    if (slot.isDisabled) {
      return RuneCastResult.failure(
          RuneCastError.temporalMutualExclusive, '時間系效果互斥');
    }

    // 能量檢查
    if (_energyManager != null &&
        !_energyManager!.canConsume(definition.energyCost)) {
      return RuneCastResult.failure(RuneCastError.energyInsufficient, '能量不足');
    }

    // 時間系互斥檢查
    if (definition.isTemporal &&
        _activeTemporalRune != null &&
        _activeTemporalRune != slot.runeType) {
      return RuneCastResult.failure(
          RuneCastError.temporalMutualExclusive, '時間系效果互斥');
    }

    // 特殊符文檢查
    final specialCheckResult =
        _performSpecialChecks(slot.runeType!, board, gameContext);
    if (specialCheckResult.isFailure) {
      return specialCheckResult;
    }

    // 執行施法
    try {
      _lastCastTime = now; // 記錄施法時間

      // 發送施法事件
      RuneEventBus.emitCast(slot.runeType!);

      // 執行符文效果
      final executeResult =
          _executeRuneEffect(slot.runeType!, board, gameContext);

      // 如果是退還能量的情況，不消耗能量和冷卻
      if (executeResult.energyRefunded) {
        logCrit('RuneSystem: Energy refunded, skipping cooldown');
        return executeResult;
      }

      // 消耗能量
      if (_energyManager != null) {
        _energyManager!.consumeBars(definition.energyCost);
        logCrit('RuneSystem: Energy consumed ${definition.energyCost} bars');
      }

      // 開始冷卻
      final cooldownMs = RuneBalance.getAdjustedCooldown(slot.runeType!) * 1000;
      logCrit(
          'RuneSystem: Starting cooldown for ${slot.runeType} - ${cooldownMs}ms');
      slot.startCooldown(cooldownMs);

      // 立即更新狀態，確保冷卻生效
      slot.update();
      logCrit(
          'RuneSystem: Slot state after cooldown: ${slot.state}, isCooling=${slot.isCooling}');

      // 開始效果（如果是持續性符文）
      if (definition.isTemporal && definition.durationSeconds > 0) {
        _activateTemporalEffect(slot.runeType!, definition.durationMs);
        slot.startEffect(definition.durationMs);
      }

      return RuneCastResult.success;
    } catch (e) {
      debugPrint('RuneSystem: Cast error - $e');
      return RuneCastResult.failure(RuneCastError.systemError, '施法失敗: $e');
    }
  }

  /// 特殊符文檢查
  RuneCastResult _performSpecialChecks(
      RuneType runeType, List<List<Color?>> board, dynamic gameContext) {
    switch (runeType) {
      case RuneType.columnBreaker:
        // Column Breaker 需要檢查影子是否有效
        if (gameContext?.calculateGhostPiece == null) {
          return RuneCastResult.failure(RuneCastError.ghostInvalid, '無法獲取影子位置');
        }
        final ghostPiece = gameContext.calculateGhostPiece();
        if (ghostPiece == null) {
          return RuneCastResult.failure(RuneCastError.ghostInvalid, '影子位置無效');
        }
        break;

      case RuneType.thunderStrike:
        // Thunder Strike 在空盤時會退還能量，不算錯誤
        break;

      case RuneType.thunderStrikeLeft:
        // Thunder Strike Left 在空盤時會退還能量，不算錯誤
        break;

      default:
        break;
    }

    return RuneCastResult.success;
  }

  /// 執行符文效果
  RuneCastResult _executeRuneEffect(
      RuneType runeType, List<List<Color?>> board, dynamic gameContext) {
    try {
      switch (runeType) {
        case RuneType.flameBurst:
          return _executeFlameBurst(board, gameContext);
        case RuneType.thunderStrike:
          return _executeThunderStrike(board, gameContext);
        case RuneType.thunderStrikeLeft:
          return _executeThunderStrikeLeft(board, gameContext);
        case RuneType.earthquake:
          return _executeEarthquake(board);
        case RuneType.angelsGrace:
          return _executeAngelsGrace(board);
        case RuneType.columnBreaker:
          return _executeColumnBreaker(board, gameContext);
        case RuneType.dragonRoar:
          return _executeDragonRoar(board, gameContext);
        case RuneType.gravityReset:
          return _executeGravityReset(board);
        case RuneType.titanGravity:
          return _executeTitanGravity(board, gameContext);
        case RuneType.timeSlow:
          return _executeTimeSlow();
        case RuneType.timeStop:
          return _executeTimeStop();
        case RuneType.timeChange:
          return _executeTimeChange();
        case RuneType.blessedCombo:
          return _executeBlessedCombo();
      }
    } catch (e) {
      debugPrint('RuneSystem: Execute error - $e');
      return RuneCastResult.failure(RuneCastError.systemError, '效果執行失敗: $e');
    }
  }

  /// 選擇最佳的清除目標行（已落地方塊最多的行）
  int _pickBestRowToClear(List<List<Color?>> board) {
    int bestRow = -1;
    int maxBlocks = 0;

    // 只檢查可見區域的行 (假設可見區域是底部20行)
    final startRow = math.max(0, board.length - 20);

    for (int row = startRow; row < board.length; row++) {
      int blockCount = 0;
      for (int col = 0; col < board[row].length; col++) {
        if (board[row][col] != null) {
          blockCount++;
        }
      }

      // 選擇方塊數量最多的行（但不是滿行，滿行會自然清除）
      if (blockCount > maxBlocks && blockCount < board[row].length) {
        maxBlocks = blockCount;
        bestRow = row;
      }
    }

    // 如果沒找到合適的行，選擇底部有方塊的行
    if (bestRow == -1) {
      for (int row = board.length - 1; row >= startRow; row--) {
        for (int col = 0; col < board[row].length; col++) {
          if (board[row][col] != null) {
            return row;
          }
        }
      }
    }

    return bestRow;
  }

  /// 執行 Flame Burst
  RuneCastResult _executeFlameBurst(
      List<List<Color?>> board, dynamic gameContext) {
    // 選擇最佳目標行（已落地方塊最多的行）
    final targetRow = _pickBestRowToClear(board);

    // 添加詳細的調試日誌
    debugPrint(
        '[FlameBurst] boardH=${board.length}, boardW=${board[0].length}');
    debugPrint('[FlameBurst] targetRow=$targetRow (best row with most blocks)');

    if (targetRow < 0) {
      debugPrint('[FlameBurst] No suitable row found to clear');
      return RuneCastResult.failure(RuneCastError.systemError, '找不到合適的清除目標');
    }

    if (targetRow >= board.length) {
      debugPrint('[FlameBurst] targetRow out of bounds: $targetRow');
      return RuneCastResult.failure(
          RuneCastError.systemError, '目標行位置無效: $targetRow');
    }

    // 檢查目標行在清除前的狀態
    int blockCount = 0;
    for (int col = 0; col < board[targetRow].length; col++) {
      if (board[targetRow][col] != null) {
        blockCount++;
      }
    }

    debugPrint(
        '[FlameBurst] Target row $targetRow has $blockCount blocks before clearing');

    // 階段1：直接執行清除操作
    int clearedCount = 0;
    for (int col = 0; col < board[targetRow].length; col++) {
      if (board[targetRow][col] != null) {
        board[targetRow][col] = null;
        clearedCount++;
      }
    }
    debugPrint('[FlameBurst] Cleared $clearedCount blocks from row $targetRow');

    // 階段2：上方方塊整體下移重力效果
    debugPrint('[FlameBurst] Applying upper block gravity effect...');
    int movedBlocks = 0;

    // 將消除行上方的所有行整體下移一行
    for (int row = targetRow; row > 0; row--) {
      for (int col = 0; col < board[row].length; col++) {
        board[row][col] = board[row - 1][col]; // 上一行內容複製到當前行
        if (board[row][col] != null) {
          movedBlocks++;
        }
      }
    }

    // 最上方補一行空行
    for (int col = 0; col < board[0].length; col++) {
      board[0][col] = null;
    }

    debugPrint(
        '[FlameBurst] Moved $movedBlocks blocks downward (upper gravity)');

    // 觸發棋盤更新回調
    batchProcessor.notifyBoardChanged();
    debugPrint(
        '[FlameBurst] Execution complete - Row cleared with upper block gravity effect');

    return RuneCastResult.success;
  }

  /// 執行 Thunder Strike - 直接操作模式（完全仿照 Flame Burst）
  /// 清除可見區域最右側兩列
  RuneCastResult _executeThunderStrike(
      List<List<Color?>> board, dynamic gameContext) {
    // 基本驗證和日誌 (仿照 Flame Burst)
    final boardHeight = board.length;
    final boardWidth = board[0].length;
    debugPrint('[ThunderStrike] boardH=$boardHeight, boardW=$boardWidth');

    // 邊界檢查
    if (boardWidth < 2) {
      debugPrint('[ThunderStrike] Board too narrow: $boardWidth');
      return RuneCastResult.failure(RuneCastError.systemError, '棋盤寬度不足');
    }

    // 目標確定 - 最右側兩列
    final targetColumns = [boardWidth - 2, boardWidth - 1];
    debugPrint(
        '[ThunderStrike] Target columns: ${targetColumns.join(",")} (rightmost 2 columns)');

    // 可見區域範圍 (完全仿照 Flame Burst)
    final startRow = math.max(0, boardHeight - 20);

    // 直接清除操作 - 雙列版本
    int totalClearedBlocks = 0;
    for (int targetColumn in targetColumns) {
      int columnClearedCount = 0;

      // 清除單列 (仿照 Flame Burst 的行清除邏輯)
      for (int row = startRow; row < boardHeight; row++) {
        if (board[row][targetColumn] != null) {
          board[row][targetColumn] = null;
          columnClearedCount++;
        }
      }

      debugPrint(
          '[ThunderStrike] Cleared $columnClearedCount blocks from column $targetColumn');
      totalClearedBlocks += columnClearedCount;
    }

    // 觸發 UI 更新（純清除，無重力壓實）
    batchProcessor.notifyBoardChanged();
    debugPrint(
        '[ThunderStrike] Execution complete - cleared $totalClearedBlocks blocks from 2 columns (no gravity compression)');

    return RuneCastResult.success;
  }

  /// 執行 Thunder Strike Left - 清除最左側兩列
  RuneCastResult _executeThunderStrikeLeft(
      List<List<Color?>> board, dynamic gameContext) {
    // 基本驗證和日誌 (仿照 Thunder Strike)
    final boardHeight = board.length;
    final boardWidth = board[0].length;
    debugPrint('[ThunderStrikeLeft] boardH=$boardHeight, boardW=$boardWidth');

    // 邊界檢查
    if (boardWidth < 2) {
      debugPrint('[ThunderStrikeLeft] Board too narrow: $boardWidth');
      return RuneCastResult.failure(RuneCastError.systemError, '棋盤寬度不足');
    }

    // 目標確定 - 最左側兩列
    final targetColumns = [0, 1];
    debugPrint(
        '[ThunderStrikeLeft] Target columns: ${targetColumns.join(",")} (leftmost 2 columns)');

    // 可見區域範圍 (完全仿照 Thunder Strike)
    final startRow = math.max(0, boardHeight - 20);

    // 直接清除操作 - 雙列版本
    int totalClearedBlocks = 0;
    for (int targetColumn in targetColumns) {
      int columnClearedCount = 0;

      // 清除單列 (仿照 Thunder Strike 的雙列清除邏輯)
      for (int row = startRow; row < boardHeight; row++) {
        if (board[row][targetColumn] != null) {
          board[row][targetColumn] = null;
          columnClearedCount++;
        }
      }

      debugPrint(
          '[ThunderStrikeLeft] Cleared $columnClearedCount blocks from column $targetColumn');
      totalClearedBlocks += columnClearedCount;
    }

    // 觸發 UI 更新（純清除，無重力壓實）
    batchProcessor.notifyBoardChanged();
    debugPrint(
        '[ThunderStrikeLeft] Execution complete - cleared $totalClearedBlocks blocks from 2 left columns (no gravity compression)');

    return RuneCastResult.success;
  }

  /// 執行 Earthquake
  RuneCastResult _executeEarthquake(List<List<Color?>> board) {
    batchProcessor.addOperation(ShiftBoardDownOperation(isSpellRemoval: true));
    return RuneCastResult.success;
  }

  /// 執行 Angel's Grace - 清空可視區域所有方塊
  RuneCastResult _executeAngelsGrace(List<List<Color?>> board) {
    // 基本驗證和日誌 (仿照其他直接操作法術)
    final boardHeight = board.length;
    final boardWidth = board[0].length;
    debugPrint('[AngelsGrace] boardH=$boardHeight, boardW=$boardWidth');

    // 可見區域範圍 (rows 20-39)
    final startRow = math.max(0, boardHeight - 20);
    debugPrint(
        '[AngelsGrace] Clearing visible area: rows $startRow-${boardHeight - 1} (all columns)');

    // 直接清除操作 - 清空所有可視區域方塊
    int totalClearedBlocks = 0;

    // 清除可視區域的所有方塊
    for (int row = startRow; row < boardHeight; row++) {
      for (int col = 0; col < boardWidth; col++) {
        if (board[row][col] != null) {
          board[row][col] = null;
          totalClearedBlocks++;
        }
      }
    }

    debugPrint(
        '[AngelsGrace] Cleared $totalClearedBlocks blocks from visible area');

    // 觸發 UI 更新（純清除，無重力壓實）
    batchProcessor.notifyBoardChanged();
    debugPrint(
        '[AngelsGrace] Execution complete - Angel\'s Grace cleared entire visible area (no gravity compression)');

    return RuneCastResult.success;
  }

  /// 執行 Column Breaker
  RuneCastResult _executeColumnBreaker(
      List<List<Color?>> board, dynamic gameContext) {
    final ghostPiece = gameContext.calculateGhostPiece();
    final targetCol = ghostPiece.x;

    batchProcessor
        .addOperation(ClearColumnOperation(targetCol, isSpellRemoval: true));
    return RuneCastResult.success;
  }

  /// 執行 Dragon Roar - 直接操作模式（完全仿照 Flame Burst）
  /// 清除遊戲板底部三行
  RuneCastResult _executeDragonRoar(
      List<List<Color?>> board, dynamic gameContext) {
    if (gameContext?.currentTetromino == null) {
      debugPrint('[DragonRoar] No active tetromino');
      return RuneCastResult.failure(RuneCastError.systemError, '無活動方塊');
    }

    // 添加詳細的調試日誌（仿照 Flame Burst）
    debugPrint(
        '[DragonRoar] boardH=${board.length}, boardW=${board[0].length}');

    // 清除可見遊戲區域的底部 3 行
    final visibleAreaBottom = board.length - 1; // 總板面最底行 (39)
    final targetRows = [
      visibleAreaBottom - 2, // 可見區域倒數第3行 (37)
      visibleAreaBottom - 1, // 可見區域倒數第2行 (38)
      visibleAreaBottom // 可見區域最底行 (39)
    ];

    debugPrint(
        '[DragonRoar] Targeting visible area bottom 3 rows: ${targetRows.join(",")} (rows ${targetRows[0]}-${targetRows[2]})');

    // 階段1：直接執行清除操作（仿照 Flame Burst）
    int totalClearedBlocks = 0;
    for (int targetRow in targetRows) {
      // 檢查目標行在清除前的狀態
      int blockCount = 0;
      for (int col = 0; col < board[targetRow].length; col++) {
        if (board[targetRow][col] != null) {
          blockCount++;
        }
      }
      debugPrint(
          '[DragonRoar] Target row $targetRow has $blockCount blocks before clearing');

      int clearedCount = 0;
      debugPrint(
          '[DragonRoar] Clearing row $targetRow: board width=${board[targetRow].length}');
      for (int col = 0; col < board[targetRow].length; col++) {
        if (board[targetRow][col] != null) {
          debugPrint('[DragonRoar] Clearing block at [$targetRow, $col]');
          board[targetRow][col] = null;
          clearedCount++;
        }
      }
      debugPrint(
          '[DragonRoar] Cleared $clearedCount blocks from row $targetRow');

      totalClearedBlocks += clearedCount;
    }

    // 階段2：上方方塊整體下移重力效果（與 Flame Burst 相同）
    debugPrint(
        '[DragonRoar] Applying upper block gravity effect for 3 cleared rows...');
    int totalMovedBlocks = 0;

    // 對每個清除的行都執行重力效果（從最上面的清除行開始）
    for (int i = 0; i < targetRows.length; i++) {
      int targetRow = targetRows[i];

      // 將消除行上方的所有行整體下移一行
      for (int row = targetRow; row > 0; row--) {
        for (int col = 0; col < board[row].length; col++) {
          board[row][col] = board[row - 1][col]; // 上一行內容複製到當前行
          if (board[row][col] != null) {
            totalMovedBlocks++;
          }
        }
      }

      // 最上方補一行空行
      for (int col = 0; col < board[0].length; col++) {
        board[0][col] = null;
      }

      debugPrint('[DragonRoar] Applied gravity for cleared row $targetRow');
    }

    debugPrint(
        '[DragonRoar] Moved $totalMovedBlocks blocks downward (upper gravity)');

    // 觸發棋盤更新回調
    batchProcessor.notifyBoardChanged();
    debugPrint(
        '[DragonRoar] Execution complete - cleared $totalClearedBlocks blocks from 3 rows with upper block gravity effect');

    return RuneCastResult.success;
  }

  /// 執行 Gravity Reset
  RuneCastResult _executeGravityReset(List<List<Color?>> board) {
    batchProcessor.addOperation(CompressBoardOperation(isSpellRemoval: true));
    return RuneCastResult.success;
  }

  /// 執行 Time Slow
  RuneCastResult _executeTimeSlow() {
    // 時間系效果的具體實現由外部處理
    RuneEventBus.emitEffectStart(RuneType.timeSlow);
    return RuneCastResult.success;
  }

  /// 執行 Time Stop
  RuneCastResult _executeTimeStop() {
    // 時間系效果的具體實現由外部處理
    RuneEventBus.emitEffectStart(RuneType.timeStop);
    return RuneCastResult.success;
  }

  /// 執行 Time Change
  RuneCastResult _executeTimeChange() {
    // 時間系效果的具體實現由外部處理
    RuneEventBus.emitEffectStart(RuneType.timeChange);
    return RuneCastResult.success;
  }

  /// 執行 Blessed Combo
  RuneCastResult _executeBlessedCombo() {
    // 時間系效果的具體實現由外部處理
    RuneEventBus.emitEffectStart(RuneType.blessedCombo);
    return RuneCastResult.success;
  }

  /// 執行 Titan Gravity - 分段壓實可視區域
  /// 逐列應用 Column Gravity，並在每列之間增加視覺延遲
  RuneCastResult _executeTitanGravity(
      List<List<Color?>> board, dynamic gameContext) {
    final boardHeight = board.length;
    final boardWidth = board[0].length;

    debugPrint('[TitanGravity] boardH=$boardHeight, boardW=$boardWidth');

    // 確定可視區域範圍（底部20行）
    final startRow = math.max(0, boardHeight - 20);
    debugPrint(
        '[TitanGravity] Processing visible area: rows $startRow to ${boardHeight - 1}');

    int totalMovedBlocks = 0;

    // 分段壓實：逐列處理
    for (int col = 0; col < boardWidth; col++) {
      // 收集該列在可視區域的所有非空方塊
      final columnBlocks = <Color?>[];

      for (int row = boardHeight - 1; row >= startRow; row--) {
        if (board[row][col] != null) {
          columnBlocks.add(board[row][col]);
        }
      }

      // 如果該列沒有方塊，跳過
      if (columnBlocks.isEmpty) {
        debugPrint('[TitanGravity] Column $col: no blocks to compress');
        continue;
      }

      // 清空該列的可視區域
      for (int row = startRow; row < boardHeight; row++) {
        board[row][col] = null;
      }

      // 將方塊從底部開始填回（壓實效果）
      for (int i = 0; i < columnBlocks.length; i++) {
        board[boardHeight - 1 - i][col] = columnBlocks[i];
        totalMovedBlocks++;
      }

      debugPrint(
          '[TitanGravity] Column $col: compressed ${columnBlocks.length} blocks');

      // 每處理完一列就觸發 UI 更新，創造分段視覺效果
      batchProcessor.notifyBoardChanged();

      // TODO: 在實際游戲中可以加入短暫延遲來增強視覺效果
      // await Future.delayed(Duration(milliseconds: 50));
    }

    debugPrint(
        '[TitanGravity] Execution complete - processed $boardWidth columns, moved $totalMovedBlocks blocks');

    return RuneCastResult.success;
  }

  /// 選擇高密度行（Thunder Strike 用）
  int _selectHighDensityRow(List<List<Color?>> board) {
    int bestRow = 0;
    int maxDensity = 0;

    for (int row = 0; row < board.length; row++) {
      int density = board[row].where((cell) => cell != null).length;
      if (density > maxDensity) {
        maxDensity = density;
        bestRow = row;
      }
    }

    return bestRow;
  }

  /// 激活時間系效果
  void _activateTemporalEffect(RuneType runeType, int durationMs) {
    _deactivateTemporalEffect(); // 先終止現有效果

    _activeTemporalRune = runeType;
    _temporalEffectTimer = Timer(Duration(milliseconds: durationMs), () {
      _deactivateTemporalEffect();
    });
  }

  /// 停用時間系效果
  void _deactivateTemporalEffect() {
    if (_activeTemporalRune != null) {
      RuneEventBus.emitEffectEnd(_activeTemporalRune!);
      _activeTemporalRune = null;
    }

    _temporalEffectTimer?.cancel();
    _temporalEffectTimer = null;

    _updateTemporalMutex();
  }

  /// 更新時間系互斥狀態
  void _updateTemporalMutex() {
    for (final slot in slots) {
      if (slot.runeType != null) {
        final definition = RuneConstants.getDefinition(slot.runeType!);
        if (definition.isTemporal) {
          final shouldDisable = _activeTemporalRune != null &&
              _activeTemporalRune != slot.runeType;
          slot.setDisabled(shouldDisable);
        }
      }
    }
  }

  /// 重新載入配置
  void reloadLoadout() {
    _initializeSlots();
  }

  /// 清理資源
  void dispose() {
    _eventSubscription?.cancel();
    _temporalEffectTimer?.cancel();
    batchProcessor.clear();
  }

  /// 獲取系統狀態摘要
  Map<String, dynamic> getStatus() {
    return {
      'slots': slots
          .map((slot) => {
                'runeType': slot.runeType?.name,
                'state': slot.state.name,
                'cooldownRemaining': slot.cooldownRemaining,
                'effectRemaining': slot.effectRemaining,
              })
          .toList(),
      'activeTemporalRune': _activeTemporalRune?.name,
      'lastCastTime': _lastCastTime,
      'pendingOperations': batchProcessor.pendingOperationCount,
    };
  }

  // =============================================================================
  // 🐉 DRAGON ROAR 輔助方法 - 批處理模式（簡化版）
  // =============================================================================

  /// 計算方塊中心行
  int _calculateSmartCenterRow(Tetromino tetromino, List<List<Color?>> board) {
    final positions = tetromino.getAbsolutePositions();
    if (positions.isEmpty) return board.length ~/ 2;

    final centerRow =
        positions.map((p) => p.dy.round()).reduce((a, b) => a + b) ~/
            positions.length;
    return centerRow.clamp(1, board.length - 2);
  }

  /// 選擇目標行：中心±1行
  List<int> _selectOptimalTargetRows(int centerRow, List<List<Color?>> board) {
    final targets = <int>[];

    for (int offset = -1; offset <= 1; offset++) {
      final row = centerRow + offset;
      if (row >= 0 && row < board.length) {
        targets.add(row);
      }
    }

    return targets;
  }
}
