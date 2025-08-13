import 'dart:async';
import 'package:flutter/material.dart';
import 'game_logic.dart';
import 'game_state.dart';

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
      if (_activeButton == action && !widget.gameState.isPaused && !widget.gameState.isGameOver) {
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
    final bool isDisabled = widget.gameState.isPaused || widget.gameState.isGameOver;
    final bool isActive = _activeButton == action && !isDisabled;
    
    return Container(
      width: size,
      height: size,
      margin: const EdgeInsets.all(4),
      child: Material(
        color: isDisabled 
            ? Colors.grey.shade600 
            : isActive 
                ? Colors.orange.shade600 
                : Colors.blue.shade600,
        borderRadius: BorderRadius.circular(12),
        elevation: isDisabled ? 1 : 4,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTapDown: (!isDisabled && allowRepeat) ? (_) => _startRepeat(action, onPressed) : null,
          onTapUp: (!isDisabled && allowRepeat) ? (_) => _stopRepeat() : null,
          onTapCancel: (!isDisabled && allowRepeat) ? _stopRepeat : null,
          onTap: (!isDisabled && !allowRepeat) ? () => _executeAction(action, onPressed) : null,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive ? Colors.white : (isDisabled ? Colors.grey.shade400 : Colors.white54),
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              color: isDisabled ? Colors.grey.shade400 : Colors.white,
              size: size * 0.45,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade300, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 標題
          Text(
            'Touch Controls',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          // 上排：旋轉按鈕
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildControlButton(
                icon: Icons.rotate_right,
                action: 'rotate',
                onPressed: widget.gameLogic.rotate,
                allowRepeat: false,
                size: 70,
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // 下排：方向按鈕
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 左移
              _buildControlButton(
                icon: Icons.keyboard_arrow_left,
                action: 'left',
                onPressed: widget.gameLogic.moveLeft,
                allowRepeat: true,
              ),
              
              // 快速下降
              _buildControlButton(
                icon: Icons.keyboard_arrow_down,
                action: 'down',
                onPressed: widget.gameLogic.moveDown,
                allowRepeat: true,
              ),
              
              // 右移
              _buildControlButton(
                icon: Icons.keyboard_arrow_right,
                action: 'right',
                onPressed: widget.gameLogic.moveRight,
                allowRepeat: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}