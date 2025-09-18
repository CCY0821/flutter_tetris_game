import 'dart:math';
import 'package:flutter/material.dart';
import '../models/tetromino.dart';

/// 分數來源類型
enum ScoreOrigin {
  /// 自然消行（正常遊戲中的消行）
  natural,

  /// 法術消行（符文效果造成的消行）
  spell,
}

/// 分數修改器抽象類（攔截器模式）
abstract class ScoreModifier {
  /// 修改分數
  /// [origin] 分數來源（自然/法術）
  /// [baseScore] 原始分數
  /// 返回修改後的分數
  double modifyScore(ScoreOrigin origin, double baseScore);

  /// 檢查修改器是否激活
  bool get isActive;

  /// 修改器描述（用於調試）
  String get description;
}

/// Blessed Combo 分數修改器
/// 10 秒內自然消行分數 ×3
class BlessedComboModifier extends ScoreModifier {
  final bool Function() _isActiveCallback;

  BlessedComboModifier(this._isActiveCallback);

  @override
  double modifyScore(ScoreOrigin origin, double baseScore) {
    // 只影響自然消行，法術消行保持不變
    if (origin == ScoreOrigin.natural && isActive) {
      return baseScore * 3.0;
    }
    return baseScore;
  }

  @override
  bool get isActive => _isActiveCallback();

  @override
  String get description => 'Blessed Combo (×3 natural score)';
}

/// 官方俄羅斯方塊得分系統服務
/// 基於 https://tetris.wiki/Scoring 的現代指導原則
class ScoringService {
  // 分數修改器列表（攔截器鏈）
  final List<ScoreModifier> _modifiers = [];

  // 基礎消行得分（乘以等級）
  static const Map<int, int> _baseLineScores = {
    1: 100, // Single
    2: 300, // Double
    3: 500, // Triple
    4: 800, // Tetris
  };

  // T-Spin 得分
  static const Map<String, int> _tSpinScores = {
    'mini_no_lines': 100,
    'normal_no_lines': 400,
    'mini_single': 200,
    'normal_single': 800,
    'normal_double': 1200,
    'normal_triple': 1600,
  };

  // 遊戲狀態追蹤
  int _comboCount = -1; // 根據官方規範，combo 從 -1 開始
  bool _lastWasDifficultClear = false; // Back-to-Back 狀態
  int _totalLinesCleared = 0;
  int _maxCombo = 0; // 最大連擊記錄

  // 統計資料
  Map<String, int> _statistics = {
    'singles': 0,
    'doubles': 0,
    'triples': 0,
    'tetrises': 0,
    't_spins': 0,
    'combos': 0,
    'back_to_backs': 0,
  };

  /// 重置得分系統狀態
  void reset() {
    _comboCount = -1; // 重置為官方標準的 -1
    _lastWasDifficultClear = false;
    _totalLinesCleared = 0;
    _maxCombo = 0;
    _statistics = {
      'singles': 0,
      'doubles': 0,
      'triples': 0,
      'tetrises': 0,
      't_spins': 0,
      'combos': 0,
      'back_to_backs': 0,
      'max_combo': 0,
      'combo_count': 0,
    };
  }

