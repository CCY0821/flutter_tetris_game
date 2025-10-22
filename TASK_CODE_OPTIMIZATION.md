# 🔧 代碼品質優化任務

## 📋 硬性前提（不可違反）

❌ **不得改動「遊戲邏輯」**與任何行為結果（含隨機性、規則、分數計算、掉落節奏、輸入時序）
❌ **不得改動「UI 佈局」**與視覺結構（元件層級/位置/尺寸/排版/層次）
✅ **功能完整一致**：所有既有功能與輸入/輸出語義毫無差異

遇到衝突時，**放棄該優化**，改採其他等效但不觸犯前提的方法。

---

## ✅ 已完成優化（2025-10-22）

### 優先級 1：高優先級優化

**Commit**: `23a6578` - ♻️ 代碼品質優化（優先級 1：高優先級項目）

| 項目 | 狀態 | 說明 |
|------|------|------|
| 1. 提取重複的 `_getComboColor()` | ✅ 完成 | 新建 `lib/utils/game_colors.dart`，減少 18 行重複 |
| 2. 提取重複的 `_getSpeedColor()` | ✅ 完成 | 合併到 `GameColors` 類，減少 30 行重複 |
| 3. GameState 尺寸常數文檔 | ✅ 完成 | 添加 GUIDELINE 和 SRS 系統說明 |
| 4. RuneSystem 魔術數字文檔 | ✅ 完成 | 解釋 16ms（60fps）和 250ms（節流） |
| 5. 修復 `_DBG_ONLY_BOARD_AND_SPELL` | ✅ 完成 | 改為 `_dbgOnlyBoardAndSpell`，符合 Dart 規範 |
| 6. 格式化與驗證 | ✅ 完成 | flutter analyze 無新警告，build 成功 |

**成效**：
- 減少約 50 行重複代碼
- 消除 1 個 flutter analyze 警告
- 提升文檔覆蓋率（+6 個關鍵常數）

---

## 🚧 待實施優化

### 優先級 2：中優先級優化（7 項）

#### 優化 7：提取棋盤座標計算邏輯 🔴 推薦優先

**位置**：`lib/game/rune_system.dart` 多處

**問題**：
```dart
final startRow = math.max(0, board.length - 20);
```
此計算模式重複出現在多個符文執行方法中。

**建議方案**：
```dart
// 在 lib/game/game_state.dart 添加
static int getVisibleAreaStartRow(int boardHeight) {
  return math.max(0, boardHeight - visibleRowCount);
}
```

**影響**：✅ 無邏輯變化，提升可維護性

**實施步驟**：
1. 在 `game_state.dart` 添加靜態方法
2. 搜尋所有 `math.max(0, board.length - 20)` 模式
3. 替換為 `GameState.getVisibleAreaStartRow(board.length)`
4. 運行測試驗證

**預計時間**：15 分鐘

---

#### 優化 8：統一空值安全模式

**位置**：`lib/game/game_logic.dart` 多處

**問題**：
```dart
// 方法 A：防禦性檢查
if (gameState.currentTetromino == null) return;

// 方法 B：強制解包
if (canMove(gameState.currentTetromino!, dx: -1)) { ... }
```
兩種模式混用，缺乏一致性。

**建議方案**：
統一使用局部變數模式：
```dart
void moveLeft() {
  final currentTetro = gameState.currentTetromino;
  if (currentTetro == null) return;

  if (canMove(currentTetro, dx: -1)) {
    currentTetro.x--;
  }
}
```

**影響**：✅ 無邏輯變化，提升代碼一致性

**實施步驟**：
1. 檢查 `game_logic.dart` 中所有使用 `currentTetromino` 的方法
2. 統一使用局部變數 + null 檢查模式
3. 測試所有移動/旋轉操作

**預計時間**：20 分鐘

---

#### 優化 9：移除未使用的導入

**位置**：`tools/chroma_key_processor_v2.dart:2`

**問題**：
```dart
import 'dart:math' as math; // 未使用
```

**建議方案**：
刪除該行。

**影響**：✅ 無邏輯變化，清理代碼

**實施步驟**：
1. 檢查檔案是否真的未使用 `math`
2. 刪除該導入
3. 運行 `flutter analyze` 確認

