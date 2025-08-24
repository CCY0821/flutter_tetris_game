import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import 'ad_service_interface.dart';
import 'admob_service.dart';
import 'adsense_service.dart';

/// Factory class for creating platform-specific ad services.
/// 
/// This factory implements the Factory pattern to create appropriate
/// ad service instances based on the current platform. Follows OCP
/// (Open/Closed Principle) by allowing new ad services to be added
/// without modifying existing code.
class AdFactory {
  static final Logger _logger = Logger('AdFactory');
  
  /// Private constructor to prevent instantiation
  AdFactory._();
  
  /// Create appropriate ad service based on current platform.
  /// 
  /// Returns:
  /// - [AdMobService] for Android and iOS platforms
  /// - [AdSenseService] for web platform
  /// - null if platform is not supported
  /// 
  /// The returned service must be initialized before use.
  static AdServiceInterface? createAdService() {
    try {
      if (kIsWeb) {
        _logger.info('Creating AdSense service for web platform');
        return AdSenseService();
      } else if (Platform.isAndroid) {
        _logger.info('Creating AdMob service for Android platform');
        return AdMobService();
      } else if (Platform.isIOS) {
        _logger.info('Creating AdMob service for iOS platform');
        return AdMobService();
      } else {
        _logger.warning('Unsupported platform for ads: ${Platform.operatingSystem}');
        return null;
      }
    } catch (error, stackTrace) {
      _logger.severe('Error creating ad service: $error', error, stackTrace);
      return null;
    }
  }
  
  /// Check if ads are supported on the current platform.
  /// 
  /// Returns true for web, Android, and iOS platforms.
  static bool get isAdSupportedPlatform {
    try {
      return kIsWeb || Platform.isAndroid || Platform.isIOS;
    } catch (e) {
      return false;
    }
  }
  
  /// Get human-readable platform name for logging.
  static String get currentPlatformName {
    try {
      if (kIsWeb) return 'Web';
      if (Platform.isAndroid) return 'Android';
      if (Platform.isIOS) return 'iOS';
      return Platform.operatingSystem;
    } catch (e) {
      return 'Unknown';
    }
  }
}