  /// 計算消行得分
  ScoringResult calculateLineScore({
    required int linesCleared,
    required int currentLevel,
    bool isTSpin = false,
    String tSpinType = 'normal', // 'normal' 或 'mini'
    Tetromino? tetromino,
    ScoreOrigin origin = ScoreOrigin.natural, // 新增：分數來源
  }) {
    if (linesCleared == 0) {
      // 無消行時重置 Combo（根據官方規範重置為 -1）
      _comboCount = -1;
      return ScoringResult(
        points: 0,
        description: 'No lines cleared',
        breakdown: {},
      );
    }

    int totalPoints = 0;
    Map<String, int> breakdown = {};
    List<String> achievements = [];

    // 判斷是否為困難消除（Tetris 或 T-Spin）
    bool isDifficultClear = (linesCleared == 4 && !isTSpin) || isTSpin;

    // 基礎得分計算
    if (isTSpin) {
      // T-Spin 得分
      String key = _getTSpinKey(tSpinType, linesCleared);
      int baseScore = _tSpinScores[key] ?? 0;

      // Back-to-Back 獎勵
      if (_lastWasDifficultClear && isDifficultClear) {
        int b2bBonus = (baseScore * 0.5).round();
        totalPoints += baseScore + b2bBonus;
        breakdown['t_spin_base'] = baseScore;
        breakdown['back_to_back'] = b2bBonus;
        achievements.add('Back-to-Back T-Spin');
        _statistics['back_to_backs'] = (_statistics['back_to_backs'] ?? 0) + 1;
      } else {
        totalPoints += baseScore;
        breakdown['t_spin'] = baseScore;
      }

      achievements
          .add('T-Spin ${_getTSpinDisplayName(tSpinType, linesCleared)}');
      _statistics['t_spins'] = (_statistics['t_spins'] ?? 0) + 1;
    } else {
      // 標準消行得分
      int baseScore = (_baseLineScores[linesCleared] ?? 0) * currentLevel;

      // Back-to-Back 獎勵（僅限 Tetris）
      if (linesCleared == 4 && _lastWasDifficultClear) {
        int b2bBonus = (baseScore * 0.5).round();
        totalPoints += baseScore + b2bBonus;
        breakdown['tetris_base'] = baseScore;
        breakdown['back_to_back'] = b2bBonus;
        achievements.add('Back-to-Back Tetris');
        _statistics['back_to_backs'] = (_statistics['back_to_backs'] ?? 0) + 1;
      } else {
        totalPoints += baseScore;
        breakdown[_getLineClearName(linesCleared)] = baseScore;
      }

      // 更新統計
      _updateLineStatistics(linesCleared);
    }

    // Combo 獎勵計算（官方規範：從 -1 開始，每次消行 +1）
    _comboCount++;

    // 更新最大連擊記錄
    if (_comboCount > _maxCombo) {
      _maxCombo = _comboCount;
      _statistics['max_combo'] = _maxCombo;
    }

    if (_comboCount > 0) {
      int comboBonus = 50 * _comboCount * currentLevel;
      totalPoints += comboBonus;
      breakdown['combo'] = comboBonus;
      achievements.add('${_comboCount} Combo');
      _statistics['combos'] = (_statistics['combos'] ?? 0) + 1;
      _statistics['combo_count'] =
          (_statistics['combo_count'] ?? 0) + _comboCount;
    }

    // 更新狀態
    _lastWasDifficultClear = isDifficultClear;
    _totalLinesCleared += linesCleared;

    // 應用分數修改器（攔截器鏈）
    double finalPoints = totalPoints.toDouble();
    for (final modifier in _modifiers) {
      if (modifier.isActive) {
        double modifiedPoints = modifier.modifyScore(origin, finalPoints);
        debugPrint(
            'ScoringService: ${modifier.description} - ${finalPoints.toInt()} -> ${modifiedPoints.toInt()}');
        finalPoints = modifiedPoints;
      }
    }

    return ScoringResult(
      points: finalPoints.toInt(),
      description: achievements.join(', '),
      breakdown: breakdown,
      achievements: achievements,
      comboCount: max(0, _comboCount),
      isBackToBack: _lastWasDifficultClear && isDifficultClear,
      comboRank: comboRankDescription,
    );
  }

  /// 計算軟降得分
  int calculateSoftDropScore(int cellsDropped) {
    return cellsDropped; // 1分/格
  }

  /// 計算硬降得分
  int calculateHardDropScore(int cellsDropped) {
    return cellsDropped * 2; // 2分/格
  }

  /// 獲取統計資料
  Map<String, int> getStatistics() {
    return Map.from(_statistics);
  }

  /// 獲取 T-Spin 類型鍵值
  String _getTSpinKey(String type, int lines) {
    if (lines == 0) {
      return type == 'mini' ? 'mini_no_lines' : 'normal_no_lines';
    } else if (lines == 1) {
      return type == 'mini' ? 'mini_single' : 'normal_single';
    } else if (lines == 2) {
      return 'normal_double';
    } else if (lines == 3) {
      return 'normal_triple';
    }
    return 'normal_no_lines';
  }

