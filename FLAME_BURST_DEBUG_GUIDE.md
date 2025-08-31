# Flame Burst 法術實現除錯指南

## 問題現象
- ✅ 點擊正常，能量消耗正確
- ❌ 無視覺效果，看不到行被清除

## 根本原因
**清錯目標**：清除活動方塊位置（通常是空的），而非已落地的實際方塊

## 解決方案

### 1. 目標選擇策略
```dart
// ❌ 錯誤：清除活動方塊位置
final targetRow = gameContext.currentTetromino.y;

// ✅ 正確：清除已落地方塊最多的行
final targetRow = _pickBestRowToClear(board);
```

### 2. 智能目標選擇
```dart
int _pickBestRowToClear(List<List<Color?>> board) {
  // 只檢查可見區域（底部20行）
  final startRow = math.max(0, board.length - 20);
  
  // 選擇方塊最多但未滿的行
  for (int row = startRow; row < board.length; row++) {
    int blockCount = countBlocks(board[row]);
    if (blockCount > maxBlocks && blockCount < board[row].length) {
      bestRow = row;
    }
  }
}
```

### 3. UI更新確保
```dart
// GameState中確保觸發UI重繪
runeSystem.setBoardChangeCallback(() {
  debugPrint('GameState: Board changed by rune system');
  _notifyUIUpdate?.call(); // 必須調用
});
```

### 4. 調試驗證
```dart
debugPrint('[FlameBurst] targetRow=$targetRow (best row with most blocks)');
debugPrint('[FlameBurst] Cleared $clearedCount blocks from row $targetRow');
```

## 關鍵洞察
1. **技術實現都正確**：能量、執行、通知機制
2. **策略選擇錯誤**：清除空位置沒有視覺效果
3. **用戶體驗優先**：選擇有實際內容的目標

## 通用法術實現原則
1. **目標選擇**：優先可見區域，選擇有意義的目標
2. **直接執行**：避免複雜的批次處理鏈
3. **UI更新**：確保 `_notifyUIUpdate?.call()` 被調用
4. **調試日誌**：記錄目標選擇和執行結果