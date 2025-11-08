import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../config/ad_config.dart';
import '../core/constants.dart';
import '../services/ads/ad_factory.dart';
import '../services/ads/ad_service_interface.dart';
import '../services/ads/admob_service.dart';

/// Unified banner ad widget that works across all platforms.
///
/// This widget automatically detects the platform and displays appropriate
/// ads (AdMob for mobile, AdSense for web) or nothing if ads are disabled.
/// Follows SRP by handling only ad display concerns.
class AdBanner extends StatefulWidget {
  /// Optional callback when ad is loaded successfully
  final VoidCallback? onAdLoaded;

  /// Optional callback when ad fails to load
  final void Function(String error)? onAdError;

  /// Whether to show a debug indicator (for development)
  final bool showDebugInfo;

  /// Optional callback to pause game when ad is clicked
  final VoidCallback? onGamePauseRequested;

  const AdBanner({
    super.key,
    this.onAdLoaded,
    this.onAdError,
    this.showDebugInfo = false,
    this.onGamePauseRequested,
  });

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> with WidgetsBindingObserver {
  static final Logger _logger = Logger('AdBanner');

  /// Ad service instance
  AdServiceInterface? _adService;

  /// Track initialization state
  bool _isInitialized = false;
  bool _initializationFailed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeAdService();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _adService?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    _logger.info('App lifecycle state changed: $state');

    if (state == AppLifecycleState.resumed && _adService != null) {
      _logger.info('App resumed - notifying ad service');

      // Notify ad service of app resume - it will decide if refresh is needed
      if (_adService is AdMobService) {
        (_adService as AdMobService).onAppResumed().then((_) {
          // Only rebuild if ad service actually refreshed
          // AdMobService now has smart refresh logic to avoid unnecessary reloads
          if (mounted) {
            _logger.info('Ad service handled app resume, updating UI');
            setState(() {});
          }
        });
      } else {
        // For other ad services, just update UI
        if (mounted) {
          setState(() {});
        }
      }
    }
  }

  /// Initialize the appropriate ad service for current platform.
  Future<void> _initializeAdService() async {
    if (!AdConfig.adsEnabled) {
      _logger.info('Ads are disabled by configuration');
      return;
    }

    if (!AdFactory.isAdSupportedPlatform) {
      _logger.info(
          'Ads not supported on platform: ${AdFactory.currentPlatformName}');
      return;
    }

    try {
      _logger
          .info('Initializing ad service for ${AdFactory.currentPlatformName}');

      _adService = AdFactory.createAdService();

      if (_adService == null) {
        _logger.warning('Failed to create ad service');
        _initializationFailed = true;
        widget.onAdError?.call('Failed to create ad service');
        return;
      }

      final bool initialized = await _adService!.initialize();

      // Set up ad click callback to pause game
      _adService!.setOnAdClickCallback(widget.onGamePauseRequested);

      if (mounted) {
        setState(() {
          _isInitialized = initialized;
          _initializationFailed = !initialized;
        });
      }

      if (initialized) {
        _logger.info('Ad service initialized successfully');
        widget.onAdLoaded?.call();
      } else {
        _logger.warning('Ad service initialization failed');
        widget.onAdError?.call('Ad service initialization failed');
      }
    } catch (error, stackTrace) {
      _logger.severe('Exception during ad service initialization: $error',
          error, stackTrace);

      if (mounted) {
        setState(() {
          _initializationFailed = true;
        });
      }

      widget.onAdError?.call('Initialization exception: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Don't show anything if ads are disabled
    if (!AdConfig.adsEnabled) {
      return const SizedBox.shrink();
    }

    // Don't show anything on unsupported platforms
    if (!AdFactory.isAdSupportedPlatform) {
      return const SizedBox.shrink();
    }

    // Show loading state during initialization
    if (!_isInitialized && !_initializationFailed) {
      return _buildLoadingState();
    }

    // Show error state if initialization failed
    if (_initializationFailed) {
      return widget.showDebugInfo
          ? _buildErrorState()
          : const SizedBox.shrink();
    }

    // Show actual ad if service is available and initialized
    if (_adService != null && _isInitialized) {
      final Widget? adWidget = _adService!.createBannerAd();

      if (adWidget != null) {
        return _buildAdContainer(adWidget);
      }
    }

    // Fallback: don't show anything
    return const SizedBox.shrink();
  }

  /// Build loading state widget.
  Widget _buildLoadingState() {
    if (!widget.showDebugInfo) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      height: AdConfig.bannerHeight,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          top: BorderSide(
            color: Colors.grey[200]!,
            width: 0.5,
          ),
        ),
      ),
      child: const Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
              ),
            ),
            SizedBox(width: 8),
            Text(
              'Loading ads...',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 10,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build error state widget.
  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      height: AdConfig.bannerHeight,
      decoration: BoxDecoration(
        color: Colors.red[50],
        border: Border(
          top: BorderSide(
            color: Colors.red[200]!,
            width: 0.5,
          ),
        ),
      ),
      child: const Center(
        child: Text(
          'Ad failed to load',
          style: TextStyle(
            color: Colors.red,
            fontSize: 10,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }

  /// Build container for the actual ad widget.
  Widget _buildAdContainer(Widget adWidget) {
    return SizedBox(
      width: double.infinity,
      height: AdConfig.bannerHeight,
      child: Stack(
        children: [
          adWidget,

          // Debug info overlay
          if (widget.showDebugInfo)
            Positioned(
              top: 2,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius:
                      BorderRadius.circular(cyberpunkBorderRadiusSmall),
                ),
                child: Text(
                  AdFactory.currentPlatformName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
