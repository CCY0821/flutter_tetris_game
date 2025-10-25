import 'package:flutter/material.dart';
import '../core/constants.dart';

class GameTheme {
  // 🌃 CYBERPUNK 2077 主題配色 - 套用霓虹調色盤
  // 主要配色方案 (使用 Cyberpunk 調色盤)
  static const Color primaryDark = cyberpunkBgDeep; // 深層背景
  static const Color secondaryDark = cyberpunkPanel; // 面板背景
  static const Color accentBlue = cyberpunkPrimary; // 霓虹青色
  static const Color brightAccent = cyberpunkAccent; // 電光紫
  static const Color highlight = cyberpunkSecondary; // 霓虹洋紅

  // 遊戲板配色 (Cyberpunk 風格)
  static const Color gameBoardBg = cyberpunkBgDeep;
  static Color gridLine = cyberpunkGridLine;
  static const Color boardBorder = cyberpunkPrimary;

  // 按鈕配色 (霓虹色系)
  static const Color buttonPrimary = cyberpunkPrimary;
  static const Color buttonSecondary = cyberpunkAccent;
  static const Color buttonDanger = cyberpunkSecondary;
  static const Color buttonSuccess = cyberpunkPrimary;

  // 文字配色 (強調霓虹色)
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB8B8D1);
  static const Color textAccent = cyberpunkPrimary; // 主要強調色

  // 漸變色 (Cyberpunk 深層背景漸變)
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      cyberpunkBgDeep,
      cyberpunkPanel,
      cyberpunkBgDeep,
    ],
  );

  static const LinearGradient panelGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      cyberpunkPanel,
      cyberpunkBgDeep,
    ],
  );

  // 陰影效果 (Cyberpunk 霓虹光暈)
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: cyberpunkGlowMed,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: cyberpunkPrimary.withOpacity(0.2),
          blurRadius: cyberpunkGlowStrong,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get buttonShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: cyberpunkGlowSoft,
          offset: const Offset(0, 2),
        ),
      ];

  // 按鈕樣式 (Cyberpunk 霓虹邊框與光暈)
  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
        backgroundColor: buttonPrimary.withOpacity(0.1),
        foregroundColor: textPrimary,
        elevation: 0,
        shadowColor: buttonPrimary.withOpacity(0.5),
        side: const BorderSide(
          color: buttonPrimary,
          width: cyberpunkBorderWidth,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.all(Radius.circular(cyberpunkBorderRadius)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ).copyWith(
        overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.hovered)) {
            return buttonPrimary.withOpacity(0.2);
          }
          if (states.contains(WidgetState.pressed)) {
            return buttonPrimary.withOpacity(0.3);
          }
          return null;
        }),
      );

  static ButtonStyle get secondaryButtonStyle => ElevatedButton.styleFrom(
        backgroundColor: buttonSecondary.withOpacity(0.1),
        foregroundColor: textPrimary,
        elevation: 0,
        shadowColor: buttonSecondary.withOpacity(0.5),
        side: const BorderSide(
          color: buttonSecondary,
          width: cyberpunkBorderWidth,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.all(Radius.circular(cyberpunkBorderRadius)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ).copyWith(
        overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.hovered)) {
            return buttonSecondary.withOpacity(0.2);
          }
          if (states.contains(WidgetState.pressed)) {
            return buttonSecondary.withOpacity(0.3);
          }
          return null;
        }),
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
