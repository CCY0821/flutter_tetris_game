import 'dart:math';
import 'package:flutter/foundation.dart';

/// 惡魔方塊觸發管理器
/// 負責管理惡魔方塊的觸發時機與頻率控制
/// 使用加速式難度曲線（n^1.2），最多觸發 15 次
class DemonSpawnManager {
  /// 最大觸發次數（防止後期過度頻繁）
  static const int maxSpawns = 15;

  /// 指數基數（用於計算觸發門檻）
  static const double exponent = 1.2;

  /// 基礎分數門檻（第一次觸發）
  static const int baseThreshold = 10000;

  /// 當前遊戲中已觸發次數（1-based）
  int _spawnCount = 0;

  /// 上次觸發時的分數（防止重複觸發）
  int _lastScore = 0;

  /// 計算下一個觸發門檻
  /// 公式：baseThreshold × (n^exponent)
  /// 其中 n = _spawnCount + 1（下一次的序號）
  ///
  /// 範例：
  /// - n=1: 10,000
  /// - n=2: 23,097
  /// - n=3: 39,189
  /// - n=15: 411,101
  int getNextThreshold() {
    if (_spawnCount >= maxSpawns) {
      return -1; // 已達上限，返回無效值（永遠不會觸發）
    }

    final n = _spawnCount + 1; // 下一次的序號（1-based）
    final threshold = (baseThreshold * pow(n, exponent)).round();

    return threshold;
  }

  /// 檢查是否應該生成惡魔方塊
  ///
  /// 觸發條件：
  /// 1. 尚未達到最大次數（< 15）
  /// 2. 當前分數 >= 下一個門檻
  /// 3. 當前分數 > 上次觸發的分數（防止重複觸發）
  ///
  /// [currentScore] 當前遊戲分數
  /// 返回 true 表示應該生成惡魔方塊
  bool shouldSpawn(int currentScore) {
    // 已達最大次數
    if (_spawnCount >= maxSpawns) {
      return false;
    }

    final threshold = getNextThreshold();

    // 🐛 詳細調試日誌
    debugPrint(
        '[DemonSpawnManager] Check spawn: score=$currentScore, threshold=$threshold, lastScore=$_lastScore, spawnCount=$_spawnCount');

    // 達到門檻且分數有增長（防止同一分數重複觸發）
    if (currentScore >= threshold && currentScore > _lastScore) {
      _lastScore = currentScore;
      _spawnCount++;

      debugPrint(
          '[DemonSpawnManager] ✅ Spawn #$_spawnCount triggered at score $currentScore (threshold: $threshold)');
      debugPrint(
          '[DemonSpawnManager] Next threshold: ${_spawnCount < maxSpawns ? getNextThreshold() : "MAX_REACHED"}');

      return true;
    }

    return false;
  }

  /// 重置計數器（遊戲重新開始時調用）
  void reset() {
    debugPrint(
        '[DemonSpawnManager] Reset (previous spawn count: $_spawnCount)');
    _spawnCount = 0;
    _lastScore = 0;
  }

  /// 獲取當前已觸發次數
  int get spawnCount => _spawnCount;

  /// 獲取剩餘可觸發次數
  int get remainingSpawns => maxSpawns - _spawnCount;

  /// 檢查是否已達最大次數
  bool get hasReachedMax => _spawnCount >= maxSpawns;

  /// 獲取當前狀態描述（用於調試）
  String get statusDescription {
    if (_spawnCount >= maxSpawns) {
      return 'DemonSpawnManager: MAX_REACHED ($maxSpawns/$maxSpawns)';
    }

    return 'DemonSpawnManager: $_spawnCount/$maxSpawns spawned, next threshold: ${getNextThreshold()}';
  }

  /// 獲取完整的觸發門檻表（用於調試和顯示）
  static List<int> getThresholdTable() {
    final thresholds = <int>[];
    for (int n = 1; n <= maxSpawns; n++) {
      final threshold = (baseThreshold * pow(n, exponent)).round();
      thresholds.add(threshold);
    }
    return thresholds;
  }

  /// 估算給定分數對應的關卡（假設每行 100 分）
  static int estimateLevel(int score) {
    return (score / 1000).round();
  }

  /// 獲取帶關卡估算的觸發門檻表（用於顯示）
  static Map<int, Map<String, dynamic>> getDetailedThresholdTable() {
    final table = <int, Map<String, dynamic>>{};
    for (int n = 1; n <= maxSpawns; n++) {
      final threshold = (baseThreshold * pow(n, exponent)).round();
      final estimatedLevel = estimateLevel(threshold);

      table[n] = {
        'threshold': threshold,
        'estimatedLevel': estimatedLevel,
      };
    }
    return table;
  }

  /// 獲取狀態（用於持久化/保存遊戲）
  Map<String, dynamic> getState() {
    return {
      'spawnCount': _spawnCount,
      'lastScore': _lastScore,
    };
  }

  /// 從狀態恢復（用於持久化/載入遊戲）
  void restoreState(Map<String, dynamic> state) {
    _spawnCount = state['spawnCount'] as int? ?? 0;
    _lastScore = state['lastScore'] as int? ?? 0;

    debugPrint(
        '[DemonSpawnManager] Restored state: $_spawnCount spawns, last score: $_lastScore');
  }

  /// 強制觸發惡魔方塊（用於測試或特殊事件）
  /// ⚠️ 警告：會增加計數器，慎用
  void forceSpawn() {
    if (_spawnCount >= maxSpawns) {
      debugPrint('[DemonSpawnManager] Cannot force spawn: max spawns reached');
      return;
    }

    _spawnCount++;
    debugPrint('[DemonSpawnManager] Force spawned demon block #$_spawnCount');
  }

  /// 打印觸發門檻表（用於調試）
  static void printThresholdTable() {
    debugPrint('=== Demon Block Spawn Thresholds ===');
    final table = getDetailedThresholdTable();

    for (final entry in table.entries) {
      final n = entry.key;
      final threshold = entry.value['threshold'];
      final level = entry.value['estimatedLevel'];

      debugPrint('Spawn #$n: $threshold points (≈ Level $level)');
    }
    debugPrint('====================================');
  }
}
