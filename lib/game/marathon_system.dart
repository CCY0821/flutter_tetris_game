import 'dart:math' as math;

/// Marathon 模式速度曲線系統
/// 基於 Tetris.wiki 的標準 Marathon 模式規格
class MarathonSystem {
  // 基本設定
  static const int maxLevel = 30;
  static const int linesPerLevel = 10;

  // 速度曲線參數
  static const double baseGravity = 0.01667; // 1G = 1/60 秒 = 16.67ms
  static const double maxGravity = 20.0; // 20G

  int _currentLevel = 1;
  int _totalLinesCleared = 0;
  int _linesInCurrentLevel = 0;

  // 速度計算緩存
  final Map<int, double> _gravityCache = {};
  final Map<int, int> _dropTimeCache = {};

  /// 當前關卡
  int get currentLevel => _currentLevel;

  /// 總消除行數
  int get totalLinesCleared => _totalLinesCleared;

  /// 當前關卡已消除行數
  int get linesInCurrentLevel => _linesInCurrentLevel;

  /// 到下一關卡還需消除的行數
  int get linesToNextLevel => linesPerLevel - _linesInCurrentLevel;

  /// 當前關卡進度 (0.0 - 1.0)
  double get levelProgress => _linesInCurrentLevel / linesPerLevel;

  /// 是否已達到最高關卡
  bool get isMaxLevel => _currentLevel >= maxLevel;

  /// 重置 Marathon 系統
  void reset() {
    _currentLevel = 1;
    _totalLinesCleared = 0;
    _linesInCurrentLevel = 0;
    _gravityCache.clear();
    _dropTimeCache.clear();
  }

  /// 更新消除行數，返回是否升級
  bool updateLinesCleared(int lines) {
    if (lines <= 0) return false;

    _totalLinesCleared += lines;
    _linesInCurrentLevel += lines;

    // 檢查是否需要升級
    bool leveledUp = false;
    while (_linesInCurrentLevel >= linesPerLevel && !isMaxLevel) {
      _linesInCurrentLevel -= linesPerLevel;
      _currentLevel++;
      leveledUp = true;
    }

    // 如果已達最高關卡，清空當前關卡進度
    if (isMaxLevel) {
      _linesInCurrentLevel = 0;
    }

    return leveledUp;
  }

  /// 獲取當前關卡的重力值 (G)
  /// 使用遊戲體驗優化的速度曲線
  double getCurrentGravity() {
    if (_gravityCache.containsKey(_currentLevel)) {
      return _gravityCache[_currentLevel]!;
    }

    double gravity;

    if (_currentLevel <= 8) {
      // 1-8級：漸進式加速，從1G開始
      gravity = 1.0 + (_currentLevel - 1) * 0.3;
    } else if (_currentLevel <= 15) {
      // 9-15級：中速加速
      gravity = 3.0 + (_currentLevel - 8) * 0.5;
    } else if (_currentLevel <= 18) {
      // 16-18級：快速加速
      gravity = 6.5 + (_currentLevel - 15) * 1.0;
    } else if (_currentLevel == 19) {
      // 19級：接近最大速度
      gravity = 15.0;
    } else {
      // 20級以後達到20G
      gravity = maxGravity;
    }

    // 緩存結果
    _gravityCache[_currentLevel] = gravity;
    return gravity;
  }

  /// 獲取當前的掉落時間間隔（毫秒）
  int getDropInterval() {
    if (_dropTimeCache.containsKey(_currentLevel)) {
      return _dropTimeCache[_currentLevel]!;
    }

    double gravity = getCurrentGravity();

    // 1G = 1000ms, 2G = 500ms, 20G = 50ms
    int interval = (1000 / gravity).round();

    // 設定最小間隔，防止過快
    if (interval < 16) interval = 16; // 約60fps

    _dropTimeCache[_currentLevel] = interval;
    return interval;
  }

  /// 獲取關卡顯示名稱
  String getLevelDisplayName() {
    if (_currentLevel <= 9) {
      return '0$_currentLevel';
    }
    return _currentLevel.toString();
  }

  /// 獲取速度等級描述
  String getSpeedDescription() {
    double gravity = getCurrentGravity();

    if (gravity < 0.1) {
      return '慢速';
    } else if (gravity < 1.0) {
      return '中速';
    } else if (gravity < 5.0) {
      return '快速';
    } else if (gravity < 15.0) {
      return '極速';
    } else {
      return '光速';
    }
  }

  /// 計算特定關卡的重力值（用於預覽）
  double calculateGravityForLevel(int level) {
    if (level <= 8) {
      // 1-8級：漸進式加速，從1G開始
      return 1.0 + (level - 1) * 0.3;
    } else if (level <= 15) {
      // 9-15級：中速加速
      return 3.0 + (level - 8) * 0.5;
    } else if (level <= 18) {
      // 16-18級：快速加速
      return 6.5 + (level - 15) * 1.0;
    } else if (level == 19) {
      // 19級：接近最大速度
      return 15.0;
    } else {
      // 20級以後達到20G
      return maxGravity;
    }
  }

  /// 獲取關卡統計資訊
  MarathonStats getStats() {
    return MarathonStats(
      level: _currentLevel,
      totalLines: _totalLinesCleared,
      linesInLevel: _linesInCurrentLevel,
      gravity: getCurrentGravity(),
      dropInterval: getDropInterval(),
      progress: levelProgress,
    );
  }

  /// 設定關卡（用於測試或載入存檔）
  void setLevel(int level, {int totalLines = 0}) {
    if (level < 1) level = 1;
    if (level > maxLevel) level = maxLevel;

    _currentLevel = level;
    _totalLinesCleared = totalLines;
    _linesInCurrentLevel = totalLines % linesPerLevel;

    // 清除緩存以重新計算
    _gravityCache.clear();
    _dropTimeCache.clear();
  }

  /// 直接設定當前關卡的行數進度（用於載入存檔）
  void setLinesInCurrentLevel(int lines) {
    if (lines < 0) lines = 0;
    if (lines >= linesPerLevel && !isMaxLevel) lines = linesPerLevel - 1;
    _linesInCurrentLevel = lines;
  }
}

/// Marathon 統計資訊
class MarathonStats {
  final int level;
  final int totalLines;
  final int linesInLevel;
  final double gravity;
  final int dropInterval;
  final double progress;

  const MarathonStats({
    required this.level,
    required this.totalLines,
    required this.linesInLevel,
    required this.gravity,
    required this.dropInterval,
    required this.progress,
  });

  @override
  String toString() {
    return 'Level $level | Lines: $totalLines | Gravity: ${gravity.toStringAsFixed(2)}G | Interval: ${dropInterval}ms';
  }
}
