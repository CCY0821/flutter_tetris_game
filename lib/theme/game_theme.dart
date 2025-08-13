import 'package:flutter/material.dart';

class GameTheme {
  // 主要配色方案
  static const Color primaryDark = Color(0xFF1A1A2E);
  static const Color secondaryDark = Color(0xFF16213E);
  static const Color accentBlue = Color(0xFF0F3460);
  static const Color brightAccent = Color(0xFF533483);
  static const Color highlight = Color(0xFFE94560);

  // 遊戲板配色
  static const Color gameBoardBg = Color(0xFF0A0E1A);
  static const Color gridLine = Color(0xFF2A2A4A);
  static const Color boardBorder = Color(0xFF3A3A6A);

  // 按鈕配色
  static const Color buttonPrimary = Color(0xFF4A90E2);
  static const Color buttonSecondary = Color(0xFF7B68EE);
  static const Color buttonDanger = Color(0xFFE94560);
  static const Color buttonSuccess = Color(0xFF50C878);

  // 文字配色
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB8B8D1);
  static const Color textAccent = Color(0xFF64FFDA);

  // 漸變色
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1A1A2E),
      Color(0xFF16213E),
      Color(0xFF0F3460),
    ],
  );

  static const LinearGradient panelGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF2A2A4A),
      Color(0xFF1A1A3A),
    ],
  );

  // 陰影效果
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: accentBlue.withOpacity(0.1),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get buttonShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];

  // 按鈕樣式
  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
        backgroundColor: buttonPrimary,
        foregroundColor: textPrimary,
        elevation: 4,
        shadowColor: buttonPrimary.withOpacity(0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      );

  static ButtonStyle get secondaryButtonStyle => ElevatedButton.styleFrom(
        backgroundColor: buttonSecondary,
        foregroundColor: textPrimary,
        elevation: 4,
        shadowColor: buttonSecondary.withOpacity(0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      );

  // 文字樣式
  static const TextStyle titleStyle = TextStyle(
    color: textPrimary,
    fontSize: 28,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.2,
  );

  static const TextStyle subtitleStyle = TextStyle(
    color: textSecondary,
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle bodyStyle = TextStyle(
    color: textPrimary,
    fontSize: 14,
    fontWeight: FontWeight.normal,
  );

  static const TextStyle accentStyle = TextStyle(
    color: textAccent,
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );
}
