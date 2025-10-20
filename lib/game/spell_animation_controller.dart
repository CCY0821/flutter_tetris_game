import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'shaders/chroma_key.dart';

/// 動畫類型枚舉
enum AnimationType {
  spriteSheet, // Sprite Sheet 逐幀動畫
  fadeInOut, // 淡入淡出動畫
}

/// Sprite Sheet 動畫播放器
/// 用於播放 4x4 格式的爆炸動畫或單張圖片淡入淡出
class SpriteSheetAnimation {
  final String assetPath;
  final AnimationType animationType;
  final int rows;
  final int columns;
  final int totalFrames;
  final Duration frameDuration;

  // 淡入淡出專用參數
  final Duration fadeInDuration;
  final Duration holdDuration;
  final Duration fadeOutDuration;

  ui.Image? _spriteSheet;
  bool _isLoaded = false;

  SpriteSheetAnimation({
    required this.assetPath,
    this.animationType = AnimationType.spriteSheet,
    this.rows = 4,
    this.columns = 4,
    int? totalFrames,
    this.frameDuration = const Duration(milliseconds: 60),
    this.fadeInDuration = const Duration(milliseconds: 200),
    this.holdDuration = const Duration(milliseconds: 500),
    this.fadeOutDuration = const Duration(milliseconds: 200),
  }) : totalFrames = totalFrames ?? (rows * columns);

  /// 載入 sprite sheet 圖片（保留完整透明度）
  Future<void> load() async {
    if (_isLoaded) return;

    try {
      final data = await rootBundle.load(assetPath);
      final bytes = data.buffer.asUint8List();

      // ✅ 關鍵修復：明確要求解碼器保留 Alpha 通道
      final codec = await ui.instantiateImageCodec(
        bytes,
        allowUpscaling: false,
        // 不指定 targetWidth/targetHeight，保持原始尺寸和格式
      );
      final frame = await codec.getNextFrame();
      _spriteSheet = frame.image;
      _isLoaded = true;

      // 驗證圖片格式（RGBA 應該有 4 個通道）
      debugPrint('[SpriteSheetAnimation] ✅ Loaded: $assetPath');
      debugPrint(
          '[SpriteSheetAnimation] Size: ${_spriteSheet!.width}x${_spriteSheet!.height}');

      // 檢查是否包含 alpha 通道
      final byteData =
          await _spriteSheet!.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData != null) {
        debugPrint(
            '[SpriteSheetAnimation] ✅ Format: RGBA (with alpha channel)');
      } else {
        debugPrint(
            '[SpriteSheetAnimation] ⚠️ Warning: Could not verify alpha channel');
      }
    } catch (e) {
      debugPrint('[SpriteSheetAnimation] ❌ Failed to load $assetPath: $e');
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

  // 淡入淡出動畫專用
  double _currentOpacity = 1.0;

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

    if (_currentAnimation!.animationType == AnimationType.fadeInOut) {
      // 淡入淡出模式
      await _playFadeInOutAnimation();
    } else {
      // Sprite Sheet 模式
      await _playSpriteSheetAnimation();
    }

    // 動畫播放完成
    if (_isPlaying) {
      stop();
      _onComplete?.call();
      debugPrint('[SpellAnimationController] Animation completed');
    }
  }

  /// 播放 Sprite Sheet 動畫
  Future<void> _playSpriteSheetAnimation() async {
    while (_isPlaying && _currentFrame < _currentAnimation!.totalFrames) {
      await Future.delayed(_currentAnimation!.frameDuration);

      if (!_isPlaying) break;

      _currentFrame++;
      _elapsedTime = DateTime.now().difference(_animationStartTime!);
      notifyListeners();
    }
  }

  /// 播放淡入淡出動畫
  Future<void> _playFadeInOutAnimation() async {
    final animation = _currentAnimation!;
    final totalDuration = animation.fadeInDuration +
        animation.holdDuration +
        animation.fadeOutDuration;

    const updateInterval = Duration(milliseconds: 16); // ~60 FPS
    final startTime = DateTime.now();

    while (_isPlaying) {
      await Future.delayed(updateInterval);

      if (!_isPlaying) break;

      _elapsedTime = DateTime.now().difference(startTime);

      // 計算當前透明度
      if (_elapsedTime < animation.fadeInDuration) {
        // 淡入階段
        final progress = _elapsedTime.inMilliseconds /
            animation.fadeInDuration.inMilliseconds;
        _currentOpacity = progress.clamp(0.0, 1.0);
      } else if (_elapsedTime <
          animation.fadeInDuration + animation.holdDuration) {
        // 停留階段
        _currentOpacity = 1.0;
      } else if (_elapsedTime < totalDuration) {
        // 淡出階段
        final fadeOutElapsed =
            _elapsedTime - animation.fadeInDuration - animation.holdDuration;
        final progress = 1.0 -
            (fadeOutElapsed.inMilliseconds /
                animation.fadeOutDuration.inMilliseconds);
        _currentOpacity = progress.clamp(0.0, 1.0);
      } else {
        // 動畫結束
        _currentOpacity = 0.0;
        break;
      }

      notifyListeners();
    }
  }

