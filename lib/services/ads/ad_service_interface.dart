import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';

/// Abstract interface for ad service implementations.
/// 
/// This interface defines the contract for different ad platforms
/// (AdMob for mobile, AdSense for web) using the Strategy pattern.
/// Follows SOLID principles: SRP (single responsibility), OCP (open/closed),
/// and DIP (dependency inversion).
abstract class AdServiceInterface {
  /// Logger instance for this service
  static final Logger _logger = Logger('AdService');
  
  /// Get logger instance for concrete implementations
  Logger get logger => _logger;
  
  /// Initialize the ad service with platform-specific settings.
  /// 
  /// Returns a [Future<bool>] indicating successful initialization.
  /// Should be called once during app startup.
  Future<bool> initialize();
  
  /// Create a banner ad widget for the bottom of the screen.
  /// 
  /// Returns a [Widget] that displays the banner ad, or null if ads
  /// are disabled or failed to load. The widget should have fixed
  /// height defined by [AdConfig.bannerHeight].
  Widget? createBannerAd();
  
  /// Dispose of any resources used by the ad service.
  /// 
  /// Should be called during app shutdown to properly clean up
  /// ad resources and prevent memory leaks.
  Future<void> dispose();
  
  /// Check if ads are currently enabled and available.
  /// 
  /// Returns true if ads can be displayed, false otherwise.
  /// Considers factors like network connectivity, platform support,
  /// and user preferences.
  bool get isAdsEnabled;
  
  /// Get the current platform name for logging purposes.
  String get platformName;
}

/// Banner ad load state enumeration.
enum AdLoadState {
  /// Ad is currently loading
  loading,
  
  /// Ad loaded successfully and ready to display
  loaded,
  
  /// Ad failed to load
  failed,
  
  /// Ad is not initialized
  notInitialized,
}

/// Ad event callback types for handling ad lifecycle events.
typedef AdEventCallback = void Function(String eventType, Map<String, dynamic> data);

/// Ad error callback for handling ad loading errors.
typedef AdErrorCallback = void Function(String error, String? details);