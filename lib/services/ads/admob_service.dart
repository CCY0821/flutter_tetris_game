import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:logging/logging.dart';

import '../../config/ad_config.dart';
import 'ad_service_interface.dart';

/// AdMob implementation for mobile platforms (Android/iOS).
///
/// This service handles Google AdMob banner ads with proper error handling,
/// retry logic, and lifecycle management. Follows SRP by focusing solely
/// on AdMob operations.
class AdMobService implements AdServiceInterface {
  static final Logger _logger = Logger('AdMobService');

  /// Current banner ad instance
  BannerAd? _bannerAd;

  /// Track if service is initialized
  bool _isInitialized = false;

  /// Track banner ad load state
  AdLoadState _loadState = AdLoadState.notInitialized;

  /// Retry counter for failed ad loads
  int _retryCount = 0;

  /// Flag to track if ad needs refresh after app resume
  bool _needsRefresh = false;

  /// Track last refresh time to avoid excessive refreshes
  DateTime? _lastRefreshTime;

  /// Minimum interval between ad refreshes (in seconds)
  static const int _minRefreshIntervalSeconds = 300; // 5 minutes

  /// Callback to pause game when ad is clicked
  GamePauseCallback? _onAdClickCallback;

  @override
  Logger get logger => _logger;

  @override
  String get platformName => Platform.isAndroid ? 'Android' : 'iOS';

  @override
  bool get isAdsEnabled => AdConfig.adsEnabled && _isInitialized;

  @override
  void setOnAdClickCallback(GamePauseCallback? callback) {
    _onAdClickCallback = callback;
  }

  /// Initialize AdMob SDK and configure settings.
  ///
  /// Returns [true] if initialization successful, [false] otherwise.
  /// This method should be called once during app startup.
  @override
  Future<bool> initialize() async {
    if (_isInitialized) {
      _logger.info('AdMob already initialized');
      return true;
    }

    try {
      _logger.info('Initializing AdMob for $platformName');

      // Initialize Google Mobile Ads SDK
      await MobileAds.instance.initialize();

      // Configure request configuration for COPPA compliance
      final RequestConfiguration requestConfig = RequestConfiguration(
        tagForChildDirectedTreatment: TagForChildDirectedTreatment.no,
        tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.no,
      );

      MobileAds.instance.updateRequestConfiguration(requestConfig);

      _isInitialized = true;
      _logger.info('AdMob initialized successfully');

      // Pre-load banner ad
      await _loadBannerAd();

      return true;
    } catch (error, stackTrace) {
      _logger.severe('Failed to initialize AdMob: $error', error, stackTrace);
      return false;
    }
  }

  /// Load banner ad with retry logic.
  ///
  /// This method creates a new [BannerAd] instance with proper event handlers
  /// and attempts to load it. Includes retry logic for failed loads.
  Future<void> _loadBannerAd() async {
    if (!_isInitialized) {
      _logger.warning('Attempted to load ad before initialization');
      return;
    }

    // Dispose existing ad if any
    await _disposeBannerAd();

    _loadState = AdLoadState.loading;

    try {
      final String adUnitId = Platform.isAndroid
          ? AdConfig.androidBannerUnitId
          : AdConfig.iosBannerUnitId;

      _logger.fine('Loading banner ad with unit ID: $adUnitId');

      _bannerAd = BannerAd(
        adUnitId: adUnitId,
        request: const AdRequest(),
        size: AdSize.banner,
        listener: BannerAdListener(
          onAdLoaded: (Ad ad) {
            _logger.info('Banner ad loaded successfully');
            _loadState = AdLoadState.loaded;
            _retryCount = 0; // Reset retry counter on success
          },
          onAdFailedToLoad: (Ad ad, LoadAdError error) {
            _logger.warning('Banner ad failed to load: ${error.message}');
            _loadState = AdLoadState.failed;
            ad.dispose();
            _bannerAd = null;

            // Retry logic
            _handleAdLoadFailure(error);
          },
          onAdOpened: (Ad ad) {
            _logger
                .info('Banner ad opened - user navigating to external content');
          },
          onAdClosed: (Ad ad) {
            _logger.info('Banner ad closed - user returned to app');
            // 當用戶從廣告返回時，可以觸發遊戲狀態檢查
          },
          onAdImpression: (Ad ad) {
            _logger.fine('Banner ad impression recorded');
          },
          onAdClicked: (Ad ad) {
            _logger.info('Banner ad clicked - pausing game before navigation');

            // First: Pause the game immediately
            _onAdClickCallback?.call();

            // Then: Log CPC event and mark for refresh
            _logger.info('CPC event triggered - ad navigation will follow');
            _needsRefresh = true;
          },
        ),
      );

      await _bannerAd!.load();

      // Update last refresh time
      _lastRefreshTime = DateTime.now();
    } catch (error, stackTrace) {
      _logger.severe('Exception loading banner ad: $error', error, stackTrace);
      _loadState = AdLoadState.failed;
      await _disposeBannerAd();
    }
  }

