/// HUD 間距主題常數
class HudSpacing {
  /// 標準 HUD 組件間距
  static const double kHudGap = 8.0;

  /// 緊湊模式下的間距
  static const double kCompactGap = 6.0;

  /// 較大的分隔間距
  static const double kSectionGap = 12.0;

  /// 根據緊湊模式動態獲取間距
  static double getGap(bool tight) => tight ? kCompactGap : kHudGap;
}
