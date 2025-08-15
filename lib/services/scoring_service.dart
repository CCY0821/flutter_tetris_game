import 'dart:math';
import '../models/tetromino.dart';

/// 官方俄羅斯方塊得分系統服務
/// 基於 https://tetris.wiki/Scoring 的現代指導原則
class ScoringService {
  // 基礎消行得分（乘以等級）
  static const Map<int, int> _baseLineScores = {
    1: 100,  // Single
    2: 300,  // Double  
    3: 500,  // Triple
    4: 800,  // Tetris
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
  int _comboCount = 0;
  bool _lastWasDifficultClear = false; // Back-to-Back 狀態
  int _totalLinesCleared = 0;
  
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
    _comboCount = 0;
    _lastWasDifficultClear = false;
    _totalLinesCleared = 0;
    _statistics = {
      'singles': 0,
      'doubles': 0,
      'triples': 0,
      'tetrises': 0,
      't_spins': 0,
      'combos': 0,
      'back_to_backs': 0,
    };
  }

  /// 計算消行得分
  ScoringResult calculateLineScore({
    required int linesCleared,
    required int currentLevel,
    bool isTSpin = false,
    String tSpinType = 'normal', // 'normal' 或 'mini'
    Tetromino? tetromino,
  }) {
    if (linesCleared == 0) {
      // 無消行時重置 Combo
      _comboCount = 0;
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
      
      achievements.add('T-Spin ${_getTSpinDisplayName(tSpinType, linesCleared)}');
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

    // Combo 獎勵計算
    _comboCount++;
    if (_comboCount > 1) {
      int comboBonus = 50 * (_comboCount - 1) * currentLevel;
      totalPoints += comboBonus;
      breakdown['combo'] = comboBonus;
      achievements.add('${_comboCount - 1} Combo');
      _statistics['combos'] = (_statistics['combos'] ?? 0) + 1;
    }

    // 更新狀態
    _lastWasDifficultClear = isDifficultClear;
    _totalLinesCleared += linesCleared;

    return ScoringResult(
      points: totalPoints,
      description: achievements.join(', '),
      breakdown: breakdown,
      achievements: achievements,
      comboCount: _comboCount - 1,
      isBackToBack: _lastWasDifficultClear && isDifficultClear,
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
      case 0: return prefix;
      case 1: return '$prefix Single';
      case 2: return '$prefix Double';
      case 3: return '$prefix Triple';
      default: return prefix;
    }
  }

  /// 獲取消行名稱
  String _getLineClearName(int lines) {
    switch (lines) {
      case 1: return 'single';
      case 2: return 'double';
      case 3: return 'triple';
      case 4: return 'tetris';
      default: return 'lines_$lines';
    }
  }

  /// 更新消行統計
  void _updateLineStatistics(int lines) {
    switch (lines) {
      case 1: _statistics['singles'] = (_statistics['singles'] ?? 0) + 1; break;
      case 2: _statistics['doubles'] = (_statistics['doubles'] ?? 0) + 1; break;
      case 3: _statistics['triples'] = (_statistics['triples'] ?? 0) + 1; break;
      case 4: _statistics['tetrises'] = (_statistics['tetrises'] ?? 0) + 1; break;
    }
  }

  /// 當前 Combo 數
  int get currentCombo => max(0, _comboCount - 1);

  /// 是否處於 Back-to-Back 狀態
  bool get isBackToBackReady => _lastWasDifficultClear;

  /// 總消行數
  int get totalLinesCleared => _totalLinesCleared;
}

/// 得分結果類
class ScoringResult {
  final int points;
  final String description;
  final Map<String, int> breakdown;
  final List<String> achievements;
  final int comboCount;
  final bool isBackToBack;

  ScoringResult({
    required this.points,
    required this.description,
    required this.breakdown,
    this.achievements = const [],
    this.comboCount = 0,
    this.isBackToBack = false,
  });

  @override
  String toString() {
    return 'ScoringResult(points: $points, description: $description)';
  }
}