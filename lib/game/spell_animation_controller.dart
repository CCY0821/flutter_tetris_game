import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';

/// Sprite Sheet 動畫播放器
/// 用於播放 4x4 格式的爆炸動畫
class SpriteSheetAnimation {
  final String assetPath;
  final int rows;
  final int columns;
  final int totalFrames;
  final Duration frameDuration;

  ui.Image? _spriteSheet;
  bool _isLoaded = false;

  SpriteSheetAnimation({
    required this.assetPath,
    this.rows = 4,
    this.columns = 4,
    int? totalFrames,
    this.frameDuration = const Duration(milliseconds: 60),
  }) : totalFrames = totalFrames ?? (rows * columns);

  /// 載入 sprite sheet 圖片
  Future<void> load() async {
    if (_isLoaded) return;

    try {
      final data = await rootBundle.load(assetPath);
      final bytes = data.buffer.asUint8List();

      // 確保載入時保留透明通道
      final codec = await ui.instantiateImageCodec(
        bytes,
        allowUpscaling: false,
      );
      final frame = await codec.getNextFrame();
      _spriteSheet = frame.image;
      _isLoaded = true;
      debugPrint(
          '[SpriteSheetAnimation] Loaded: $assetPath (${_spriteSheet!.width}x${_spriteSheet!.height})');
      debugPrint(
          '[SpriteSheetAnimation] Image format: ${_spriteSheet!.toByteData() != null ? "with alpha" : "unknown"}');
    } catch (e) {
      debugPrint('[SpriteSheetAnimation] Failed to load $assetPath: $e');
      rethrow;
    }
  }

  /// 獲取指定幀的繪製區域
  Rect getFrameRect(int frameIndex) {
    if (!_isLoaded || _spriteSheet == null) {
      return Rect.zero;
    }

    final frameWidth = _spriteSheet!.width / columns;
    final frameHeight = _spriteSheet!.height / rows;

    final row = frameIndex ~/ columns;
    final col = frameIndex % columns;

    return Rect.fromLTWH(
      col * frameWidth,
      row * frameHeight,
      frameWidth,
      frameHeight,
    );
  }

  /// 是否已載入
  bool get isLoaded => _isLoaded;

  /// 獲取 sprite sheet 圖片
  ui.Image? get spriteSheet => _spriteSheet;

  /// 取得總動畫時長
  Duration get totalDuration => frameDuration * totalFrames;
}

/// 全螢幕法術動畫控制器
/// 覆蓋遊戲可視區域的動畫效果
class SpellAnimationController with ChangeNotifier {
  SpriteSheetAnimation? _currentAnimation;
  int _currentFrame = 0;
  bool _isPlaying = false;
  DateTime? _animationStartTime;
  Duration _elapsedTime = Duration.zero;
  VoidCallback? _onComplete;

  /// 播放動畫
  Future<void> play(SpriteSheetAnimation animation,
      {VoidCallback? onComplete}) async {
    // 確保動畫已載入
    if (!animation.isLoaded) {
      await animation.load();
    }

    _currentAnimation = animation;
    _currentFrame = 0;
    _isPlaying = true;
    _animationStartTime = DateTime.now();
    _elapsedTime = Duration.zero;
    _onComplete = onComplete;

    debugPrint(
        '[SpellAnimationController] Started animation: ${animation.assetPath}');
    notifyListeners();

    // 啟動動畫循環
    _startAnimationLoop();
  }

  /// 動畫循環
  void _startAnimationLoop() async {
    if (_currentAnimation == null || !_isPlaying) return;

    while (_isPlaying && _currentFrame < _currentAnimation!.totalFrames) {
      await Future.delayed(_currentAnimation!.frameDuration);

      if (!_isPlaying) break;

      _currentFrame++;
      _elapsedTime = DateTime.now().difference(_animationStartTime!);
      notifyListeners();
    }

    // 動畫播放完成
    if (_isPlaying) {
      stop();
      _onComplete?.call();
      debugPrint('[SpellAnimationController] Animation completed');
    }
  }

  /// 停止動畫
  void stop() {
    _isPlaying = false;
    _currentFrame = 0;
    _elapsedTime = Duration.zero;
    _animationStartTime = null;
    notifyListeners();
  }

  /// 清除當前動畫
  void clear() {
    stop();
    _currentAnimation = null;
    _onComplete = null;
    notifyListeners();
  }

