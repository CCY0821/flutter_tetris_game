import 'dart:async';
import 'package:flutter/material.dart';
import 'game_logic.dart';
import 'game_state.dart';
import '../theme/game_theme.dart';
import '../core/constants.dart';

class TouchControls extends StatefulWidget {
  final GameLogic gameLogic;
  final GameState gameState;
  final VoidCallback onStateChange;

  const TouchControls({
    super.key,
    required this.gameLogic,
    required this.gameState,
    required this.onStateChange,
  });

  @override
  State<TouchControls> createState() => _TouchControlsState();
}

class _TouchControlsState extends State<TouchControls> {
  Timer? _repeatTimer;
  String? _activeButton;

  void _startRepeat(String action, VoidCallback callback) {
    if (widget.gameState.isPaused || widget.gameState.isGameOver) return;

    _activeButton = action;
    callback(); // 立即執行一次
    widget.onStateChange();

    // 開始重複執行
    _repeatTimer?.cancel();
    _repeatTimer = Timer.periodic(const Duration(milliseconds: 150), (_) {
      if (_activeButton == action &&
          !widget.gameState.isPaused &&
          !widget.gameState.isGameOver) {
        callback();
        widget.onStateChange();
      }
    });
  }

  void _stopRepeat() {
    _activeButton = null;
    _repeatTimer?.cancel();
  }

  void _executeAction(String action, VoidCallback callback) {
    if (widget.gameState.isPaused || widget.gameState.isGameOver) return;
    callback();
    widget.onStateChange();
  }

  @override
  void dispose() {
    _repeatTimer?.cancel();
    super.dispose();
  }