**預計時間**：5 分鐘

---

#### 優化 10：清理過時註釋

**位置**：`lib/game/game_logic.dart:557-558, 570-572`

**問題**：
```dart
// case RuneType.earthquake: // 已移除
//   return _executeEarthquake(board);

// case RuneType.timeSlow: // 已移除
// case RuneType.timeStop: // 已移除
```

**建議方案**：
移除已註釋的舊代碼（這些代碼已經被標記為「已移除」超過一次提交週期）。

**影響**：✅ 無邏輯變化，清理代碼

**實施步驟**：
1. 確認這些符文已完全移除
2. 刪除註釋的代碼
3. 檢查 git history 確保可以找回（如需要）

**預計時間**：5 分鐘

---

#### 優化 11：統一調試日誌前綴格式

**位置**：各個檔案的 `debugPrint` 調用

**問題**：
```dart
debugPrint('[FlameBurst] ...');          // 使用方括號
debugPrint('RuneSystem: ...');           // 使用冒號
debugPrint('GameState: ...');            // 使用冒號
debugPrint('[GravityReset] ...');        // 使用方括號
```

**建議方案**：
統一使用方括號格式：
```dart
debugPrint('[ClassName] message');
```

**影響**：✅ 無邏輯變化，提升日誌可讀性

**實施步驟**：
1. 全局搜尋 `debugPrint\('(\w+): `（regex）
2. 批量替換為 `debugPrint('[$1] `
3. 確認沒有破壞多行字串

**預計時間**：15 分鐘

---

#### 優化 12：優化列表複製性能

**位置**：`lib/core/game_persistence.dart:143-144, 187-192`

**問題**：
```dart
final board = List.from(gameData.board.map((row) => List<Color?>.from(row)));

// 以及雙重 map + toList()
return board.map((row) => row.map(...).toList()).toList();
```

**建議方案**：
```dart
final board = List<List<Color?>>.generate(
  gameData.board.length,
  (i) => List<Color?>.from(gameData.board[i]),
);
```

**影響**：✅ 無邏輯變化，性能提升（減少中間列表分配）

**實施步驟**：
1. 修改 `game_persistence.dart` 中的列表複製邏輯
2. 運行持久化相關測試
3. 使用 DevTools 確認性能提升

**預計時間**：20 分鐘

---

#### 優化 13：提取 Color 映射表到獨立檔案

**位置**：`lib/core/game_persistence.dart:16-35`

**問題**：
Color 映射表定義冗長，且顏色值與 `tetromino.dart` 重複。

**建議方案**：
```dart
// 新建 lib/theme/tetromino_colors.dart
class TetrominoColors {
  static const Color I = Color(0xFF00E5FF);
  static const Color J = Color(0xFF0066FF);
  static const Color L = Color(0xFFFF2ED1);
  static const Color O = Color(0xFFFCEE09);
  static const Color S = Color(0xFF00FF88);
  static const Color T = Color(0xFF8A2BE2);
  static const Color Z = Color(0xFFFF0066);

  static const colorToInt = {
    I: 1, J: 2, L: 3, O: 4, S: 5, T: 6, Z: 7,
  };

  static const intToColor = {
    1: I, 2: J, 3: L, 4: O, 5: S, 6: T, 7: Z,
  };
}
```

**影響**：✅ 無邏輯變化，提升可維護性

**實施步驟**：
1. 創建 `tetromino_colors.dart`
2. 檢查 `tetromino.dart` 中的顏色定義是否一致
3. 更新 `game_persistence.dart` 引用
4. 運行持久化測試

**預計時間**：25 分鐘

---

### 優先級 3：低優先級優化（14+ 項）

#### 優化 14：提取棋盤清除邏輯

**位置**：`lib/game/rune_system.dart` 多個執行方法

**問題**：
清除棋盤方塊的循環模式重複出現：
```dart
for (int row = startRow; row < boardHeight; row++) {
  for (int col = 0; col < boardWidth; col++) {
    if (board[row][col] != null) {
      board[row][col] = null;
      clearedCount++;
    }
  }
}
```

