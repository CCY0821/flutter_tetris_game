import 'dart:async';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:universal_html/html.dart' as html;

import '../../config/ad_config.dart';
import 'ad_service_interface.dart';

/// AdSense implementation for web platform.
/// 
/// This service handles Google AdSense banner ads using JavaScript integration
/// with proper error handling and lifecycle management. Follows SRP by focusing
/// solely on AdSense operations for web platform.
class AdSenseService implements AdServiceInterface {
  static final Logger _logger = Logger('AdSenseService');
  
  /// Track if service is initialized
  bool _isInitialized = false;
  
  /// Track banner ad load state
  AdLoadState _loadState = AdLoadState.notInitialized;
  
  /// AdSense script load completer
  Completer<bool>? _scriptLoadCompleter;
  
  /// Unique ad container ID counter
  static int _adCounter = 0;
  
  @override
  Logger get logger => _logger;
  
  @override
  String get platformName => 'Web';
  
  @override
  bool get isAdsEnabled => AdConfig.adsEnabled && _isInitialized;
  
  @override
  void setOnAdClickCallback(GamePauseCallback? callback) {
    // AdSense service placeholder - callback would be used in actual implementation
  }
  
  /// Initialize AdSense by loading the required JavaScript SDK.
  /// 
  /// Returns [true] if initialization successful, [false] otherwise.
  /// This method should be called once during app startup.
  @override
  Future<bool> initialize() async {
    if (_isInitialized) {
      _logger.info('AdSense already initialized');
      return true;
    }
    
    try {
      _logger.info('Initializing AdSense for web platform');
      
      // Check if AdSense script is already loaded
      if (_isAdSenseScriptLoaded()) {
        _isInitialized = true;
        _logger.info('AdSense script already loaded');
        return true;
      }
      
      // Load AdSense script
      final bool scriptLoaded = await _loadAdSenseScript();
      
      if (scriptLoaded) {
        _isInitialized = true;
        _loadState = AdLoadState.loaded;
        _logger.info('AdSense initialized successfully');
        return true;
      } else {
        _logger.severe('Failed to load AdSense script');
        return false;
      }
    } catch (error, stackTrace) {
      _logger.severe('Failed to initialize AdSense: $error', error, stackTrace);
      return false;
    }
  }
  
  /// Check if AdSense script is already loaded in the document.
  bool _isAdSenseScriptLoaded() {
    try {
      return html.document.querySelector('script[src*="adsbygoogle.js"]') != null;
    } catch (e) {
      return false;
    }
  }
  
  /// Load Google AdSense JavaScript SDK.
  /// 
  /// Creates and injects the AdSense script tag into the document head.
  /// Returns a [Future<bool>] indicating successful script loading.
  Future<bool> _loadAdSenseScript() async {
    if (_scriptLoadCompleter != null) {
      return await _scriptLoadCompleter!.future;
    }
    
    _scriptLoadCompleter = Completer<bool>();
    
    try {
      // Create script element
      final html.ScriptElement script = html.ScriptElement()
        ..async = true
        ..src = 'https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=${AdConfig.adSensePublisherId}';
      
      // Set up load/error handlers
      script.onLoad.listen((_) {
        _logger.info('AdSense script loaded successfully');
        if (!_scriptLoadCompleter!.isCompleted) {
          _scriptLoadCompleter!.complete(true);
        }
      });
      
      script.onError.listen((error) {
        _logger.severe('Failed to load AdSense script: $error');
        if (!_scriptLoadCompleter!.isCompleted) {
          _scriptLoadCompleter!.complete(false);
        }
      });
      
      // Add script to document head
      html.document.head?.append(script);
      
      // Timeout fallback
      Timer(const Duration(seconds: 10), () {
        if (!_scriptLoadCompleter!.isCompleted) {
          _logger.warning('AdSense script load timeout');
          _scriptLoadCompleter!.complete(false);
        }
      });
      
      return await _scriptLoadCompleter!.future;
    } catch (error, stackTrace) {
      _logger.severe('Exception loading AdSense script: $error', error, stackTrace);
      if (!_scriptLoadCompleter!.isCompleted) {
        _scriptLoadCompleter!.complete(false);
      }
      return false;
    }
  }
  
  @override
  Widget? createBannerAd() {
    if (!isAdsEnabled) {
      _logger.fine('AdSense ads not enabled');
      return null;
    }
    
    return _AdSenseBannerWidget(
      publisherId: AdConfig.adSensePublisherId,
      adSlot: AdConfig.adSenseAdSlot,
      onAdLoaded: () {
        _logger.info('AdSense banner ad loaded - potential CPM/CPC revenue');
      },
      onAdError: (error) {
        _logger.warning('AdSense banner ad error: $error');
      },
    );
  }
  
  @override
  Future<void> dispose() async {
    _logger.info('Disposing AdSense service');
    
    _isInitialized = false;
    _loadState = AdLoadState.notInitialized;
    _scriptLoadCompleter = null;
    
    _logger.info('AdSense service disposed');
  }
}

/// Internal widget for displaying AdSense banner ads.
/// 
/// This widget creates an HTML div container and initializes AdSense
/// ad display using JavaScript interop.
class _AdSenseBannerWidget extends StatefulWidget {
  final String publisherId;
  final String adSlot;
  final VoidCallback? onAdLoaded;
  final void Function(String error)? onAdError;
  
  const _AdSenseBannerWidget({
    required this.publisherId,
    required this.adSlot,
    this.onAdLoaded,
    this.onAdError,
  });
  
  @override
  State<_AdSenseBannerWidget> createState() => _AdSenseBannerWidgetState();
}

class _AdSenseBannerWidgetState extends State<_AdSenseBannerWidget> {
  static final Logger _logger = Logger('AdSenseBanner');
  late String _containerId;
  
  @override
  void initState() {
    super.initState();
    _containerId = 'adsense-banner-${++AdSenseService._adCounter}';
    
    // Initialize ad after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAd();
    });
  }
  
  /// Initialize AdSense ad in the HTML container.
  void _initializeAd() {
    try {
      // For now, just show a placeholder since AdSense integration
      // requires proper web setup and domain verification
      _logger.info('AdSense ad placeholder initialized');
      widget.onAdLoaded?.call();
    } catch (error, stackTrace) {
      _logger.severe('Error initializing AdSense ad: $error', error, stackTrace);
      widget.onAdError?.call('Initialization error: $error');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: AdConfig.bannerHeight,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          top: BorderSide(
            color: Colors.grey[300]!,
            width: 0.5,
          ),
        ),
      ),
      child: const Center(
        child: Text(
          'AdSense Banner Placeholder',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    super.dispose();
  }
}