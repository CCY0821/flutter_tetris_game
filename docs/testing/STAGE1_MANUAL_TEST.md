# 階段 1 手動測試指南

## 🎯 測試目標

驗證惡魔方塊的核心數據結構是否正確實現：
1. ✅ 惡魔方塊能正確生成（10格隨機形狀）
2. ✅ 惡魔方塊能正確顯示在遊戲中
3. ✅ 惡魔方塊無法旋轉
4. ✅ 惡魔方塊可以正常移動和放置

---

## 📝 測試前準備

### 步驟 1：啟用測試攔截器

修改 `lib/game/game_state.dart` 的 `GameState._internal()` 建構函式：

**原始代碼（第 26-37 行）：**
```dart
GameState._internal() {
  // 初始化方塊供應器系統
  // H型方塊設為稀有方塊：每30個方塊隨機出現1次
  final bagWithoutH =
      BagProvider(excludedTypes: {TetrominoType.H}); // 9種方塊的bag
  final rareH = RareBlockInterceptor(
    baseProvider: bagWithoutH,
    rareType: TetrominoType.H,
    cycleLength: 30, // 每30個方塊出現1次H型
  );
  pieceProviderStack = PieceProviderStack(baseProvider: rareH);
}
```

**修改為（添加測試攔截器）：**
```dart
GameState._internal() {
  // 🧪 臨時測試：啟用惡魔方塊測試攔截器
  final bagWithoutH =
      BagProvider(excludedTypes: {TetrominoType.H, TetrominoType.demon}); // 排除 H 和 demon
  final rareH = RareBlockInterceptor(
    baseProvider: bagWithoutH,
    rareType: TetrominoType.H,
    cycleLength: 30,
  );

  // 🔥 插入測試攔截器：前 3 個方塊將是惡魔方塊
  final testDemon = TestDemonInterceptor(
    baseProvider: rareH,
    maxDemons: 3, // 生成 3 個惡魔方塊用於測試
  );

  pieceProviderStack = PieceProviderStack(baseProvider: testDemon);
}
```

### 步驟 2：添加 import

在 `lib/game/game_state.dart` 頂部添加：
```dart
import 'test_demon_interceptor.dart'; // 🧪 臨時測試用
```

---

## 🎮 執行測試

### 1. 啟動遊戲

```bash
flutter run -d windows  # Windows
# 或
flutter run -d emulator-5554  # Android 模擬器
```

### 2. 觀察控制台日誌

當遊戲啟動時，您應該看到：
```
🔥 [TestDemonInterceptor] Injecting demon block #1/3
[DemonPieceGenerator] Generated valid shape (attempt 1)
```

---

## ✅ 測試檢查清單

### 測試 1：惡魔方塊生成與顯示

**操作：**
1. 啟動遊戲
2. 觀察第一個下落的方塊

**預期結果：**
- ✅ 方塊形狀是隨機的 10 格形狀（不是標準的 I/O/T/S/Z/L/J/D/U/H）
- ✅ 方塊顏色為金色（#FFD700）
- ✅ 方塊大小比標準方塊大（最多 5×5）
- ✅ 控制台顯示 `Injecting demon block #1/3`

**如果失敗：**
- 檢查 `test_demon_interceptor.dart` 是否正確導入
- 檢查 `GameState._internal()` 修改是否正確

---

### 測試 2：惡魔方塊無法旋轉

**操作：**
1. 當惡魔方塊下落時
2. 按下旋轉按鈕（或按鍵 `Up Arrow`/`X`/`Z`）

**預期結果：**
- ✅ 方塊不旋轉（保持原樣）
- ✅ 沒有旋轉音效
- ✅ 沒有視覺反饋

**如果失敗：**
- 檢查 `lib/game/srs_system.dart` 的 `attemptRotation` 是否正確處理 demon
- 檢查 `lib/models/tetromino.dart` 的 `isDemon` getter 是否正確

---

### 測試 3：惡魔方塊可以移動

**操作：**
1. 當惡魔方塊下落時
2. 按左右方向鍵移動
3. 按下方向鍵加速下降
4. 按空白鍵硬降（Hard Drop）

**預期結果：**
- ✅ 方塊可以正常左右移動
- ✅ 方塊可以加速下降
- ✅ 方塊可以硬降到底部
- ✅ 移動邏輯與標準方塊相同

**如果失敗：**
- 檢查 `Tetromino.demon()` 的 shape 轉換邏輯
- 檢查碰撞檢測是否正確處理大方塊

---

### 測試 4：惡魔方塊可以放置

**操作：**
1. 讓惡魔方塊落到底部
2. 觀察方塊是否正確鎖定

**預期結果：**
- ✅ 方塊正確鎖定在棋盤上
- ✅ 方塊顏色保持金色
- ✅ 下一個方塊正常生成

**如果失敗：**
- 檢查 `getAbsolutePositions()` 方法
- 檢查棋盤鎖定邏輯

---

### 測試 5：連續生成 3 個惡魔方塊

**操作：**
1. 放置第一個惡魔方塊
2. 觀察第二個方塊
3. 放置第二個惡魔方塊
4. 觀察第三個方塊
5. 放置第三個惡魔方塊
6. 觀察第四個方塊

**預期結果：**
- ✅ 前 3 個方塊都是惡魔方塊（形狀各異）
- ✅ 控制台顯示 `Injecting demon block #1/3`、`#2/3`、`#3/3`
- ✅ 第 4 個方塊恢復正常（標準方塊或 H 型）
- ✅ 每個惡魔方塊的形狀都不同（有很高機率）

**如果失敗：**
- 檢查 `TestDemonInterceptor` 的計數邏輯
- 檢查 `PieceProviderStack` 的清理邏輯

