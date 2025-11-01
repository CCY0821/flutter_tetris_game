/// Marathon 模式速度曲線系統
/// 基於 Tetris.wiki 的標準 Marathon 模式規格
class MarathonSystem {
  // 基本設定
  static const int maxLevel = 999;
  static const int maxSpeedLevel = 500; // LV500 達到最高速
  static const int linesPerLevel = 10;

  // 速度曲線參數
  static const double baseGravity = 0.01667; // 1G = 1/60 秒 = 16.67ms
  static const double maxGravity = 20.0; // 20G
  static const double _gravitySlope = 19.0 / 499; // 線性增長係數

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
  /// 使用線性增長速度曲線 (LV1-500)
  double getCurrentGravity() {
    if (_gravityCache.containsKey(_currentLevel)) {
      return _gravityCache[_currentLevel]!;
    }

    double gravity;

    if (_currentLevel <= maxSpeedLevel) {
      // LV1-500: 線性增長從 1.0G 到 20.0G
      gravity = 1.0 + (_currentLevel - 1) * _gravitySlope;
    } else {
      // LV501+: 維持最高速 20G
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
      return '00$_currentLevel';
    } else if (_currentLevel <= 99) {
      return '0$_currentLevel';
    }
    return _currentLevel.toString();
  }

  /// 獲取速度等級描述
  String getSpeedDescription() {
    double gravity = getCurrentGravity();

    if (gravity < 5.0) {
      return '中速';
    } else if (gravity < 10.0) {
      return '快速';
    } else if (gravity < 15.0) {
      return '極速';
    } else if (gravity < 20.0) {
      return '超速';
    } else {
      return '光速';
    }
  }

  /// 計算特定關卡的重力值（用於預覽）
  double calculateGravityForLevel(int level) {
    if (level <= maxSpeedLevel) {
      // LV1-500: 線性增長從 1.0G 到 20.0G
      return 1.0 + (level - 1) * _gravitySlope;
    } else {
      // LV501+: 維持最高速 20G
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
