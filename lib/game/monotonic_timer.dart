import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 單調時鐘系統
/// 提供遊戲內統一的時間基準，支持暫停/恢復機制
/// 用於符文冷卻、持續時間等需要時間凍結的場景
class MonotonicTimer {
  static int _gameTime = 0; // 遊戲內時間 (毫秒)
  static bool _isPaused = false;
  static Timer? _ticker;
  static final List<VoidCallback> _pauseListeners = [];
  static final List<VoidCallback> _resumeListeners = [];

  /// 啟動時鐘
  static void start() {
    stop(); // 先停止現有的計時器

    _ticker = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!_isPaused) {
        _gameTime += 16; // 邏輯幀 ~60FPS
      }
    });

    debugPrint('[MonotonicTimer] Started');
  }

  /// 停止時鐘
  static void stop() {
    _ticker?.cancel();
    _ticker = null;
    debugPrint('[MonotonicTimer] Stopped');
  }

  /// 暫停時鐘
  static void pause() {
    if (!_isPaused) {
      _isPaused = true;
      for (final listener in _pauseListeners) {
        listener();
      }
      debugPrint('[MonotonicTimer] Paused at ${_gameTime}ms');
    }
  }

  /// 恢復時鐘
  static void resume() {
    if (_isPaused) {
      _isPaused = false;
      for (final listener in _resumeListeners) {
        listener();
      }
      debugPrint('[MonotonicTimer] Resumed at ${_gameTime}ms');
    }
  }

  /// 處理應用生命週期變化
  static void handleAppLifecycle(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        pause(); // 應用進入背景時凍結時間
        break;
      case AppLifecycleState.resumed:
        resume(); // 應用回到前景時恢復時間
        break;
      case AppLifecycleState.detached:
        stop(); // 應用終止時停止時鐘
        break;
    }
  }

  /// 添加暫停監聽器
  static void addPauseListener(VoidCallback listener) {
    _pauseListeners.add(listener);
  }

  /// 添加恢復監聽器
  static void addResumeListener(VoidCallback listener) {
    _resumeListeners.add(listener);
  }

  /// 移除監聽器
  static void removePauseListener(VoidCallback listener) {
    _pauseListeners.remove(listener);
  }

  static void removeResumeListener(VoidCallback listener) {
    _resumeListeners.remove(listener);
  }

  /// 清理所有監聽器
  static void clearListeners() {
    _pauseListeners.clear();
    _resumeListeners.clear();
  }

  /// 獲取當前遊戲時間 (毫秒)
  static int get now => _gameTime;

  /// 獲取當前遊戲時間 (秒)
  static double get nowSeconds => _gameTime / 1000.0;

  /// 是否暫停中
  static bool get isPaused => _isPaused;

  /// 重置時鐘（測試用）
  static void reset() {
    _gameTime = 0;
    _isPaused = false;
    debugPrint('[MonotonicTimer] Reset');
  }

  /// 檢查時間點是否已過期
  static bool isExpired(int timestamp) {
    return _gameTime >= timestamp;
  }

  /// 獲取剩餘時間 (毫秒)
  static int getRemainingTime(int endTimestamp) {
    return math.max(0, endTimestamp - _gameTime);
  }

  /// 獲取剩餘時間進度 (0.0 - 1.0)
  static double getRemainingProgress(int startTimestamp, int endTimestamp) {
    if (endTimestamp <= startTimestamp) return 0.0;

    final total = endTimestamp - startTimestamp;
    final remaining = getRemainingTime(endTimestamp);
    return remaining / total;
  }

  /// 獲取已過時間進度 (0.0 - 1.0)
  static double getElapsedProgress(int startTimestamp, int endTimestamp) {
    return 1.0 - getRemainingProgress(startTimestamp, endTimestamp);
  }
}