---

### 測試 6：惡魔方塊形狀多樣性

**操作：**
1. 重啟遊戲 5 次
2. 記錄每次第一個惡魔方塊的形狀

**預期結果：**
- ✅ 5 次重啟至少看到 3 種不同的形狀
- ✅ 所有形狀都是 10 格
- ✅ 所有形狀都是連續的（沒有分離的格子）

**如果失敗：**
- 檢查 `DemonPieceGenerator` 的隨機邏輯
- 檢查是否每次都觸發降級方案（應該很少發生）

---

### 測試 7：惡魔方塊 Next Piece 預覽

**操作：**
1. 啟動遊戲
2. 觀察右側 Next Piece 預覽區域

**預期結果：**
- ✅ 前 3 個預覽方塊都是惡魔方塊（金色）
- ✅ 預覽形狀與實際下落的方塊一致
- ✅ 預覽形狀正確顯示（不會超出預覽框）

**如果失敗：**
- 檢查 `TestDemonInterceptor.preview()` 方法
- 檢查 Next Piece 渲染邏輯

---

### 測試 8：惡魔方塊性能測試

**操作：**
1. 觀察遊戲流暢度
2. 檢查 FPS（使用 Flutter DevTools）

**預期結果：**
- ✅ 遊戲維持 60 FPS
- ✅ 惡魔方塊生成時無明顯卡頓
- ✅ 方塊移動流暢

**如果失敗：**
- 檢查 `DemonPieceGenerator.generateShape()` 的性能
- 運行單元測試中的性能測試

---

## 🐛 常見問題排查

### 問題 1：看不到惡魔方塊

**可能原因：**
- `TestDemonInterceptor` 未正確導入
- `GameState._internal()` 未正確修改
- 方塊顏色與背景相同（機率很低）

**解決方案：**
1. 檢查控制台是否有 `Injecting demon block` 日誌
2. 在 `Tetromino.demon()` 添加 `debugPrint('Creating demon tetromino')`
3. 檢查 `typeColors[TetrominoType.demon]` 是否正確

---

### 問題 2：惡魔方塊形狀太大無法放置

**可能原因：**
- 生成的形狀寬度超過 10 格（應該不會發生）
- 起始位置計算錯誤

**解決方案：**
1. 運行單元測試：`flutter test test/demon_block_phase1_test.dart`
2. 檢查 `getBoundingBox()` 返回的寬度
3. 檢查起始位置 `x: boardWidth ~/ 2` 是否正確

---

### 問題 3：惡魔方塊可以旋轉

**可能原因：**
- `SRSSystem.attemptRotation` 未正確處理 demon
- 旋轉邏輯繞過了 SRS 系統

**解決方案：**
1. 檢查 `lib/game/srs_system.dart:360-369` 的 demon 判斷
2. 添加 `debugPrint` 確認旋轉請求被正確攔截
3. 檢查 `isDemon` getter 是否正確返回 true

---

### 問題 4：遊戲崩潰

**可能原因：**
- 惡魔方塊形狀超出邊界
- 碰撞檢測邏輯錯誤

**解決方案：**
1. 查看崩潰堆疊追蹤
2. 檢查 `getAbsolutePositions()` 返回的座標
3. 運行單元測試確認基礎功能正常

---

## 🧹 測試完成後清理

**重要：測試完成後必須還原代碼！**

### 步驟 1：還原 game_state.dart

將 `lib/game/game_state.dart` 的 `GameState._internal()` 還原為原始代碼（移除 TestDemonInterceptor）

### 步驟 2：刪除測試文件

```bash
# 刪除臨時測試文件
rm lib/game/test_demon_interceptor.dart
rm docs/testing/STAGE1_MANUAL_TEST.md  # 本文件
```

### 步驟 3：提交測試報告（可選）

如果發現 bug，請記錄：
- Bug 描述
- 重現步驟
- 預期行為 vs 實際行為
- 截圖或影片

---

## ✅ 測試通過標準

如果以下所有項目都通過，階段 1 開發完成：

- [x] 所有 18 個單元測試通過 ✓
- [ ] 測試 1：惡魔方塊生成與顯示 ✓
- [ ] 測試 2：惡魔方塊無法旋轉 ✓
- [ ] 測試 3：惡魔方塊可以移動 ✓
- [ ] 測試 4：惡魔方塊可以放置 ✓
- [ ] 測試 5：連續生成 3 個惡魔方塊 ✓
- [ ] 測試 6：惡魔方塊形狀多樣性 ✓
- [ ] 測試 7：惡魔方塊 Next Piece 預覽 ✓
- [ ] 測試 8：惡魔方塊性能測試 ✓

**總計**: 9 項檢查（1 項自動化 + 8 項手動）

---

## 📸 測試截圖建議

建議截圖記錄：
1. 第一個惡魔方塊的形狀（全屏）
2. 惡魔方塊在 Next Piece 預覽中的顯示
3. 按下旋轉按鈕後方塊不旋轉的狀態
4. 3 個不同形狀的惡魔方塊（合成圖）
5. 控制台日誌顯示 `Injecting demon block` 的截圖

---

## 📞 需要幫助？

如果測試過程中遇到問題：
1. 檢查本文件的「常見問題排查」章節
2. 重新運行單元測試：`flutter test test/demon_block_phase1_test.dart`
3. 查看設計文檔：`docs/features/demon_block_system_design.md`
4. 查看實現細節：`lib/game/demon_piece_generator.dart`

---

**最後更新**: 2025-11-02
**文檔版本**: 1.0
**對應階段**: 階段 1（核心數據結構）
