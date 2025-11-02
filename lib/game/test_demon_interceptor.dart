import '../models/tetromino.dart';
import 'piece_provider.dart';
import 'package:flutter/foundation.dart';

/// 🧪 臨時測試用：惡魔方塊測試攔截器
/// 用於手動測試階段 1 的實現
/// ⚠️ 這是臨時檔案，階段 1 測試完成後應該刪除
class TestDemonInterceptor implements IPieceProvider {
  final IPieceProvider baseProvider;
  int _demonCount = 0;
  final int maxDemons;

  TestDemonInterceptor({
    required this.baseProvider,
    this.maxDemons = 3, // 預設插入 3 個惡魔方塊用於測試
  });

  @override
  TetrominoType getNext() {
    if (_demonCount < maxDemons) {
      _demonCount++;
      debugPrint('🔥 [TestDemonInterceptor] Injecting demon block #$_demonCount/$maxDemons');
      return TetrominoType.demon;
    }

    // 用完後使用基礎提供器
    return baseProvider.getNext();
  }

  @override
  List<TetrominoType> preview(int count) {
    final result = <TetrominoType>[];
    int tempCount = _demonCount;

    // 先填充剩餘的惡魔方塊
    for (int i = 0; i < count && tempCount < maxDemons; i++) {
      result.add(TetrominoType.demon);
      tempCount++;
    }

    // 如果還需要更多預覽，從基礎提供器獲取
    if (result.length < count) {
      final basePreview = baseProvider.preview(count - result.length);
      result.addAll(basePreview);
    }

    return result;
  }

  @override
  bool get isExhausted => _demonCount >= maxDemons;

  @override
  int get priority => 10; // 高優先級（測試用）

  @override
  String get description => 'TestDemonInterceptor($_demonCount/$maxDemons demons used)';
}
