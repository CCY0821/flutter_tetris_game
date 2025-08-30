import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'monotonic_timer.dart';
import 'rune_events.dart';
import 'rune_definitions.dart';
import 'rune_loadout.dart';
import 'rune_batch_processor.dart';
import 'rune_energy_manager.dart';

/// 符文施法錯誤類型
enum RuneCastError {
  success,
  energyInsufficient, // 能量不足
  cooldownActive, // 冷卻中
  temporalMutualExclusive, // 時間系互斥
  frameThrottled, // 單幀節流
  slotEmpty, // 槽位為空
  ghostInvalid, // 影子無效（Column Breaker專用）
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
  int get cooldownRemaining =>
      math.max(0, cooldownEndTime - MonotonicTimer.now);

  /// 獲取效果剩餘時間（毫秒）
  int get effectRemaining => math.max(0, effectEndTime - MonotonicTimer.now);

  /// 獲取冷卻進度 (0.0 - 1.0)
  double get cooldownProgress {
    if (!isCooling || cooldownEndTime <= cooldownStartTime) return 1.0;
    final elapsed = MonotonicTimer.now - cooldownStartTime;
    final total = cooldownEndTime - cooldownStartTime;
    return (elapsed / total).clamp(0.0, 1.0);
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

    // 檢查冷卻是否結束
    if (cooldownEndTime > 0 && now >= cooldownEndTime) {
      cooldownEndTime = 0;
      cooldownStartTime = 0;
    }

    // 更新狀態
    if (effectEndTime > now) {
      state = RuneSlotState.active;
    } else if (cooldownEndTime > now) {
      state = RuneSlotState.cooling;
    } else {
      state = RuneSlotState.ready;
    }
  }

  /// 開始冷卻
  void startCooldown(int durationMs) {
    final now = MonotonicTimer.now;
    cooldownStartTime = now;
    cooldownEndTime = now + durationMs;
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
        return executeResult;
      }

      // 消耗能量
      if (_energyManager != null) {
        _energyManager!.consumeBars(definition.energyCost);
      }

      // 開始冷卻
      slot.startCooldown(
          RuneBalance.getAdjustedCooldown(slot.runeType!) * 1000);

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
          return _executeThunderStrike(board);
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
        case RuneType.timeSlow:
          return _executeTimeSlow();
        case RuneType.timeStop:
          return _executeTimeStop();
        case RuneType.blessedCombo:
          return _executeBlessedCombo();
      }
    } catch (e) {
      debugPrint('RuneSystem: Execute error - $e');
      return RuneCastResult.failure(RuneCastError.systemError, '效果執行失敗: $e');
    }
  }

  /// 執行 Flame Burst
  RuneCastResult _executeFlameBurst(
      List<List<Color?>> board, dynamic gameContext) {
    if (gameContext?.currentTetromino == null) {
      return RuneCastResult.failure(RuneCastError.systemError, '無當前方塊');
    }

    final currentY = gameContext.currentTetromino.y;
    if (currentY < 0 || currentY >= board.length) {
      return RuneCastResult.failure(RuneCastError.systemError, '方塊位置無效');
    }

    batchProcessor
        .addOperation(ClearRowOperation(currentY, isSpellRemoval: true));
    return RuneCastResult.success;
  }

  /// 執行 Thunder Strike
  RuneCastResult _executeThunderStrike(List<List<Color?>> board) {
    // 檢查是否為空盤
    bool isEmpty = true;
    for (final row in board) {
      for (final cell in row) {
        if (cell != null) {
          isEmpty = false;
          break;
        }
      }
      if (!isEmpty) break;
    }

    if (isEmpty) {
      // 空盤退還能量
      _energyManager?.refundEnergy(1);
      return RuneCastResult.refund('盤面全空，退還能量');
    }

    // 選擇高密度行進行清除
    final targetRow = _selectHighDensityRow(board);
    batchProcessor
        .addOperation(ClearRowOperation(targetRow, isSpellRemoval: true));
    return RuneCastResult.success;
  }

  /// 執行 Earthquake
  RuneCastResult _executeEarthquake(List<List<Color?>> board) {
    batchProcessor.addOperation(ShiftBoardDownOperation(isSpellRemoval: true));
    return RuneCastResult.success;
  }

  /// 執行 Angel's Grace
  RuneCastResult _executeAngelsGrace(List<List<Color?>> board) {
    batchProcessor
        .addOperation(RemoveTopRowsOperation(2, isSpellRemoval: true));
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

  /// 執行 Dragon Roar
  RuneCastResult _executeDragonRoar(
      List<List<Color?>> board, dynamic gameContext) {
    final currentY = gameContext.currentTetromino?.y ?? 0;

    // 清除當前行和上下各一行
    for (int offset = -1; offset <= 1; offset++) {
      final targetRow = currentY + offset;
      if (targetRow >= 0 && targetRow < board.length) {
        batchProcessor
            .addOperation(ClearRowOperation(targetRow, isSpellRemoval: true));
      }
    }

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

  /// 執行 Blessed Combo
  RuneCastResult _executeBlessedCombo() {
    // 時間系效果的具體實現由外部處理
    RuneEventBus.emitEffectStart(RuneType.blessedCombo);
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
}