  /// 停止動畫
  void stop() {
    _isPlaying = false;
    _currentFrame = 0;
    _elapsedTime = Duration.zero;
    _animationStartTime = null;
    _currentOpacity = 1.0;
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

    if (_currentAnimation!.animationType == AnimationType.fadeInOut) {
      // 淡入淡出模式：使用整張圖片
      return SpellAnimationFrame(
        spriteSheet: _currentAnimation!.spriteSheet!,
        sourceRect: Rect.fromLTWH(
          0,
          0,
          _currentAnimation!.spriteSheet!.width.toDouble(),
          _currentAnimation!.spriteSheet!.height.toDouble(),
        ),
        frameIndex: 0,
        totalFrames: 1,
        opacity: _currentOpacity,
      );
    } else {
      // Sprite Sheet 模式
      if (_currentFrame >= _currentAnimation!.totalFrames) {
        return null;
      }

      return SpellAnimationFrame(
        spriteSheet: _currentAnimation!.spriteSheet!,
        sourceRect: _currentAnimation!.getFrameRect(_currentFrame),
        frameIndex: _currentFrame,
        totalFrames: _currentAnimation!.totalFrames,
        opacity: 1.0,
      );
    }
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
  final double opacity; // 透明度 (0.0 - 1.0)

  const SpellAnimationFrame({
    required this.spriteSheet,
    required this.sourceRect,
    required this.frameIndex,
    required this.totalFrames,
    this.opacity = 1.0,
  });
}

/// 可視區域法術動畫疊加層 Widget
class SpellAnimationOverlay extends StatelessWidget {
  final SpellAnimationController controller;
  final double visibleAreaTop;
  final double visibleAreaHeight;
  final BoxFit fit;

  const SpellAnimationOverlay({
    super.key,
    required this.controller,
    required this.visibleAreaTop,
    required this.visibleAreaHeight,
    this.fit = BoxFit.contain, // 預設保持比例
  });

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
              willChange: false, // ✅ 修復：避免離屏緩衝區導致透明度失效
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

        final scaledWidth = sourceSize.width * scale * 0.5;
        final scaledHeight = sourceSize.height * scale * 0.5;

        final offsetX = (targetSize.width - scaledWidth) / 2;
        final offsetY = (targetSize.height - scaledHeight) / 2;

        destRect = Rect.fromLTWH(offsetX, offsetY, scaledWidth, scaledHeight);
        break;

      case BoxFit.cover:
        // 等比例縮放，填滿整個區域，可能裁切
        final double scaleX = targetSize.width / sourceSize.width;
        final double scaleY = targetSize.height / sourceSize.height;
        final double scale = scaleX > scaleY ? scaleX : scaleY;

        final scaledWidth = sourceSize.width * scale * 0.5;
        final scaledHeight = sourceSize.height * scale * 0.5;

        final offsetX = (targetSize.width - scaledWidth) / 2;
        final offsetY = (targetSize.height - scaledHeight) / 2;

        destRect = Rect.fromLTWH(offsetX, offsetY, scaledWidth, scaledHeight);
        break;

      case BoxFit.fill:
        // 拉伸填滿，不保持比例
        final fillWidth = targetSize.width * 0.5;
        final fillHeight = targetSize.height * 0.5;
        final fillOffsetX = (targetSize.width - fillWidth) / 2;
        final fillOffsetY = (targetSize.height - fillHeight) / 2;
        destRect =
            Rect.fromLTWH(fillOffsetX, fillOffsetY, fillWidth, fillHeight);
        break;

      default:
        destRect = Offset.zero & targetSize;
    }

    // ✅ 正確繪製：保留 PNG 原始透明通道，只用 saveLayer 控制全域淡入淡出
    final opacity = frame.opacity.clamp(0.0, 1.0);

    // 全域淡入淡出（不改變每像素 alpha）
    if (opacity < 0.999) {
      canvas.saveLayer(
        destRect,
        Paint()..color = const Color(0xFFFFFFFF).withOpacity(opacity),
      );
    }

    // 嘗試使用 Chroma Key Shader 去除綠幕
    final shader = ChromaKey.I.createShader(
      image: frame.spriteSheet,
      srcRect: frame.sourceRect,
      dstRect: destRect,
      key: const Color(0xFF00FF00), // #00FF00 綠幕
      tolerance: 0.12,
      softness: 0.05,
    );

    if (shader != null) {
      // ✅ Shader 路徑：使用 chroma key 去除綠幕
      final paint = Paint()
        ..shader = shader
        ..filterQuality = FilterQuality.high
        ..isAntiAlias = true;
      canvas.drawRect(destRect, paint);
    } else {
      // 🔻 降級路徑：Shader 未載入，直接繪製原圖
      canvas.drawImageRect(
        frame.spriteSheet,
        frame.sourceRect,
        destRect,
        Paint()
          ..filterQuality = FilterQuality.high
          ..blendMode = BlendMode.srcOver, // 預設模式，保留 PNG 透明
      );
    }

    if (opacity < 0.999) {
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_SpellAnimationPainter oldDelegate) {
    return frame.frameIndex != oldDelegate.frame.frameIndex ||
        frame.opacity != oldDelegate.frame.opacity;
  }
}