**建議方案**：
```dart
// 新建 lib/game/board_utils.dart
class BoardUtils {
  static int clearRegion(
    List<List<Color?>> board,
    {required int startRow, required int endRow,
     required int startCol, required int endCol}
  ) {
    int cleared = 0;
    for (int row = startRow; row < endRow; row++) {
      for (int col = startCol; col < endCol; col++) {
        if (board[row][col] != null) {
          board[row][col] = null;
          cleared++;
        }
      }
    }
    return cleared;
  }
}
```

**影響**：✅ 無邏輯變化，減少重複代碼

**實施步驟**：
1. 創建 `board_utils.dart`
2. 實現 `clearRegion` 方法
3. 搜尋所有重複的清除循環
4. 逐個替換並測試符文效果

**預計時間**：45 分鐘

---

#### 優化 15：提取重力效果邏輯

**位置**：`lib/game/rune_system.dart:671-683, 901-926`

**問題**：
Flame Burst 和 Dragon Roar 的重力效果邏輯幾乎相同（僅迭代次數不同）。

**建議方案**：
```dart
// 在 BoardUtils 中添加
static int applyRowGravity(
  List<List<Color?>> board,
  List<int> clearedRows,
  {int iterations = 1}
) {
  // ... 統一的重力邏輯
}
```

**影響**：✅ 無邏輯變化，減少重複代碼

**實施步驟**：
1. 分析兩個重力邏輯的差異
2. 提取共用邏輯並參數化
3. 更新 Flame Burst 和 Dragon Roar
4. 測試重力效果一致性

**預計時間**：40 分鐘

---

#### 優化 16-30：批次優化項目

**16. 常數提取：震動持續時間**
- 位置：搜尋 `400` 相關震動代碼
- 方案：`const shakeDurationMs = 400`
- 時間：10 分鐘

**17. 常數提取：輸入凍結時間**
- 位置：`lib/game/game_state.dart:236`
- 方案：`const inputFreezeMs = 150`（已使用 Duration，可保持）
- 時間：5 分鐘

**18-20. 性能優化：getter 緩存**
- 位置：`lib/game/marathon_system.dart` 的 `dropSpeed` 等計算
- 方案：為頻繁調用的計算添加緩存變數
- 時間：每個 15 分鐘

**21-28. 使用 const 構造函數**
- 位置：Flutter Analyze 指出的 8 處
- 方案：添加 `const` 關鍵字
- 時間：每個 5 分鐘

**29-30. 其他命名改進**
- 移除不必要的私有前綴
- 改善方法命名清晰度
- 時間：每個 10 分鐘

---

## 📊 優化統計

| 優先級 | 數量 | 已完成 | 待完成 | 預計總時間 |
|--------|------|--------|--------|------------|
| 優先級 1（高） | 6 | 6 ✅ | 0 | 已完成 |
| 優先級 2（中） | 7 | 0 | 7 | ~1.5 小時 |
| 優先級 3（低） | 14+ | 0 | 14+ | ~4 小時 |
| **總計** | **27+** | **6** | **21+** | **~5.5 小時** |

---

## 🎯 實施建議

### 本週計劃（建議）

**Week 1**：優先級 2（中優先級）
- 第 1-2 天：優化 7、8（座標計算、空值安全）- 核心邏輯優化
- 第 3-4 天：優化 9、10、11（清理工作）- 快速勝利
- 第 5 天：優化 12、13（性能與結構）- 重要改進

**Week 2-3**：優先級 3（低優先級）
- 選擇性實施，優先處理：
  - 優化 14、15（提取重複邏輯）- 較大重構
  - 優化 16-20（常數提取與性能）- 小改進
  - 優化 21-30（清理與規範）- 長期維護

### 每次實施流程

1. **閱讀本文檔**，選擇一個優化項目
2. **檢查硬性前提**，確認不違反
3. **實施優化**，遵循文檔中的步驟
4. **驗證**：
   ```bash
   # 格式化
   dart format <modified_files>

   # 分析
   flutter analyze

   # 構建
   flutter build apk --debug

   # 可選：運行測試
   flutter test
   ```
5. **提交**：
   ```bash
   git add <files>
   git commit -m "♻️ 代碼品質優化：<優化項目名稱>"
   git push
   ```
6. **更新本文檔**，標記為完成

---

## ✅ 優化驗證清單

每個優化完成後，必須確認：

