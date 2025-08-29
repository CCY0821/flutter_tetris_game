/// Ad configuration constants for different platforms and build modes.
///
/// This file contains all advertisement IDs and settings for the Tetris game.
/// - Production IDs should be replaced with real publisher/app/unit IDs
/// - Test IDs are used in debug mode to prevent policy violations
/// - Different platforms (Android/iOS/Web) have separate configurations
class AdConfig {
  /// AdMob test banner unit ID for development
  static const String _testBannerUnitId =
      'ca-app-pub-3940256099942544/6300978111';

  // ============================================================================
  // 🚨 PRODUCTION IDs - Replace these with your real Google AdSense/AdMob IDs
  // ============================================================================

  /// Production Google AdSense Publisher ID (Web platform)
  static const String _prodAdSensePublisherId = 'pub-0000000000000000';

  /// Production Google AdSense Ad Unit ID (Web banner)
  static const String _prodAdSenseAdSlot = '0000000000';

  /// Production AdMob App ID for Android
  static const String _prodAndroidAppId =
      'ca-app-pub-0000000000000000~0000000000';

  /// Production AdMob Banner Unit ID for Android
  static const String _prodAndroidBannerUnitId =
      'ca-app-pub-0000000000000000/0000000000';

  /// Production AdMob App ID for iOS
  static const String _prodIosAppId = 'ca-app-pub-0000000000000000~0000000000';

  /// Production AdMob Banner Unit ID for iOS
  static const String _prodIosBannerUnitId =
      'ca-app-pub-0000000000000000/0000000000';

  // ============================================================================
  // 🎯 Platform-specific getters
  // ============================================================================

  /// Gets AdSense Publisher ID for web platform
  static String get adSensePublisherId {
    const bool isDebug = bool.fromEnvironment('dart.vm.product') == false;
    return isDebug ? 'pub-test' : _prodAdSensePublisherId;
  }

  /// Gets AdSense Ad Slot for web platform
  static String get adSenseAdSlot {
    const bool isDebug = bool.fromEnvironment('dart.vm.product') == false;
    return isDebug ? 'test-slot' : _prodAdSenseAdSlot;
  }

  /// Gets AdMob App ID for Android platform
  static String get androidAppId {
    const bool isDebug = bool.fromEnvironment('dart.vm.product') == false;
    return isDebug
        ? 'ca-app-pub-3940256099942544~3347511713'
        : _prodAndroidAppId;
  }

  /// Gets AdMob Banner Unit ID for Android platform
  static String get androidBannerUnitId {
    const bool isDebug = bool.fromEnvironment('dart.vm.product') == false;
    return isDebug ? _testBannerUnitId : _prodAndroidBannerUnitId;
  }

  /// Gets AdMob App ID for iOS platform
  static String get iosAppId {
    const bool isDebug = bool.fromEnvironment('dart.vm.product') == false;
    return isDebug ? 'ca-app-pub-3940256099942544~1458002511' : _prodIosAppId;
  }

  /// Gets AdMob Banner Unit ID for iOS platform
  static String get iosBannerUnitId {
    const bool isDebug = bool.fromEnvironment('dart.vm.product') == false;
    return isDebug ? _testBannerUnitId : _prodIosBannerUnitId;
  }

  // ============================================================================
  // 📊 Ad Display Settings
  // ============================================================================

  /// Standard banner ad height in pixels
  static const double bannerHeight = 60.0;

  /// Enable ads in this build (can be toggled for premium versions)
  static const bool adsEnabled = true;

  /// Minimum time between ad refresh (seconds)
  static const int adRefreshInterval = 30;

  /// Maximum ad load retry attempts
  static const int maxLoadRetries = 3;
}
