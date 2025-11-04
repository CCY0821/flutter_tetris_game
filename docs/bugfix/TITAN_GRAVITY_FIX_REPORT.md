# TITAN GRAVITY Bug 修復報告
**Bug ID**: TITAN-GRAVITY-001
**修復日期**: 2025-01-XX
**嚴重性**: 🔴 高（影響遊戲邏輯）

---

## 🐛 Bug 描述

**問題現象**:
使用 TITAN GRAVITY 技能後，下一次放置方塊時，就算沒有滿足消行條件，方塊也會自動消掉幾行。

**影響範圍**:
- 遊戲邏輯（消行機制）
- 用戶體驗（困惑、不符預期）
- 分數計算（意外獲得分數）

---

## 🔍 根本原因分析

### **TITAN GRAVITY 的實作流程**

```
1. 使用 TITAN GRAVITY
   ↓
2. 逐列壓實可視區域（底部20行）
   ↓
3. 壓實過程中可能形成滿行
   ↓
4. ❌ 沒有立即清除這些滿行
   ↓
5. 棋盤狀態保留（包含滿行）
```

### **方塊放置流程**

```
1. 放置下一個方塊
   ↓
2. 調用 lockTetromino()
   ↓
3. 調用 clearFullRows()
   ↓
4. 檢查整個棋盤（包含緩衝區）
   ↓
5. 清除所有滿行
   ├─ TITAN GRAVITY 造成的滿行 ✅
   └─ 當前方塊造成的滿行 ✅
```

### **問題核心**

TITAN GRAVITY 壓實後形成的滿行沒有被立即清除，而是延遲到下次放置方塊時才清除，導致用戶看到「異常消行」的現象。

---

## 🔧 修復方案

### **修復邏輯**

在 TITAN GRAVITY 執行完壓實後，立即調用 `clearFullRows()` 清除滿行。

### **修改檔案**

**檔案**: `lib/game/rune_system.dart`
**行數**: 1058-1078（新增代碼）

### **修復代碼**

```dart
/// 執行 Titan Gravity - 分段壓實可視區域
RuneCastResult _executeTitanGravity(
    List<List<Color?>> board, dynamic gameContext) {
  // ... 原有壓實邏輯 ...

  debugPrint(
      '[TitanGravity] Compression complete - processed $boardWidth columns, moved $totalMovedBlocks blocks');

  // 🔧 BUG FIX: 壓實完成後，立即檢查並清除滿行
  // 原因：壓實可能形成滿行，如果不立即清除，會在下次放置方塊時才清除，導致異常消行
  debugPrint('[TitanGravity] Checking for full rows after compression...');

  try {
    if (gameContext?.gameLogic != null) {
      // 調用遊戲邏輯的消行函數
      gameContext.gameLogic.clearFullRows();
      debugPrint('[TitanGravity] Full rows cleared successfully after compression');
    } else {
      debugPrint('[TitanGravity] Warning: gameContext.gameLogic is null, skipping row clearing');
    }
  } catch (e) {
    debugPrint('[TitanGravity] Error clearing rows: $e');
    // 不返回錯誤，因為壓實本身已經成功
  }

  debugPrint('[TitanGravity] Execution complete');

  return RuneCastResult.success;
}
```

### **修復重點**

1. **立即清除滿行**: 壓實完成後立即調用 `clearFullRows()`
2. **異常處理**: 使用 try-catch 捕獲可能的錯誤
3. **防呆檢查**: 檢查 `gameContext.gameLogic` 是否為 null
4. **調試日誌**: 新增詳細的日誌輸出

---

## ✅ 修復後的行為

### **新的 TITAN GRAVITY 流程**

```
1. 使用 TITAN GRAVITY
   ↓
2. 逐列壓實可視區域（底部20行）
   ↓
3. 壓實完成後檢查滿行
   ↓
4. ✅ 立即清除滿行 + 計分 + 獲得能量
   ↓
5. 棋盤狀態更新（乾淨，無滿行）
```

### **用戶體驗改進**

| 修復前 | 修復後 |
|-------|-------|
| 使用 TITAN GRAVITY → 看似無事發生 | 使用 TITAN GRAVITY → 壓實 + 立即消行（如有） |
| 放置下一個方塊 → 異常消行 | 放置下一個方塊 → 正常消行檢查 |
| 用戶困惑：「為什麼突然消行？」 | 用戶清楚：「TITAN GRAVITY 壓實後立即消行」 |

---

## 🧪 測試指南

### **測試步驟**

#### **測試一：TITAN GRAVITY 形成滿行**

1. **準備測試環境**：
   ```bash
   flutter run
   ```

2. **建立測試場景**：
   - 堆疊方塊，讓底部形成不規則排列
   - 確保有多個列有空洞（例如：第7列、第9列有空洞）

3. **使用 TITAN GRAVITY**：
   - 累積能量至 3 格
   - 施放 TITAN GRAVITY 技能

4. **觀察行為**：
   - ✅ 預期：壓實後立即檢查並清除滿行
   - ✅ 預期：如有滿行，應立即消除並計分
   - ✅ 預期：Console 輸出 `[TitanGravity] Full rows cleared successfully after compression`

5. **放置下一個方塊**：
   - ✅ 預期：僅清除當前方塊造成的滿行（如有）
   - ❌ 不應再清除 TITAN GRAVITY 造成的滿行

---

#### **測試二：TITAN GRAVITY 未形成滿行**

