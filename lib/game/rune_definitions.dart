import 'package:flutter/material.dart';
import 'rune_events.dart';

/// 符文分類（用於時間系互斥檢查）
enum RuneCategory {
  /// 瞬發效果類
  instant,

  /// 時間系效果類（互斥）
  temporal,
}

/// 符文定義類
/// 包含符文的所有靜態屬性和規則
class RuneDefinition {
  /// 符文類型
  final RuneType type;

  /// 符文名稱
  final String name;

  /// 符文圖標
  final IconData icon;

  /// 符文描述
  final String description;

  /// 能量成本（格數）
  final int energyCost;

  /// 冷卻時間（秒）
  final int cooldownSeconds;

  /// 持續時間（秒，0表示瞬發）
  final int durationSeconds;

  /// 符文分類
  final RuneCategory category;

  /// 顏色主題（用於UI）
  final Color themeColor;

  const RuneDefinition({
    required this.type,
    required this.name,
    required this.icon,
    required this.description,
    required this.energyCost,
    required this.cooldownSeconds,
    required this.durationSeconds,
    required this.category,
    required this.themeColor,
  });

  /// 是否為時間系符文
  bool get isTemporal => category == RuneCategory.temporal;

  /// 是否為瞬發符文
  bool get isInstant => durationSeconds == 0;

  /// 冷卻時間（毫秒）
  int get cooldownMs => cooldownSeconds * 1000;

  /// 持續時間（毫秒）
  int get durationMs => durationSeconds * 1000;

  @override
  String toString() {
    return 'RuneDefinition($name, cost: $energyCost, cd: ${cooldownSeconds}s'
        '${durationSeconds > 0 ? ', dur: ${durationSeconds}s' : ''})';
  }
}

/// 符文常量定義
/// 包含所有10種符文的完整定義
class RuneConstants {
  static const Map<RuneType, RuneDefinition> definitions = {
    RuneType.flameBurst: RuneDefinition(
      type: RuneType.flameBurst,
      name: "Flame Burst",
      icon: Icons.local_fire_department,
      description: "立即清除當前方塊所在列",
      energyCost: 1,
      cooldownSeconds: 6,
      durationSeconds: 0,
      category: RuneCategory.instant,
      themeColor: Colors.deepOrange,
    ),
    RuneType.thunderStrike: RuneDefinition(
      type: RuneType.thunderStrike,
      name: "Thunder Strike",
      icon: Icons.flash_on,
      description: "清除棋盤最右側兩列",
      energyCost: 2,
      cooldownSeconds: 8,
      durationSeconds: 0,
      category: RuneCategory.instant,
      themeColor: Colors.yellow,
    ),
    RuneType.earthquake: RuneDefinition(
      type: RuneType.earthquake,
      name: "Earthquake",
      icon: Icons.terrain,
      description: "整個盤面下移1行，底行消失",
      energyCost: 1,
      cooldownSeconds: 10,
      durationSeconds: 0,
      category: RuneCategory.instant,
      themeColor: Colors.brown,
    ),
    RuneType.timeSlow: RuneDefinition(
      type: RuneType.timeSlow,
      name: "Time Slow",
      icon: Icons.slow_motion_video,
      description: "5秒內下落速度減半",
      energyCost: 1,
      cooldownSeconds: 12,
      durationSeconds: 5,
      category: RuneCategory.temporal,
      themeColor: Colors.cyan,
    ),
    RuneType.angelsGrace: RuneDefinition(
      type: RuneType.angelsGrace,
      name: "Angel's Grace",
      icon: Icons.flight,
      description: "刪除最頂端2行方塊",
      energyCost: 2,
      cooldownSeconds: 18,
      durationSeconds: 0,
      category: RuneCategory.instant,
      themeColor: Colors.white,
    ),
    RuneType.timeStop: RuneDefinition(
      type: RuneType.timeStop,
      name: "Time Stop",
      icon: Icons.pause_circle,
      description: "3秒完全暫停，可移動旋轉",
      energyCost: 2,
      cooldownSeconds: 18,
      durationSeconds: 3,
      category: RuneCategory.temporal,
      themeColor: Colors.purple,
    ),
    RuneType.blessedCombo: RuneDefinition(
      type: RuneType.blessedCombo,
      name: "Blessed Combo",
      icon: Icons.star,
      description: "10秒內自然消除分數翻倍",
      energyCost: 2,
      cooldownSeconds: 20,
      durationSeconds: 10,
      category: RuneCategory.temporal,
      themeColor: Colors.amber,
    ),
    RuneType.columnBreaker: RuneDefinition(
      type: RuneType.columnBreaker,
      name: "Column Breaker",
      icon: Icons.view_column,
      description: "清除當前方塊影子所覆蓋的整條縱列",
      energyCost: 3,
      cooldownSeconds: 8,
      durationSeconds: 0,
      category: RuneCategory.instant,
      themeColor: Colors.orange,
    ),
    RuneType.dragonRoar: RuneDefinition(
      type: RuneType.dragonRoar,
      name: "Dragon Roar",
      icon: Icons.whatshot,
      description: "清除當前列及上下各一行",
      energyCost: 3,
      cooldownSeconds: 15,
      durationSeconds: 0,
      category: RuneCategory.instant,
      themeColor: Colors.red,
    ),
    RuneType.gravityReset: RuneDefinition(
      type: RuneType.gravityReset,
      name: "Gravity Reset",
      icon: Icons.vertical_align_bottom,
      description: "整個棋盤壓縮到底部，消除所有空洞",
      energyCost: 3,
      cooldownSeconds: 25,
      durationSeconds: 0,
      category: RuneCategory.instant,
      themeColor: Colors.indigo,
    ),
    RuneType.titanGravity: RuneDefinition(
      type: RuneType.titanGravity,
      name: "Titan Gravity",
      icon: Icons.landscape,
      description: "分段壓實可視區域，消除縱向空洞",
      energyCost: 2,
      cooldownSeconds: 45,
      durationSeconds: 0,
      category: RuneCategory.instant,
      themeColor: Colors.blueGrey,
    ),
  };

