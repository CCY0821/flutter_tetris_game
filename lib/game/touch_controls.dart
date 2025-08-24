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

    // Neumorphism + Cyberpunk 配色 (霓虹藍底色)
    const neumorphBase = Color(0xFF00D9FF); // 霓虹藍底色
    const neumorphLight = Color(0xFF33E2FF); // 稍亮霓虹藍
    const neumorphDark = Color(0xFF00A6CC); // 稍暗霓虹藍
    const cyberpunkAccent = Color(0xFF00FF88); // 霓虹綠
    const cyberpunkPink = Color(0xFFFF0080); // 電光粉

    return Container(
      width: size,
      height: size,
      margin: const EdgeInsets.all(3),
      child: AnimatedScale(
        scale: isActive ? 0.98 : 1.0,
        duration: Duration(milliseconds: isDPadButton ? 100 : 140),
        curve: isDPadButton ? Curves.easeOutQuart : Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: Duration(milliseconds: isDPadButton ? 100 : 140),
          curve: isDPadButton ? Curves.easeOutQuart : Curves.easeOutCubic,
          decoration: BoxDecoration(
            // Neumorphism 霓虹藍底色漸變
            gradient: isDisabled
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      neumorphBase.withOpacity(0.3),
                      neumorphDark.withOpacity(0.3),
                    ],
                  )
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isActive
                        ? [
                            neumorphDark, // 按下時稍深
                            neumorphBase,
                          ]
                        : [
                            neumorphLight,
                            neumorphBase,
                          ],
                  ),
            borderRadius: BorderRadius.circular(isDPadButton ? 16 : 14),
            // Neumorphism 雙陰影系統
            boxShadow: isDisabled
                ? [
                    // 禁用狀態的基礎陰影
                    const BoxShadow(
                      color: Color(0x1A000000),
                      offset: Offset(4, 4),
                      blurRadius: 8,
                    ),
                  ]
                : isActive
                    ? [
                        // Pressed 內陰影效果 (模擬)
                        const BoxShadow(
                          color: Color(0x33000000), // 內暗影
                          offset: Offset(2, 2),
                          blurRadius: 6,
                        ),
                        const BoxShadow(
                          color: Color(0x0CFFFFFF), // 內高光
                          offset: Offset(-1, -1),
                          blurRadius: 4,
                        ),
                        // Cyberpunk 霓虹光環 (按下時)
                        BoxShadow(
                          color: isDPadButton 
                              ? cyberpunkAccent.withOpacity(0.4)
                              : cyberpunkPink.withOpacity(0.3),
                          offset: const Offset(0, 0),
                          blurRadius: isDPadButton ? 12 : 8,
                          spreadRadius: -1,
                        ),
                      ]
                    : [
                        // Normal Neumorphism 外陰影
                        const BoxShadow(
                          color: Color(0x14FFFFFF), // 高光 (左上)
                          offset: Offset(-4, -4),
                          blurRadius: 10,
                        ),
                        const BoxShadow(
                          color: Color(0x59000000), // 暗影 (右下) 
                          offset: Offset(6, 6),
                          blurRadius: 16,
                        ),
                        // Cyberpunk 霓虹外光環
                        BoxShadow(
                          color: isDPadButton 
                              ? cyberpunkAccent.withOpacity(0.2)
                              : Colors.white.withOpacity(0.15),
                          offset: const Offset(0, 0),
                          blurRadius: isDPadButton ? 20 : 16,
                          spreadRadius: -2,
                        ),
                        // D-Pad 專用額外霓虹環
                        if (isDPadButton)
                          BoxShadow(
                            color: cyberpunkPink.withOpacity(0.1),
                            offset: const Offset(0, 0),
                            blurRadius: 28,
                            spreadRadius: -4,
                          ),
                      ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(isDPadButton ? 16 : 14),
            child: InkWell(
              borderRadius: BorderRadius.circular(isDPadButton ? 16 : 14),
              hoverColor: const Color(0xFF00D9FF).withOpacity(0.1),
              splashColor: isDPadButton 
                  ? const Color(0xFF00FF88).withOpacity(0.3)
                  : const Color(0xFF00D9FF).withOpacity(0.3),
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
                  // Neumorphism 內部細節漸變
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isActive
                        ? [
                            const Color(0x1A000000), // 按下時內陰影效果
                            Colors.transparent,
                            const Color(0x0CFFFFFF), // 微微高光
                          ]
                        : [
                            const Color(0x0AFFFFFF), // 微高光
                            Colors.transparent,
                            const Color(0x0A000000), // 微陰影
                          ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: isDisabled
                        ? neumorphBase.withOpacity(0.3)
                        : isActive
                            ? (isDPadButton 
                                ? const Color(0xFF00FF88) // 按下時霓虹綠
                                : Colors.white) // 按下時白色
                            : Colors.black.withOpacity(0.8),
                    size: size * (isDPadButton ? 0.45 : 0.4),
                    shadows: isDisabled
                        ? null
                        : [
                            // 主要光效
                            Shadow(
                              color: isActive
                                  ? (isDPadButton
                                      ? const Color(0xFF00FF88).withOpacity(0.8)
                                      : Colors.white.withOpacity(0.9))
                                  : Colors.black.withOpacity(0.6),
                              blurRadius: isDPadButton ? 10 : 8,
                              offset: const Offset(0, 0),
                            ),
                            // 陰影層次
                            const Shadow(
                              color: Color(0x66000000),
                              blurRadius: 2,
                              offset: Offset(1, 1),
                            ),
                            // D-Pad 專用額外內霓虹光
                            if (isDPadButton)
                              Shadow(
                                color: isActive
                                    ? const Color(0xFF00FF88).withOpacity(0.6)
                                    : const Color(0xFFFF0080).withOpacity(0.3),
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
