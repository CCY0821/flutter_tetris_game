import 'package:flutter/material.dart';
import '../theme/game_theme.dart';

/// 遊戲顏色工具類
/// 提供統一的顏色映射邏輯，避免代碼重複
class GameColors {
  /// 根據連擊數返回對應的顏色
  ///
  /// 連擊等級：
  /// - 1-3: NICE (藍色)
  /// - 4-6: GREAT (綠色)
  /// - 7-10: EXCELLENT (黃色)
  /// - 11-15: AMAZING (橙色)
  /// - 16-20: INCREDIBLE (深橙色)
  /// - 21+: LEGENDARY (紅色)
  static Color getComboColor(int combo) {
    if (combo >= 21) return const Color(0xFFFF1744); // LEGENDARY
    if (combo >= 16) return const Color(0xFFFF5722); // INCREDIBLE
    if (combo >= 11) return const Color(0xFFFF9800); // AMAZING
    if (combo >= 7) return const Color(0xFFFFC107); // EXCELLENT
    if (combo >= 4) return const Color(0xFF4CAF50); // GREAT
    if (combo >= 1) return const Color(0xFF2196F3); // NICE
    return GameTheme.accentBlue;
  }

  /// 根據重力速度返回對應的顏色
  ///
  /// 速度等級（gravity 參數為每幀下落的行數）：
  /// - < 1.0: 慢速 (綠色)
  /// - 1.0-4.9: 中速 (黃色)
  /// - 5.0-14.9: 快速 (橙色)
  /// - 15.0+: 極速 (紅色)
  static Color getSpeedColor(double gravity) {
    if (gravity < 1.0) return Colors.green;
    if (gravity < 5.0) return Colors.yellow;
    if (gravity < 15.0) return Colors.orange;
    return Colors.red;
  }
}