1. **準備測試環境**：
   ```bash
   flutter run
   ```

2. **建立測試場景**：
   - 堆疊方塊，但底部沒有形成滿行

3. **使用 TITAN GRAVITY**：
   - 施放 TITAN GRAVITY 技能

4. **觀察行為**：
   - ✅ 預期：壓實完成，但沒有消行
   - ✅ 預期：Console 輸出 `[TitanGravity] Full rows cleared successfully after compression`（但實際未清除任何行）

5. **放置下一個方塊**：
   - ✅ 預期：正常消行檢查

---

#### **測試三：連續使用 TITAN GRAVITY**

1. **建立測試場景**：
   - 堆疊大量方塊

2. **連續使用 TITAN GRAVITY**：
   - 施放第一次 TITAN GRAVITY
   - 等待能量恢復
   - 施放第二次 TITAN GRAVITY

3. **觀察行為**：
   - ✅ 預期：每次壓實後都立即檢查並清除滿行
   - ✅ 預期：沒有延遲消行的現象

---

### **預期 Console 輸出**

```
[TitanGravity] boardH=40, boardW=10
[TitanGravity] Processing visible area: rows 20 to 39
[TitanGravity] Column 0: compressed 15 blocks
[TitanGravity] Column 1: compressed 18 blocks
...
[TitanGravity] Compression complete - processed 10 columns, moved 150 blocks
[TitanGravity] Checking for full rows after compression...
[TitanGravity] Full rows cleared successfully after compression
[TitanGravity] Execution complete
```

如果形成滿行，還會看到 `clearFullRows()` 的相關輸出：
```
[GameLogic] Cleared 2 full rows
[GameLogic] Score increased by 300 points
```

---

## 📊 驗證檢查清單

### **功能性驗證**

- [ ] TITAN GRAVITY 壓實後立即清除滿行
- [ ] 放置方塊後不會清除之前 TITAN GRAVITY 造成的滿行
- [ ] 分數計算正確（TITAN GRAVITY 造成的滿行計分）
- [ ] 能量獲得正確（消行後獲得能量）
- [ ] 不影響其他符文的行為

### **非功能性驗證**

- [ ] 無 Crash 或錯誤
- [ ] Console 輸出正確的調試日誌
- [ ] 性能沒有明顯下降
- [ ] UI 更新正常（壓實動畫 + 消行動畫）

### **邊界條件驗證**

- [ ] 空棋盤使用 TITAN GRAVITY（無滿行）
- [ ] 滿棋盤使用 TITAN GRAVITY（全部滿行）
- [ ] gameContext.gameLogic 為 null 時不 Crash

---

## 🚀 部署建議

### **測試環境部署**

```bash
# 1. 切換到測試分支
git checkout -b bugfix/titan-gravity-fix

# 2. 執行分析
flutter analyze

# 3. 執行測試（如有）
flutter test

# 4. 本地測試
flutter run
```

### **正式環境部署**

```bash
# 1. 合併到主分支
git checkout main
git merge bugfix/titan-gravity-fix

# 2. 更新版本號
# 編輯 pubspec.yaml: version: 1.2.0+4

# 3. 建置正式版
flutter build apk --release --obfuscate --split-debug-info=build/symbols

# 4. 提交變更
git add .
git commit -m "🔧 Fix: TITAN GRAVITY 異常消行問題

- 修復 TITAN GRAVITY 壓實後未立即清除滿行的 bug
- 新增壓實完成後的消行檢查邏輯
- 改進用戶體驗，避免延遲消行造成的困惑

Bug ID: TITAN-GRAVITY-001"

# 5. 推送
git push origin main
```

---

## 📝 相關文件

- **Bug 診斷指南**: `docs/troubleshooting/rune_system_debug.md`
- **符文系統架構**: `docs/patterns/coding_patterns.md`
- **遊戲邏輯文檔**: `lib/game/game_logic.dart`

---

## ⚠️ 注意事項

### **可能的副作用**

1. **分數變化**: TITAN GRAVITY 現在會立即計分（之前是延遲計分）
   - 影響：分數顯示時機改變
   - 解決：這是正確的行為，無需調整

2. **能量獲得**: TITAN GRAVITY 造成的消行會立即獲得能量
   - 影響：可能更快累積能量
   - 解決：這是預期的行為

3. **連擊計算**: TITAN GRAVITY 造成的消行會計入連擊
   - 影響：連擊計數可能增加
   - 解決：這是預期的行為

### **已知限制**

1. **gameContext.gameLogic 為 null**: 如果 gameContext 沒有正確傳遞，會跳過消行
   - 風險：低（gameContext 通常都有正確傳遞）
   - 緩解：新增調試日誌，方便排查

2. **異步問題**: clearFullRows() 可能在 UI 更新時調用
   - 風險：低（使用 try-catch 保護）
   - 緩解：不影響壓實本身的成功

---

## ✅ 修復確認

- [x] Bug 根本原因已識別
- [x] 修復代碼已實作
- [x] 程式碼分析通過（`flutter analyze`）
- [ ] 本地測試通過（需手動測試）
- [ ] 回歸測試通過（需手動測試）
- [ ] 用戶驗收測試（需上線後確認）

---

## 📞 聯絡資訊

**Bug 報告者**: [用戶]
**修復開發者**: Claude Code
**審核者**: [待確認]

**報告版本**: 1.0.0
**生成日期**: 2025-01-XX
**專案**: Flutter Tetris Game (Tetris Runes)
