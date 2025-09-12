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
      description: "精確選擇最有價值的目標清除，上方方塊結構整體下沉",
      energyCost: 1,
      cooldownSeconds: 6,
      durationSeconds: 0,
      category: RuneCategory.instant,
      themeColor: Colors.deepOrange,
    ),
    RuneType.thunderStrike: RuneDefinition(
      type: RuneType.thunderStrike,
      name: "Thunder Strike Right",
      icon: Icons.flash_on,
      description: "清理棋盤最右側行",
      energyCost: 2,
      cooldownSeconds: 8,
      durationSeconds: 0,
      category: RuneCategory.instant,
      themeColor: Colors.yellow,
    ),
    RuneType.thunderStrikeLeft: RuneDefinition(
      type: RuneType.thunderStrikeLeft,
      name: "Thunder Strike Left",
      icon: Icons.flash_off,
      description: "清理棋盤最左側行",
      energyCost: 2,
      cooldownSeconds: 8,
      durationSeconds: 0,
      category: RuneCategory.instant,
      themeColor: Colors.yellowAccent,
    ),
    RuneType.angelsGrace: RuneDefinition(
      type: RuneType.angelsGrace,
      name: "Angel's Grace",
      icon: Icons.flight,
      description: "全部方塊清空",
      energyCost: 3,
      cooldownSeconds: 60,
      durationSeconds: 0,
      category: RuneCategory.instant,
      themeColor: Colors.white,
    ),
    RuneType.timeChange: RuneDefinition(
      type: RuneType.timeChange,
      name: "Time Change",
      icon: Icons.slow_motion_video,
      description: "下落速度 ×0.5，10秒後恢復原本速度",
      energyCost: 2,
      cooldownSeconds: 18,
      durationSeconds: 10,
      category: RuneCategory.temporal,
      themeColor: Colors.deepPurple,
    ),
    RuneType.blessedCombo: RuneDefinition(
      type: RuneType.blessedCombo,
      name: "Blessed Combo",
      icon: Icons.star,
      description: "10秒內自然消行分數 ×3",
      energyCost: 2,
      cooldownSeconds: 20,
      durationSeconds: 10,
      category: RuneCategory.temporal,
      themeColor: Colors.amber,
    ),
    RuneType.dragonRoar: RuneDefinition(
      type: RuneType.dragonRoar,
      name: "Dragon Roar",
      icon: Icons.whatshot,
      description: "清除最下方三列，上方方塊結構整體下沉",
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
      description: "接下來五個方塊變成I",
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
      description: "使用泰坦引力消除縱向空洞，分段壓實方塊",
      energyCost: 2,
      cooldownSeconds: 45,
      durationSeconds: 0,
      category: RuneCategory.instant,
      themeColor: Colors.blueGrey,
    ),
    RuneType.elementMorph: RuneDefinition(
      type: RuneType.elementMorph,
      name: "Element Morph",
      icon: Icons.transform,
      description: "當前方塊隨機變形",
      energyCost: 1,
      cooldownSeconds: 3,
      durationSeconds: 0,
      category: RuneCategory.instant,
      themeColor: Colors.teal,
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
