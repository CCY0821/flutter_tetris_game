import 'dart:async';
import 'package:flutter/material.dart';
import 'game_logic.dart';
import 'game_state.dart';
import '../theme/game_theme.dart';

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
    double size = 60,
  }) {
    final bool isDisabled =
        widget.gameState.isPaused || widget.gameState.isGameOver;
    final bool isActive = _activeButton == action && !isDisabled;

    // Cyberpunk 色彩定義
    const cyberpunkPrimary = Color(0xFF00D9FF); // 霓虹藍
    const cyberpunkSecondary = Color(0xFFFF0080); // 電光粉
    const cyberpunkAccent = Color(0xFF00FF88); // 亮綠
    const cyberpunkYellow = Color(0xFFFFDD00); // 黃
    const cyberpunkBg = Color(0xFF0A0F1E); // 深色背景

    return Container(
      width: size,
      height: size,
      margin: const EdgeInsets.all(3),
      child: AnimatedScale(
        scale: isActive ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0, isActive ? 3.0 : 0.0, 0),
          decoration: BoxDecoration(
            gradient: isDisabled
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      cyberpunkBg.withOpacity(0.6),
                      cyberpunkBg.withOpacity(0.4),
                    ],
                  )
                : isActive
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          cyberpunkSecondary,
                          cyberpunkSecondary.withOpacity(0.8),
                          cyberpunkBg,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      )
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          cyberpunkPrimary.withOpacity(0.9),
                          cyberpunkPrimary.withOpacity(0.7),
                          cyberpunkBg,
                        ],
                        stops: const [0.0, 0.6, 1.0],
                      ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive
                  ? cyberpunkSecondary
                  : isDisabled
                      ? cyberpunkBg.withOpacity(0.5)
                      : cyberpunkPrimary,
              width: isActive ? 2 : 1,
            ),
            boxShadow: isDisabled
                ? []
                : [
                    // 上方高光陰影
                    BoxShadow(
                      color: Colors.white.withOpacity(0.25),
                      blurRadius: isActive ? 2 : 3,
                      offset: const Offset(0, -1),
                    ),
                    // 主要陰影
                    BoxShadow(
                      color: (isActive ? cyberpunkSecondary : cyberpunkPrimary)
                          .withOpacity(isActive ? 0.15 : 0.25),
                      blurRadius: isActive ? 8 : 14,
                      spreadRadius: isActive ? 0 : 1,
                      offset: Offset(0, isActive ? 3 : 6),
                    ),
                    // 霓虹外光
                    BoxShadow(
                      color: (isActive ? cyberpunkSecondary : cyberpunkPrimary)
                          .withOpacity(0.2),
                      blurRadius: isActive ? 16 : 20,
                      spreadRadius: -2,
                      offset: const Offset(0, 0),
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              hoverColor: cyberpunkPrimary.withOpacity(0.1),
              splashColor: cyberpunkSecondary.withOpacity(0.3),
              onTapDown: (!isDisabled && allowRepeat)
                  ? (_) => _startRepeat(action, onPressed)
                  : null,
              onTapUp: (!isDisabled && allowRepeat) ? (_) => _stopRepeat() : null,
              onTapCancel: (!isDisabled && allowRepeat) ? _stopRepeat : null,
              onTap: (!isDisabled && !allowRepeat)
                  ? () => _executeAction(action, onPressed)
                  : null,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(isActive ? 0.15 : 0.08),
                      Colors.transparent,
                      Colors.black.withOpacity(isActive ? 0.1 : 0.05),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: isDisabled
                        ? cyberpunkBg.withOpacity(0.5)
                        : isActive
                            ? Colors.white
                            : Colors.white,
                    size: size * 0.4,
                    shadows: isDisabled
                        ? null
                        : [
                            Shadow(
                              color: isActive 
                                  ? cyberpunkSecondary.withOpacity(0.8)
                                  : Colors.white.withOpacity(0.6),
                              blurRadius: 6,
                              offset: const Offset(0, 0),
                            ),
                            Shadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 2,
                              offset: const Offset(1, 1),
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
    // Cyberpunk 面板色彩
    const cyberpunkPrimary = Color(0xFF00D9FF); // 霓虹藍
    const cyberpunkBg = Color(0xFF0A0F1E); // 深色背景
    const cyberpunkPanel = Color(0xFF1A1F2E); // 面板背景

    return Container(
      width: GameState.colCount * 20,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cyberpunkPanel,
            cyberpunkBg,
            cyberpunkPanel.withOpacity(0.8),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cyberpunkPrimary.withOpacity(0.6),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: cyberpunkPrimary.withOpacity(0.15),
            blurRadius: 16,
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
                size: 40,
              ),
              _buildControlButton(
                icon: Icons.rotate_right,
                action: 'rotate',
                onPressed: widget.gameLogic.rotate,
                allowRepeat: false,
                size: 45,
              ),
              _buildControlButton(
                icon: Icons.vertical_align_bottom,
                action: 'hard_drop',
                onPressed: widget.gameLogic.hardDrop,
                allowRepeat: false,
                size: 40,
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
                size: 40,
              ),

              // 快速下降
              _buildControlButton(
                icon: Icons.keyboard_arrow_down,
                action: 'down',
                onPressed: widget.gameLogic.moveDown,
                allowRepeat: true,
                size: 40,
              ),

              // 右移
              _buildControlButton(
                icon: Icons.keyboard_arrow_right,
                action: 'right',
                onPressed: widget.gameLogic.moveRight,
                allowRepeat: true,
                size: 40,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