  /// 獲取當前幀的繪製資訊
  SpellAnimationFrame? getCurrentFrame() {
    if (_currentAnimation == null ||
        !_isPlaying ||
        _currentAnimation!.spriteSheet == null) {
      return null;
    }

    if (_currentFrame >= _currentAnimation!.totalFrames) {
      return null;
    }

    return SpellAnimationFrame(
      spriteSheet: _currentAnimation!.spriteSheet!,
      sourceRect: _currentAnimation!.getFrameRect(_currentFrame),
      frameIndex: _currentFrame,
      totalFrames: _currentAnimation!.totalFrames,
    );
  }

  /// 是否正在播放
  bool get isPlaying => _isPlaying;

  /// 當前幀索引
  int get currentFrame => _currentFrame;

  /// 獲取播放進度 (0.0 - 1.0)
  double get progress {
    if (_currentAnimation == null || _currentAnimation!.totalFrames == 0) {
      return 0.0;
    }
    return (_currentFrame / _currentAnimation!.totalFrames).clamp(0.0, 1.0);
  }

  @override
  void dispose() {
    clear();
    super.dispose();
  }
}

/// 動畫幀資訊
class SpellAnimationFrame {
  final ui.Image spriteSheet;
  final Rect sourceRect;
  final int frameIndex;
  final int totalFrames;

  const SpellAnimationFrame({
    required this.spriteSheet,
    required this.sourceRect,
    required this.frameIndex,
    required this.totalFrames,
  });
}

/// 可視區域法術動畫疊加層 Widget
class SpellAnimationOverlay extends StatelessWidget {
  final SpellAnimationController controller;
  final double visibleAreaTop;
  final double visibleAreaHeight;
  final BoxFit fit;

  const SpellAnimationOverlay({
    Key? key,
    required this.controller,
    required this.visibleAreaTop,
    required this.visibleAreaHeight,
    this.fit = BoxFit.contain, // 預設保持比例
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final frame = controller.getCurrentFrame();

        if (frame == null) {
          return const SizedBox.shrink();
        }

        // 只覆蓋可視區域
        return Positioned(
          top: visibleAreaTop,
          left: 0,
          right: 0,
          height: visibleAreaHeight,
          child: IgnorePointer(
            child: CustomPaint(
              painter: _SpellAnimationPainter(frame, fit),
              isComplex: true,
              willChange: true,
            ),
          ),
        );
      },
    );
  }
}

/// 自定義繪製器
class _SpellAnimationPainter extends CustomPainter {
  final SpellAnimationFrame frame;
  final BoxFit fit;

  _SpellAnimationPainter(this.frame, this.fit);

  @override
  void paint(Canvas canvas, Size size) {
    final sourceSize = frame.sourceRect.size;
    final targetSize = size;

    Rect destRect;

    switch (fit) {
      case BoxFit.contain:
        // 等比例縮放，完整顯示不裁切，居中
        final double scaleX = targetSize.width / sourceSize.width;
        final double scaleY = targetSize.height / sourceSize.height;
        final double scale = scaleX < scaleY ? scaleX : scaleY;

        final scaledWidth = sourceSize.width * scale;
        final scaledHeight = sourceSize.height * scale;

        final offsetX = (targetSize.width - scaledWidth) / 2;
        final offsetY = (targetSize.height - scaledHeight) / 2;

        destRect = Rect.fromLTWH(offsetX, offsetY, scaledWidth, scaledHeight);
        break;

      case BoxFit.cover:
        // 等比例縮放，填滿整個區域，可能裁切
        final double scaleX = targetSize.width / sourceSize.width;
        final double scaleY = targetSize.height / sourceSize.height;
        final double scale = scaleX > scaleY ? scaleX : scaleY;

        final scaledWidth = sourceSize.width * scale;
        final scaledHeight = sourceSize.height * scale;

        final offsetX = (targetSize.width - scaledWidth) / 2;
        final offsetY = (targetSize.height - scaledHeight) / 2;

        destRect = Rect.fromLTWH(offsetX, offsetY, scaledWidth, scaledHeight);
        break;

      case BoxFit.fill:
        // 拉伸填滿，不保持比例
        destRect = Offset.zero & targetSize;
        break;

      default:
        destRect = Offset.zero & targetSize;
    }

    final paint = Paint()
      ..filterQuality = FilterQuality.high
      ..isAntiAlias = true;

    canvas.drawImageRect(
      frame.spriteSheet,
      frame.sourceRect,
      destRect,
      paint,
    );
  }

  @override
  bool shouldRepaint(_SpellAnimationPainter oldDelegate) {
    return frame.frameIndex != oldDelegate.frame.frameIndex;
  }
}
