import 'dart:async';

/// 符文事件類型枚舉（P0 最小版本）
enum RuneEventType {
  /// 符文施法事件
  cast,

  /// 符文效果開始事件
  effectStart,

  /// 符文效果結束事件
  effectEnd,

  /// 能量變化事件
  energyChanged,
}

/// 符文類型枚舉
enum RuneType {
  flameBurst, // 🔥 Flame Burst (1格/6s)
  dragonRoar, // 🐉 Dragon Roar (3格/15s)
  thunderStrike, // ⚡ Thunder Strike (1格/8s)
  earthquake, // 🌍 Earthquake (1格/10s)
  angelsGrace, // 😇 Angel's Grace (2格/18s)
  timeSlow, // 🕰 Time Slow (1格/12s, 5s持續)
  timeStop, // ⏸ Time Stop (2格/18s, 3s持續)
  columnBreaker, // 🧨 Column Breaker (3格/8s)
  gravityReset, // 💫 Gravity Reset (3格/25s)
  blessedCombo, // ✨ Blessed Combo (2格/20s, 10s持續)
}

/// 符文事件數據
class RuneEvent {
  /// 事件類型
  final RuneEventType type;

  /// 相關符文類型（可選）
  final RuneType? runeType;

  /// 額外數據
  final Map<String, dynamic> data;

  const RuneEvent({
    required this.type,
    this.runeType,
    this.data = const {},
  });

  @override
  String toString() {
    return 'RuneEvent(type: $type, runeType: $runeType, data: $data)';
  }
}

/// 符文事件總線（域內 Bus）
/// P0 版本：簡單的廣播流，綁定到 GameSession 生命週期
class RuneEventBus {
  static StreamController<RuneEvent>? _controller;
  static Stream<RuneEvent>? _stream;

  /// 初始化事件總線
  static void initialize() {
    dispose(); // 確保清理現有資源

    _controller = StreamController<RuneEvent>.broadcast();
    _stream = _controller!.stream;
  }

  /// 獲取事件流
  static Stream<RuneEvent> get events {
    if (_stream == null) {
      throw StateError(
          'RuneEventBus not initialized. Call initialize() first.');
    }
    return _stream!;
  }

  /// 發送事件
  static void emit(RuneEventType type,
      {RuneType? runeType, Map<String, dynamic>? data}) {
    if (_controller == null || _controller!.isClosed) {
      return; // 靜默忽略，避免崩潰
    }

    final event = RuneEvent(
      type: type,
      runeType: runeType,
      data: data ?? {},
    );

    _controller!.add(event);
  }

  /// 快捷方法：發送符文施法事件
  static void emitCast(RuneType runeType, {Map<String, dynamic>? data}) {
    emit(RuneEventType.cast, runeType: runeType, data: data);
  }

  /// 快捷方法：發送效果開始事件
  static void emitEffectStart(RuneType runeType, {Map<String, dynamic>? data}) {
    emit(RuneEventType.effectStart, runeType: runeType, data: data);
  }

  /// 快捷方法：發送效果結束事件
  static void emitEffectEnd(RuneType runeType, {Map<String, dynamic>? data}) {
    emit(RuneEventType.effectEnd, runeType: runeType, data: data);
  }

  /// 快捷方法：發送能量變化事件
  static void emitEnergyChanged(int newValue, int oldValue) {
    emit(RuneEventType.energyChanged, data: {
      'newValue': newValue,
      'oldValue': oldValue,
    });
  }

  /// 清理事件總線
  static void dispose() {
    _controller?.close();
    _controller = null;
    _stream = null;
  }

  /// 檢查是否已初始化
  static bool get isInitialized =>
      _controller != null && !_controller!.isClosed;
}
