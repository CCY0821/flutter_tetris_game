import 'package:flutter/material.dart';

// UI 動畫常數
class AnimationConstants {
  /// 畫面震動持續時間（毫秒）
  static const int shakeDurationMs = 400;

  /// 輸入凍結持續時間
  static const Duration inputFreezeDuration = Duration(milliseconds: 150);
}

// UI 響應式常數
class ResponsiveConstants {
  // cellSize 範圍
  static const double minCellSize = 12.0;
  static const double maxCellSize = 24.0;

  // HUD 最小寬度
  static const double hudMinWidth = 240.0;

  // 斷點
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 900.0;

  // 縮放選項
  static const List<double> scaleOptions = [0.8, 0.9, 1.0, 1.1, 1.2];
  static const double defaultScale = 1.0;
}

class CellSizeCalculator {
  static double calculateCellSize(
      BoxConstraints constraints, int cols, int rows) {
    // 先為 HUD 保留最小寬度
    final availableWidth =
        (constraints.maxWidth - ResponsiveConstants.hudMinWidth)
            .clamp(0.0, constraints.maxWidth);
    final availableHeight = constraints.maxHeight;

    // 以寬度和高度能容納的最大 cellSize 為準
    final cellByWidth = availableWidth / cols;
    final cellByHeight = availableHeight / rows;
    final cellSize = cellByWidth < cellByHeight ? cellByWidth : cellByHeight;

    // 夾在合理範圍內
    return cellSize.clamp(
        ResponsiveConstants.minCellSize, ResponsiveConstants.maxCellSize);
  }

  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width <
        ResponsiveConstants.mobileBreakpoint;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= ResponsiveConstants.mobileBreakpoint &&
        width < ResponsiveConstants.tabletBreakpoint;
  }
}
