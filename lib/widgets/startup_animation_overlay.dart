import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import '../core/constants.dart';

/// 🎬 启动动画覆盖层 - 电驭叛客风格
///
/// 动画方案：霓虹淡入 + 发光脉冲
/// - 0.0s-0.4s: "ARCANE / BLOCKS" 淡入
/// - 0.4s-0.8s: "RUNE GRID" 淡入
/// - 0.8s-1.5s: 发光脉冲效果
/// - 1.5s-2.0s: 整体淡出
class StartupAnimationOverlay extends StatefulWidget {
  const StartupAnimationOverlay({super.key});

  @override
  State<StartupAnimationOverlay> createState() =>
      _StartupAnimationOverlayState();
}

class _StartupAnimationOverlayState extends State<StartupAnimationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _titleFadeIn;
  late Animation<double> _subtitleFadeIn;
  late Animation<double> _glowPulse;
  late Animation<double> _overlayFadeOut;

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();

    // 初始化动画控制器（总时长 2 秒）
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // 阶段1: 主标题淡入 (0.0s-0.4s)
    _titleFadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.2, curve: Curves.easeOut),
      ),
    );

    // 阶段2: 副标题淡入 (0.4s-0.8s)
    _subtitleFadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.4, curve: Curves.easeOut),
      ),
    );

    // 阶段3: 发光脉冲 (0.0s-1.5s，贯穿整个显示期间)
    _glowPulse = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.75, curve: Curves.easeInOut),
      ),
    );

    // 阶段4: 整体淡出 (1.5s-2.0s)
    _overlayFadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.75, 1.0, curve: Curves.easeIn),
      ),
    );

    // 播放启动音效（音量 70%）
    _playStartupSound();

    // 开始动画
    _controller.forward().then((_) {
      // 动画结束后从 widget tree 移除
      if (mounted) {
        setState(() {
          _isVisible = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  /// 播放启动音效（优雅降级）
  Future<void> _playStartupSound() async {
    try {
      await _audioPlayer.play(
        AssetSource('audio/start.mp3'),
        volume: 0.7, // 70% 音量
      );
      await _audioPlayer.setReleaseMode(ReleaseMode.release);
    } catch (e) {
      debugPrint('⚠️ 启动音效播放失败（静默失败）: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 动画结束后返回空 Widget
    if (!_isVisible) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _overlayFadeOut.value,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      cyberpunkBgDeep,
                      const Color(0xFF1a0d2e), // 深紫黑
                      cyberpunkPanel,
                      cyberpunkBgDeep, // 右下角用深色，与左上角一致
                    ],
                    stops: const [0.0, 0.3, 0.7, 1.0],
                  ),
                ),
                child: Center(
                  child: _buildContent(context),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// 构建启动动画内容
  Widget _buildContent(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // 响应式字号（主标题：48-80px）
    final titleFontSize = (screenWidth * 0.12).clamp(48.0, 80.0);
    final subtitleFontSize = titleFontSize * 0.35;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 主标题：ARCANE (第一行)
        Opacity(
          opacity: _titleFadeIn.value,
          child: _buildGlowText(
            'ARCANE',
            fontSize: titleFontSize,
            glowIntensity: _glowPulse.value,
          ),
        ),

        // 主标题：BLOCKS (第二行)
        Opacity(
          opacity: _titleFadeIn.value,
          child: _buildGlowText(
            'BLOCKS',
            fontSize: titleFontSize,
            glowIntensity: _glowPulse.value,
          ),
        ),

        SizedBox(height: titleFontSize * 0.15),

        // 副标题：RUNE GRID
        Opacity(
          opacity: _subtitleFadeIn.value,
          child: _buildGlowText(
            'RUNE GRID',
            fontSize: subtitleFontSize,
            glowIntensity: _glowPulse.value * 0.7,
            color: cyberpunkSecondary, // 洋红色副标题
          ),
        ),
      ],
    );
  }

  /// 构建带霓虹发光效果的文字
  Widget _buildGlowText(
    String text, {
    required double fontSize,
    required double glowIntensity,
    Color? color,
  }) {
    final textColor = color ?? cyberpunkPrimary;

    return Text(
      text,
      style: GoogleFonts.orbitron(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: textColor,
        letterSpacing: fontSize * 0.05, // 字距为字号的 5%
        shadows: [
          // 内层发光（强烈）
          Shadow(
            color: textColor.withOpacity(0.8 * glowIntensity),
            blurRadius: 20 * glowIntensity,
          ),
          // 中层发光
          Shadow(
            color: textColor.withOpacity(0.6 * glowIntensity),
            blurRadius: 40 * glowIntensity,
          ),
          // 外层发光（扩散）
          Shadow(
            color: textColor.withOpacity(0.3 * glowIntensity),
            blurRadius: 60 * glowIntensity,
          ),
          // 白色高光（增强霓虹效果）
          Shadow(
            color: Colors.white.withOpacity(0.2 * glowIntensity),
            blurRadius: 80 * glowIntensity,
          ),
        ],
      ),
    );
  }
}