  /// 獲取 T-Spin 顯示名稱
  String _getTSpinDisplayName(String type, int lines) {
    String prefix = type == 'mini' ? 'Mini T-Spin' : 'T-Spin';
    switch (lines) {
      case 0:
        return prefix;
      case 1:
        return '$prefix Single';
      case 2:
        return '$prefix Double';
      case 3:
        return '$prefix Triple';
      default:
        return prefix;
    }
  }

  /// 獲取消行名稱
  String _getLineClearName(int lines) {
    switch (lines) {
      case 1:
        return 'single';
      case 2:
        return 'double';
      case 3:
        return 'triple';
      case 4:
        return 'tetris';
      default:
        return 'lines_$lines';
    }
  }

  /// 更新消行統計
  void _updateLineStatistics(int lines) {
    switch (lines) {
      case 1:
        _statistics['singles'] = (_statistics['singles'] ?? 0) + 1;
        break;
      case 2:
        _statistics['doubles'] = (_statistics['doubles'] ?? 0) + 1;
        break;
      case 3:
        _statistics['triples'] = (_statistics['triples'] ?? 0) + 1;
        break;
      case 4:
        _statistics['tetrises'] = (_statistics['tetrises'] ?? 0) + 1;
        break;
    }
  }

  /// 當前 Combo 數
  int get currentCombo => max(0, _comboCount);

  /// 最大連擊記錄
  int get maxCombo => _maxCombo;

  /// 連擊等級描述
  String get comboRankDescription {
    if (_comboCount <= 0) return '';
    if (_comboCount >= 1 && _comboCount <= 3) return 'Nice Combo!';
    if (_comboCount >= 4 && _comboCount <= 6) return 'Great Combo!';
    if (_comboCount >= 7 && _comboCount <= 10) return 'Excellent Combo!';
    if (_comboCount >= 11 && _comboCount <= 15) return 'Amazing Combo!';
    if (_comboCount >= 16 && _comboCount <= 20) return 'Incredible Combo!';
    return 'LEGENDARY COMBO!';
  }

  /// 是否處於 Back-to-Back 狀態
  bool get isBackToBackReady => _lastWasDifficultClear;

  /// 總消行數
  int get totalLinesCleared => _totalLinesCleared;

  /// 添加分數修改器
  void addModifier(ScoreModifier modifier) {
    if (!_modifiers.contains(modifier)) {
      _modifiers.add(modifier);
      debugPrint('ScoringService: Added modifier - ${modifier.description}');
    }
  }

  /// 移除分數修改器
  void removeModifier(ScoreModifier modifier) {
    if (_modifiers.remove(modifier)) {
      debugPrint('ScoringService: Removed modifier - ${modifier.description}');
    }
  }

  /// 清除所有修改器
  void clearModifiers() {
    final count = _modifiers.length;
    _modifiers.clear();
    debugPrint('ScoringService: Cleared $count modifiers');
  }

  /// 獲取激活的修改器數量
  int get activeModifierCount => _modifiers.where((m) => m.isActive).length;

  /// 恢復得分系統狀態（用於載入存檔）
  void restoreState({
    required int comboCount,
    required bool lastWasDifficultClear,
    required int totalLinesCleared,
    required int maxCombo,
    required Map<String, int> statistics,
  }) {
    _comboCount = comboCount;
    _lastWasDifficultClear = lastWasDifficultClear;
    _totalLinesCleared = totalLinesCleared;
    _maxCombo = maxCombo;
    _statistics = Map<String, int>.from(statistics);
    debugPrint(
        'Scoring service state restored: combo=$comboCount, maxCombo=$maxCombo, totalLines=$totalLinesCleared');
  }
}

/// 得分結果類
class ScoringResult {
  final int points;
  final String description;
  final Map<String, int> breakdown;
  final List<String> achievements;
  final int comboCount;
  final String comboRank;
  final bool isBackToBack;

  ScoringResult({
    required this.points,
    required this.description,
    required this.breakdown,
    this.achievements = const [],
    this.comboCount = 0,
    this.comboRank = '',
    this.isBackToBack = false,
  });

  @override
  String toString() {
    return 'ScoringResult(points: $points, description: $description)';
  }
}
