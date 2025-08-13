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

    return Container(
      width: size,
      height: size,
      margin: const EdgeInsets.all(3),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: isDisabled
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      GameTheme.gridLine,
                      GameTheme.gridLine.withOpacity(0.8),
                    ],
                  )
                : isActive
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          GameTheme.highlight,
                          GameTheme.highlight.withOpacity(0.8),
                        ],
                      )
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          GameTheme.buttonPrimary,
                          GameTheme.buttonPrimary.withOpacity(0.8),
                        ],
                      ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive
                  ? Colors.white.withOpacity(0.8)
                  : isDisabled
                      ? GameTheme.gridLine.withOpacity(0.5)
                      : GameTheme.boardBorder.withOpacity(0.6),
              width: isActive ? 3 : 2,
            ),
            boxShadow: isDisabled
                ? []
                : [
                    BoxShadow(
                      color: (isActive
                              ? GameTheme.highlight
                              : GameTheme.buttonPrimary)
                          .withOpacity(0.3),
                      blurRadius: isActive ? 12 : 8,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
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
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(isActive ? 0.2 : 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Icon(
                icon,
                color: isDisabled
                    ? GameTheme.textSecondary.withOpacity(0.5)
                    : Colors.white,
                size: size * 0.4,
                shadows: isDisabled
                    ? null
                    : [
                        Shadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(1, 1),
                        ),
                      ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: GameTheme.panelGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: GameTheme.boardBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
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