  Widget _buildControlButton({
    required IconData icon,
    required String action,
    required VoidCallback onPressed,
    bool allowRepeat = false,
    double size = 72,
  }) {
    final bool isDisabled =
        widget.gameState.isPaused || widget.gameState.isGameOver;
    final bool isActive = _activeButton == action && !isDisabled;

    // 方向鍵專用增強效果
    final bool isDPadButton = ['left', 'right', 'down'].contains(action);

    return Container(
      width: size,
      height: size,
      margin: const EdgeInsets.all(3),
      child: AnimatedScale(
        scale: isActive ? 0.95 : 1.0,
        duration: Duration(milliseconds: isDPadButton ? 100 : 140),
        curve: isDPadButton ? Curves.easeOutQuart : Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: Duration(milliseconds: isDPadButton ? 100 : 140),
          curve: isDPadButton ? Curves.easeOutQuart : Curves.easeOutCubic,
          transform: Matrix4.translationValues(
              0, isActive ? (isDPadButton ? 2.0 : 3.0) : 0.0, 0),
          decoration: BoxDecoration(
            gradient: isDisabled
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      cyberpunkBgDeep.withOpacity(0.6),
                      cyberpunkBgDeep.withOpacity(0.4),
                    ],
                  )
                : isActive
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDPadButton
                            ? [
                                cyberpunkSecondary,
                                cyberpunkSecondary.withOpacity(0.9),
                                cyberpunkAccent.withOpacity(0.6),
                                cyberpunkBgDeep,
                              ]
                            : [
                                cyberpunkSecondary,
                                cyberpunkSecondary.withOpacity(0.8),
                                cyberpunkBgDeep,
                              ],
                        stops: isDPadButton
                            ? [0.0, 0.3, 0.7, 1.0]
                            : [0.0, 0.5, 1.0],
                      )
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDPadButton
                            ? [
                                cyberpunkPrimary.withOpacity(0.95),
                                cyberpunkPrimary.withOpacity(0.8),
                                cyberpunkAccent.withOpacity(0.4),
                                cyberpunkBgDeep,
                              ]
                            : [
                                cyberpunkPrimary.withOpacity(0.9),
                                cyberpunkPrimary.withOpacity(0.7),
                                cyberpunkBgDeep,
                              ],
                        stops: isDPadButton
                            ? [0.0, 0.4, 0.7, 1.0]
                            : [0.0, 0.6, 1.0],
                      ),
            borderRadius: BorderRadius.circular(isDPadButton ? 16 : 14),
            border: Border.all(
              color: isActive
                  ? (isDPadButton ? cyberpunkAccent : cyberpunkSecondary)
                  : isDisabled
                      ? cyberpunkBgDeep.withOpacity(0.5)
                      : cyberpunkPrimary,
              width: isActive
                  ? (isDPadButton ? 2.5 : 2)
                  : (isDPadButton ? 1.5 : 1),
            ),
            boxShadow: isDisabled
                ? []
                : [
                    // 上方高光陰影
                    BoxShadow(
                      color:
                          Colors.white.withOpacity(isDPadButton ? 0.3 : 0.25),
                      blurRadius: isActive ? 2 : (isDPadButton ? 4 : 3),
                      offset: const Offset(0, -1),
                    ),
                    // 主要陰影
                    BoxShadow(
                      color: (isActive
                              ? (isDPadButton
                                  ? cyberpunkAccent
                                  : cyberpunkSecondary)
                              : cyberpunkPrimary)
                          .withOpacity(
                              isActive ? 0.2 : (isDPadButton ? 0.3 : 0.25)),
                      blurRadius: isActive
                          ? (isDPadButton ? 10 : 8)
                          : (isDPadButton ? 16 : 14),
                      spreadRadius: isActive ? 0 : (isDPadButton ? 2 : 1),
                      offset: Offset(
                          0,
                          isActive
                              ? (isDPadButton ? 2 : 3)
                              : (isDPadButton ? 8 : 6)),
                    ),
                    // 霓虹外光
                    BoxShadow(
                      color: (isActive
                              ? (isDPadButton
                                  ? cyberpunkAccent
                                  : cyberpunkSecondary)
                              : cyberpunkPrimary)
                          .withOpacity(isDPadButton ? 0.25 : 0.2),
                      blurRadius: isActive
                          ? (isDPadButton ? 18 : 16)
                          : (isDPadButton ? 24 : 20),
                      spreadRadius: -2,
                      offset: const Offset(0, 0),
                    ),
                    // D-Pad 專用額外霓虹環
                    if (isDPadButton)
                      BoxShadow(
                        color: (isActive ? cyberpunkAccent : cyberpunkPrimary)
                            .withOpacity(0.15),
                        blurRadius: isActive ? 28 : 32,
                        spreadRadius: -4,
                        offset: const Offset(0, 0),
                      ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(isDPadButton ? 16 : 14),
            child: InkWell(
              borderRadius: BorderRadius.circular(isDPadButton ? 16 : 14),
              hoverColor: cyberpunkPrimary.withOpacity(0.1),
              splashColor: (isDPadButton ? cyberpunkAccent : cyberpunkSecondary)
                  .withOpacity(0.3),
              onTapDown: (!isDisabled && allowRepeat)
                  ? (_) => _startRepeat(action, onPressed)
                  : null,
              onTapUp:
                  (!isDisabled && allowRepeat) ? (_) => _stopRepeat() : null,
              onTapCancel: (!isDisabled && allowRepeat) ? _stopRepeat : null,
              onTap: (!isDisabled && !allowRepeat)
                  ? () => _executeAction(action, onPressed)
                  : null,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(isDPadButton ? 14 : 12),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(isActive
                          ? (isDPadButton ? 0.2 : 0.15)
                          : (isDPadButton ? 0.12 : 0.08)),
                      Colors.transparent,
                      Colors.black.withOpacity(isActive
                          ? (isDPadButton ? 0.15 : 0.1)
                          : (isDPadButton ? 0.08 : 0.05)),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: isDisabled
                        ? cyberpunkBgDeep.withOpacity(0.5)
                        : Colors.white,
                    size: size * (isDPadButton ? 0.45 : 0.4),
                    shadows: isDisabled
                        ? null
                        : [
                            Shadow(
                              color: isActive
                                  ? (isDPadButton
                                      ? cyberpunkAccent.withOpacity(0.9)
                                      : cyberpunkSecondary.withOpacity(0.8))
                                  : (isDPadButton
                                      ? cyberpunkPrimary.withOpacity(0.8)
                                      : Colors.white.withOpacity(0.6)),
                              blurRadius: isDPadButton ? 8 : 6,
                              offset: const Offset(0, 0),
                            ),
                            Shadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 2,
                              offset: const Offset(1, 1),
                            ),
                            // D-Pad 專用額外內發光
                            if (isDPadButton)
                              Shadow(
                                color: isActive
                                    ? cyberpunkAccent.withOpacity(0.6)
                                    : cyberpunkPrimary.withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 0),
                              ),
                          ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // 計算控制區域寬度，確保不為負數
    final controlWidth = (screenWidth - 32).clamp(200.0, double.infinity);
    
    return Container(
      width: controlWidth,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cyberpunkPanel,
            cyberpunkBgDeep,
            cyberpunkPanel.withOpacity(0.8),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(cyberpunkBorderRadiusLarge + 4),
        border: Border.all(
          color: cyberpunkPrimary.withOpacity(0.6),
          width: cyberpunkBorderWidth,
        ),
        boxShadow: [
          ...cyberpunkPanelShadow,
          BoxShadow(
            color: cyberpunkPrimary.withOpacity(0.15),
            blurRadius: cyberpunkGlowStrong,
            spreadRadius: -2,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 旋轉按鈕和硬降按鈕
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildControlButton(
                icon: Icons.rotate_left,
                action: 'rotate_ccw',
                onPressed: widget.gameLogic.rotateCounterClockwise,
                allowRepeat: false,
                size: 56,
              ),
              _buildControlButton(
                icon: Icons.rotate_right,
                action: 'rotate',
                onPressed: widget.gameLogic.rotate,
                allowRepeat: false,
                size: 60,
              ),
              _buildControlButton(
                icon: Icons.vertical_align_bottom,
                action: 'hard_drop',
                onPressed: widget.gameLogic.hardDrop,
                allowRepeat: false,
                size: 56,
              ),
            ],
          ),

          const SizedBox(height: 6),

          // 方向按鈕
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 左移
              _buildControlButton(
                icon: Icons.keyboard_arrow_left,
                action: 'left',
                onPressed: widget.gameLogic.moveLeft,
                allowRepeat: true,
                size: 56,
              ),

              // 快速下降
              _buildControlButton(
                icon: Icons.keyboard_arrow_down,
                action: 'down',
                onPressed: widget.gameLogic.moveDown,
                allowRepeat: true,
                size: 56,
              ),

              // 右移
              _buildControlButton(
                icon: Icons.keyboard_arrow_right,
                action: 'right',
                onPressed: widget.gameLogic.moveRight,
                allowRepeat: true,
                size: 56,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