- [ ] ✅ **遊戲邏輯不變**：運行測試，確認分數、隨機性、遊戲規則一致
- [ ] ✅ **UI 不變**：截圖對比前後 UI，確認位置、尺寸、層級一致
- [ ] ✅ **編譯通過**：`flutter analyze` 無新警告
- [ ] ✅ **性能不劣化**：使用 DevTools 確認幀率、內存使用
- [ ] ✅ **Git diff 審查**：確認只有重構變更，無意外修改

---

## 📚 參考資料

### 相關文檔
- `CLAUDE.md` - 專案開發指引
- `PROJECT_STRUCTURE.md` - 檔案結構對照表
- `docs/patterns/coding_patterns.md` - 代碼模式指南
- `TASK_ISOLATED_BLOCK_BUG_FIX.md` - Bug 修復範例

### Flutter/Dart 最佳實踐
- [Effective Dart](https://dart.dev/guides/language/effective-dart)
- [Flutter Performance Best Practices](https://flutter.dev/docs/perf/best-practices)
- [Dart Code Style](https://dart.dev/guides/language/effective-dart/style)

### 優化原則
1. **Don't Repeat Yourself (DRY)** - 消除重複代碼
2. **Single Responsibility Principle (SRP)** - 單一職責
3. **Boy Scout Rule** - 離開代碼時比發現時更乾淨
4. **KISS (Keep It Simple, Stupid)** - 保持簡單

---

## 🔍 良好實踐範例

### 已實現的優化範例

#### 範例 1：提取重複方法（優化 1-2）
```dart
// ❌ Before: 重複於 3 個檔案
Color _getComboColor(int combo) {
  if (combo >= 21) return const Color(0xFFFF1744);
  if (combo >= 16) return const Color(0xFFFF5722);
  // ... 8 行代碼
}

// ✅ After: 統一工具類
class GameColors {
  static Color getComboColor(int combo) { ... }
}

// 使用處：
return GameColors.getComboColor(combo);
```

#### 範例 2：改善文檔（優化 3-4）
```dart
// ❌ Before: 缺乏解釋
static const int visibleRowCount = 20;
static const int colCount = 10;

// ✅ After: 詳細文檔
/// Tetris 標準可視區域高度（GUIDELINE 規範）
/// 玩家可見的遊戲區域為 20 行
static const int visibleRowCount = 20;

/// Tetris 標準寬度（GUIDELINE 規範）
/// 遊戲區域寬度固定為 10 列
static const int colCount = 10;
```

#### 範例 3：命名規範（優化 6）
```dart
// ❌ Before: 違反 lowerCamelCase
static const bool _DBG_ONLY_BOARD_AND_SPELL = false;

// ✅ After: 符合 Dart 規範
static const bool _dbgOnlyBoardAndSpell = false;
```

---

## 🚨 注意事項

### 必須避免的修改

❌ **遊戲邏輯**：
- 不修改分數計算公式
- 不修改隨機數生成邏輯
- 不修改方塊掉落速度計算
- 不修改輸入時序（節流、防抖時間除外）
- 不修改消行檢測邏輯

❌ **UI 佈局**：
- 不修改元件的父子關係
- 不修改元件的位置、尺寸
- 不修改顏色值（除非提取為常數）
- 不修改動畫時長
- 不修改排版規則

### 安全的修改

✅ **可以安全進行**：
- 提取重複代碼為方法/工具類
- 添加/改善文檔註釋
- 重命名變數/方法（保持語義一致）
- 提取魔術數字為命名常數（數值不變）
- 優化算法複雜度（結果不變）
- 添加類型註解
- 移除未使用的代碼/導入

---

## 📝 更新日誌

### 2025-10-22
- ✅ 完成優先級 1 全部 6 項優化
- ✅ Commit `23a6578` 已推送到 GitHub
- 📊 減少 50 行重複代碼
- 📊 消除 1 個 flutter analyze 警告
- 📊 提升文檔覆蓋率

### 下次更新
- 待實施優先級 2 的優化項目
- 更新完成狀態和統計數據

---

**最後更新**：2025-10-22
**文檔版本**：v1.0
**負責人**：Claude Code
**狀態**：優先級 1 已完成，優先級 2-3 待實施