  /// Handle banner ad load failure with retry logic.
  ///
  /// Implements exponential backoff for retries up to [AdConfig.maxLoadRetries].
  void _handleAdLoadFailure(LoadAdError error) {
    if (_retryCount < AdConfig.maxLoadRetries) {
      _retryCount++;
      final int delaySeconds = _retryCount * 2; // Exponential backoff

      _logger.info(
          'Retrying banner ad load in ${delaySeconds}s (attempt $_retryCount/${AdConfig.maxLoadRetries})');

      Future.delayed(Duration(seconds: delaySeconds), () {
        if (_isInitialized) {
          _loadBannerAd();
        }
      });
    } else {
      _logger.warning('Maximum ad load retries reached. Giving up.');
    }
  }

  /// Dispose current banner ad instance.
  Future<void> _disposeBannerAd() async {
    if (_bannerAd != null) {
      await _bannerAd!.dispose();
      _bannerAd = null;
      _logger.fine('Banner ad disposed');
    }
  }

  @override
  Widget? createBannerAd() {
    if (!isAdsEnabled ||
        _loadState != AdLoadState.loaded ||
        _bannerAd == null) {
      _logger.fine(
          'Banner ad not available - enabled: $isAdsEnabled, state: $_loadState');
      return null;
    }

    return Container(
      width: double.infinity,
      height: AdConfig.bannerHeight,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          top: BorderSide(
            color: Colors.grey[300]!,
            width: 0.5,
          ),
        ),
      ),
      child: AdWidget(ad: _bannerAd!),
    );
  }

  /// Handle app resume event - refresh ad if needed
  ///
  /// Call this method when the app resumes from background.
  /// Only refreshes ad in specific cases to avoid unnecessary flickering:
  /// 1. Ad was clicked and needs refresh (_needsRefresh = true)
  /// 2. Ad failed to load (_loadState = failed)
  /// 3. Sufficient time has passed since last refresh
  Future<void> onAppResumed() async {
    if (!_isInitialized) {
      return;
    }

    _logger.info('App resumed - checking if ad refresh needed');

    // Check if ad needs refresh
    bool shouldRefresh = false;
    String reason = '';

    // Case 1: Ad was clicked and marked for refresh
    if (_needsRefresh) {
      shouldRefresh = true;
      reason = 'ad was clicked';
      _needsRefresh = false;
    }
    // Case 2: Ad failed to load
    else if (_loadState == AdLoadState.failed) {
      shouldRefresh = true;
      reason = 'ad load failed';
    }
    // Case 3: Minimum refresh interval passed
    else if (_lastRefreshTime != null) {
      final timeSinceLastRefresh = DateTime.now().difference(_lastRefreshTime!);
      if (timeSinceLastRefresh.inSeconds > _minRefreshIntervalSeconds) {
        shouldRefresh = true;
        reason =
            'minimum refresh interval passed (${timeSinceLastRefresh.inMinutes} minutes)';
      }
    }

    if (shouldRefresh) {
      _logger.info('Refreshing banner ad: $reason');
      await _loadBannerAd();
    } else {
      _logger.info(
          'Skipping ad refresh - ad is stable and clickable (state: $_loadState)');
    }
  }

  @override
  Future<void> dispose() async {
    _logger.info('Disposing AdMob service');

    await _disposeBannerAd();
    _isInitialized = false;
    _loadState = AdLoadState.notInitialized;
    _retryCount = 0;
    _needsRefresh = false;
    _lastRefreshTime = null;

    _logger.info('AdMob service disposed');
  }
}