  /// 獲取符文定義
  static RuneDefinition getDefinition(RuneType type) {
    return definitions[type]!;
  }

  /// 獲取所有符文類型
  static List<RuneType> get allTypes => RuneType.values;

  /// 獲取所有時間系符文類型
  static List<RuneType> get temporalTypes =>
      allTypes.where((type) => definitions[type]!.isTemporal).toList();

  /// 獲取所有瞬發符文類型
  static List<RuneType> get instantTypes =>
      allTypes.where((type) => !definitions[type]!.isTemporal).toList();

  /// 檢查兩個符文是否互斥
  static bool areRulesMutuallyExclusive(RuneType type1, RuneType type2) {
    final def1 = definitions[type1]!;
    final def2 = definitions[type2]!;
    return def1.isTemporal && def2.isTemporal;
  }

  /// 獲取指定能量成本的符文
  static List<RuneType> getRunesByEnergyCost(int cost) {
    return allTypes
        .where((type) => definitions[type]!.energyCost == cost)
        .toList();
  }

  /// 獲取3格能量符文（用於配置限制檢查）
  static List<RuneType> get threeEnergyRunes => getRunesByEnergyCost(3);
}

/// 符文平衡參數（支持±20%微調）
class RuneBalance {
  /// 微調因子（0.8 ~ 1.2）
  static double tuningFactor = 1.0;

  /// 獲取調整後的冷卻時間
  static int getAdjustedCooldown(RuneType type) {
    final base = RuneConstants.getDefinition(type).cooldownSeconds;
    return (base * tuningFactor).round().clamp(1, 999);
  }

  /// 獲取調整後的持續時間
  static int getAdjustedDuration(RuneType type) {
    final base = RuneConstants.getDefinition(type).durationSeconds;
    return (base * tuningFactor).round().clamp(0, 999);
  }

  /// 設置微調因子
  static void setTuningFactor(double factor) {
    tuningFactor = factor.clamp(0.8, 1.2);
  }

  /// 重置為默認值
  static void reset() {
    tuningFactor = 1.0;
  }
}
