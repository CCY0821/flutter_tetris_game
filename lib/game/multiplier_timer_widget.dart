import 'package:flutter/material.dart';
import 'game_state.dart';
import 'effect_timer_widget.dart';

/// 分數加成計時器 Widget（惡魔方塊系統）
///
/// 功能：
/// - 顯示剩餘時間倒數
/// - 進度條動畫（紅到黃漸層）
/// - 最後 3 秒閃爍效果
class MultiplierTimerWidget extends StatelessWidget {
  final GameState gameState;

  const MultiplierTimerWidget({
    super.key,
    required this.gameState,
  });

  @override
  Widget build(BuildContext context) {
    return EffectTimerWidget(
      config: EffectTimerConfig(
        endTime: gameState.multiplierEndTime,
        effectName: '三倍加成',
        emoji: '🔥',
        primaryColor: const Color(0xFFDC143C), // 紅色
        secondaryColor: const Color(0xFFFFD700), // 金色
      ),
    );
  }
}
