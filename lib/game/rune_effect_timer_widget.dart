import 'package:flutter/material.dart';
import 'game_state.dart';
import 'effect_timer_widget.dart';

/// 符文效果計時器 Widget
///
/// 功能：
/// - 監聽時間系符文效果（Time Change / Blessed Combo）
/// - 顯示剩餘時間倒數
/// - 進度條動畫
/// - 最後 3 秒閃爍效果
class RuneEffectTimerWidget extends StatelessWidget {
  final GameState gameState;
  final bool isOverlayMode; // 是否為浮動層模式

  const RuneEffectTimerWidget({
    super.key,
    required this.gameState,
    this.isOverlayMode = false,
  });

  @override
  Widget build(BuildContext context) {
    // 檢查 Time Change 效果
    if (gameState.timeChangeEndTime != null) {
      return EffectTimerWidget(
        config: EffectTimerConfig(
          endTime: gameState.timeChangeEndTime,
          effectName: '時間減速',
          emoji: '⏰',
          primaryColor: const Color(0xFF673AB7), // 紫色
          secondaryColor: const Color(0xFF2196F3), // 藍色
          isOverlayMode: isOverlayMode,
        ),
      );
    }

    // 檢查 Blessed Combo 效果
    if (gameState.blessedComboEndTime != null) {
      return EffectTimerWidget(
        config: EffectTimerConfig(
          endTime: gameState.blessedComboEndTime,
          effectName: '祝福連擊',
          emoji: '⭐',
          primaryColor: const Color(0xFFFF9800), // 橙色
          secondaryColor: const Color(0xFFFFD700), // 金色
          isOverlayMode: isOverlayMode,
        ),
      );
    }

    // 沒有效果激活
    return const SizedBox.shrink();
  }
}
