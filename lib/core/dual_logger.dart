import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// 雙路徑日誌系統：控制台 + 檔案
/// 避免關鍵日誌被 logcat 節流沖掉
class DualLogger {
  static DualLogger? _instance;
  IOSink? _sink;
  bool _initialized = false;

  DualLogger._();

  static DualLogger get instance {
    _instance ??= DualLogger._();
    return _instance!;
  }

  /// 初始化文件日誌
  Future<void> init() async {
    if (_initialized) return;
    
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/rune_debug.log');
      _sink = file.openWrite(mode: FileMode.append);
      _initialized = true;
      debugPrintSynchronously('[CRIT] DualLogger: file log at ${file.path}');
    } catch (e) {
      debugPrintSynchronously('[CRIT] DualLogger: init failed - $e');
    }
  }

  /// 記錄關鍵事件
  void crit(String msg) {
    final line = '[CRIT] ${DateTime.now().toIso8601String()} $msg';
    
    // 路徑1：同步控制台輸出（避免節流）
    debugPrintSynchronously(line);
    
    // 路徑2：文件輸出（避免被 logcat 吃掉）
    if (_initialized && _sink != null) {
      try {
        _sink!.writeln(line);
        _sink!.flush();
      } catch (e) {
        debugPrintSynchronously('[CRIT] DualLogger: write failed - $e');
      }
    }
  }

  /// 關閉資源
  Future<void> close() async {
    if (_sink != null) {
      await _sink!.close();
      _sink = null;
    }
    _initialized = false;
  }
}

/// 全域便利函數
void logCrit(String msg) {
  DualLogger.instance.crit(msg);
}