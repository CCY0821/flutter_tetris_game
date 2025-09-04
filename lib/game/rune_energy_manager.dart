import 'package:flutter/foundation.dart';

/// 基础符文能量管理器
///
/// 能量规则：
/// - 自然消除 1 行 = +50 分
/// - 100 分 = 1 格能量
/// - 最多 3 格能量
/// - 可保留溢出进度 (例: 130分 = 1格 + 下一格30%)
/// - 法术造成的清除不可调用 addScore
class RuneEnergyManager {
  static const int maxEnergy = 3; // 最大 3 格能量
  static const int scorePerEnergyBar = 100; // 每 100 分产生 1 格能量

  int _currentScore = 0; // 累积的能量分数
  int _currentBars = 0; // 当前完整能量格数 (0-3)

  // 事件回调
  VoidCallback? _onEnergyChanged;
  VoidCallback? _onEnergyFull;

  /// 设置能量变化回调
  void setOnEnergyChanged(VoidCallback callback) {
    _onEnergyChanged = callback;
  }

  /// 设置能量满格回调
  void setOnEnergyFull(VoidCallback callback) {
    _onEnergyFull = callback;
  }

  /// 当前完整能量格数 (0-3)
  int get currentBars => _currentBars;

  /// 当前能量总分数
  int get currentScore => _currentScore;

  /// 当前进度百分比 (下一格的进度 0.0-1.0)
  double get currentPartialRatio {
    if (_currentBars >= maxEnergy) return 0.0; // 满格时不显示进度
    int remainingScore = _currentScore % scorePerEnergyBar;
    double ratio = remainingScore / scorePerEnergyBar;
    return ratio.clamp(0.0, 1.0); // 严格限制范围
  }

  /// 是否已达最大能量
  bool get isMaxEnergy => _currentBars >= maxEnergy;

  /// 是否可以消耗指定格数的能量
  bool canConsume(int bars) {
    return bars > 0 && _currentBars >= bars;
  }

  /// 添加分数并转换为能量 (仅限自然消除)
  /// 每消除 1 行 = +50 分，每 100 分 = 1 格能量
  /// 注意: 法术造成的清除不可调用此方法
  void addScore(int linesCleared) {
    if (linesCleared <= 0) return;

    int scoreToAdd = linesCleared * 50;
    int oldBars = _currentBars;

    _currentScore += scoreToAdd;

    // 计算新的能量格数 (最多3格)
    int totalBars = _currentScore ~/ scorePerEnergyBar;
    _currentBars = totalBars.clamp(0, maxEnergy);

    // 触发事件
    if (oldBars != _currentBars) {
      _onEnergyChanged?.call();

      // 首次达到满格时触发特效
      if (oldBars < maxEnergy && _currentBars >= maxEnergy) {
        _onEnergyFull?.call();
      }
    }

    debugPrint('RuneEnergy: Added $scoreToAdd score ($linesCleared lines), '
        'total: $_currentScore, bars: $_currentBars, '
        'progress: ${(currentPartialRatio * 100).toStringAsFixed(1)}%');
  }

  /// 消耗指定格数的能量 (供未来法术使用)
  /// 返回是否成功消耗
  bool consumeBars(int bars) {
    if (!canConsume(bars)) {
      debugPrint(
          'RuneEnergy: Cannot consume $bars bars, only have $_currentBars');
      return false;
    }

    // 消耗能量：减少对应的分数
    _currentScore -= bars * scorePerEnergyBar;

    // 重新计算能量格数
    int totalBars = _currentScore ~/ scorePerEnergyBar;
    _currentBars = totalBars.clamp(0, maxEnergy);

    _onEnergyChanged?.call();

    debugPrint('RuneEnergy: Consumed $bars bars, '
        'remaining: $_currentScore score, $_currentBars bars');
    return true;
  }

  /// 退還能量 (Thunder Strike 空盤時使用)
  /// 直接增加能量格數而不影響分數進度
  void refundEnergy(int bars) {
    if (bars <= 0) return;

    int oldBars = _currentBars;

    // 直接增加分數來恢復能量
    _currentScore += bars * scorePerEnergyBar;

    // 重新計算能量格數 (最多3格)
    int totalBars = _currentScore ~/ scorePerEnergyBar;
    _currentBars = totalBars.clamp(0, maxEnergy);

    // 觸發事件
    if (oldBars != _currentBars) {
      _onEnergyChanged?.call();

      // 如果因退還而達到滿格
      if (oldBars < maxEnergy && _currentBars >= maxEnergy) {
        _onEnergyFull?.call();
      }
    }

    debugPrint('RuneEnergy: Refunded $bars bars, '
        'total: $_currentScore score, $_currentBars bars');
  }

  /// 重置能量系统
  void reset() {
    _currentScore = 0;
    _currentBars = 0;
    _onEnergyChanged?.call();
    debugPrint('RuneEnergy: System reset');
  }

  /// 获取能量状态摘要
  RuneEnergyStatus getStatus() {
    return RuneEnergyStatus(
      currentBars: _currentBars,
      maxBars: maxEnergy,
      currentScore: _currentScore,
      partialRatio: currentPartialRatio,
      isMaxEnergy: isMaxEnergy,
    );
  }

  /// 用于持久化的状态数据
  Map<String, dynamic> toJson() {
    return {
      'currentScore': _currentScore,
      'currentBars': _currentBars,
    };
  }

  /// 从持久化数据恢复状态
  void fromJson(Map<String, dynamic> json) {
    _currentScore = json['currentScore'] as int? ?? 0;
    _currentBars = json['currentBars'] as int? ?? 0;

    // 验证数据有效性
    _currentBars = _currentBars.clamp(0, maxEnergy);
    if (_currentScore < 0) _currentScore = 0;

    _onEnergyChanged?.call();
    debugPrint(
        'RuneEnergy: Restored from save - score: $_currentScore, bars: $_currentBars');
  }

  @override
  String toString() {
    return 'RuneEnergyManager(bars: $_currentBars/$maxEnergy, '
        'score: $_currentScore, progress: ${(currentPartialRatio * 100).toStringAsFixed(1)}%)';
  }
}

/// 能量状态快照
class RuneEnergyStatus {
  final int currentBars;
  final int maxBars;
  final int currentScore;
  final double partialRatio;
  final bool isMaxEnergy;

  const RuneEnergyStatus({
    required this.currentBars,
    required this.maxBars,
    required this.currentScore,
    required this.partialRatio,
    required this.isMaxEnergy,
  });

  @override
  String toString() {
    return 'RuneEnergyStatus(bars: $currentBars/$maxBars, '
        'progress: ${(partialRatio * 100).toStringAsFixed(1)}%)';
  }
}
