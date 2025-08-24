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
  
  @override
  Logger get logger => _logger;
  
  @override
  String get platformName => Platform.isAndroid ? 'Android' : 'iOS';
  
  @override
  bool get isAdsEnabled => AdConfig.adsEnabled && _isInitialized;
  
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
            _logger.info('Banner ad opened');
          },
          onAdClosed: (Ad ad) {
            _logger.info('Banner ad closed');
          },
          onAdImpression: (Ad ad) {
            _logger.fine('Banner ad impression recorded');
          },
          onAdClicked: (Ad ad) {
            _logger.info('Banner ad clicked - CPC event');
          },
        ),
      );
      
      await _bannerAd!.load();
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
      
      _logger.info('Retrying banner ad load in ${delaySeconds}s (attempt $_retryCount/${AdConfig.maxLoadRetries})');
      
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
    if (!isAdsEnabled || _loadState != AdLoadState.loaded || _bannerAd == null) {
      _logger.fine('Banner ad not available - enabled: $isAdsEnabled, state: $_loadState');
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
  
  @override
  Future<void> dispose() async {
    _logger.info('Disposing AdMob service');
    
    await _disposeBannerAd();
    _isInitialized = false;
    _loadState = AdLoadState.notInitialized;
    _retryCount = 0;
    
    _logger.info('AdMob service disposed');
  }
}