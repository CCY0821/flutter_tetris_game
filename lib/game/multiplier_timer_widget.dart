import 'dart:async';
import 'package:flutter/material.dart';
import '../core/constants.dart';
import 'game_state.dart';

/// 分數加成計時器 Widget（惡魔方塊系統）
///
/// 功能：
/// - 顯示剩餘時間倒數
/// - 進度條動畫（紅到黃漸層）
/// - 最後 3 秒閃爍效果
class MultiplierTimerWidget extends StatefulWidget {
  final GameState gameState;

  const MultiplierTimerWidget({
    super.key,
    required this.gameState,
  });

  @override
  State<MultiplierTimerWidget> createState() => _MultiplierTimerWidgetState();
}

class _MultiplierTimerWidgetState extends State<MultiplierTimerWidget>
    with SingleTickerProviderStateMixin {
  Timer? _updateTimer;
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;

  double _remainingSeconds = 0.0;
  double _totalSeconds = 10.0;
  bool _isActive = false;

  @override
  void initState() {
    super.initState();

    // 閃爍動畫控制器（最後 3 秒使用）
    _blinkController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _blinkAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _blinkController,
        curve: Curves.easeInOut,
      ),
    );

    // 每 50ms 更新一次倒數計時
    _updateTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (mounted) {
        _updateTimerDisplay();
      }
    });
  }

  void _updateTimerDisplay() {
    final endTime = widget.gameState.multiplierEndTime;

    if (endTime == null) {
      // 加成已結束
      setState(() {
        _isActive = false;
        _remainingSeconds = 0.0;
      });
      _blinkController.stop();
      _blinkController.reset();
      return;
    }

    final now = DateTime.now();
    if (now.isAfter(endTime)) {
      // 時間已到
      setState(() {
        _isActive = false;
        _remainingSeconds = 0.0;
      });
      _blinkController.stop();
      _blinkController.reset();
      return;
    }

    // 計算剩餘時間
    final remaining = endTime.difference(now);
    final seconds = remaining.inMilliseconds / 1000.0;

    setState(() {
      _isActive = true;
      _remainingSeconds = seconds;

      // 如果剩餘時間超過 10 秒，表示疊加了多次
      if (seconds > _totalSeconds) {
        _totalSeconds = seconds;
      }
    });

    // 最後 3 秒啟動閃爍動畫
    if (seconds <= 3.0 && !_blinkController.isAnimating) {
      _blinkController.repeat(reverse: true);
    } else if (seconds > 3.0 && _blinkController.isAnimating) {
      _blinkController.stop();
      _blinkController.reset();
    }
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isActive || _remainingSeconds <= 0) {
      return const SizedBox.shrink(); // 不顯示
    }

    final progress = (_remainingSeconds / _totalSeconds).clamp(0.0, 1.0);

    return AnimatedBuilder(
      animation: _blinkAnimation,
      builder: (context, child) {
        final opacity = _remainingSeconds <= 3.0 ? _blinkAnimation.value : 1.0;

        return Opacity(
          opacity: opacity,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cyberpunkPanel,
              borderRadius: BorderRadius.circular(cyberpunkBorderRadius),
              border: Border.all(
                color: const Color(0xFFDC143C).withOpacity(opacity * 0.8),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFDC143C).withOpacity(opacity * 0.4),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 標題行
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          '🔥',
                          style: TextStyle(fontSize: 16 * opacity),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          '三倍加成',
                          style: TextStyle(
                            color: Color(0xFFFFD700),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${_remainingSeconds.toStringAsFixed(1)}s',
                      style: TextStyle(
                        color: _remainingSeconds <= 3.0
                            ? const Color(0xFFDC143C)
                            : const Color(0xFFFFD700),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // 進度條
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: SizedBox(
                    height: 6,
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: const Color(0xFF8B0000).withOpacity(0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color.lerp(
                          const Color(0xFFDC143C), // 紅色（剩餘少）
                          const Color(0xFFFFD700), // 金色（剩餘多）
                          progress,
                        )!,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
