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

#### 優化 7：提取棋盤座標計算邏輯 ✅ 已完成

**位置**：`lib/game/rune_system.dart` 多處

**問題**：
```dart
final startRow = math.max(0, board.length - 20);
```
此計算模式重複出現在多個符文執行方法中。

**實施方案**：
```dart
// 創建新檔案 lib/game/board_constants.dart
class BoardConstants {
  static int getVisibleAreaStartRow(int boardHeight) {
    return boardHeight > visibleRowCount ? boardHeight - visibleRowCount : 0;
  }
}
```

**實施結果**：
- ✅ 創建 `lib/game/board_constants.dart` 統一管理棋盤常數
- ✅ 提取方法避免循環依賴問題
- ✅ 替換 4 處重複計算：
  - `lib/game/rune_targeting.dart` (3 處)
  - `lib/game/rune_system.dart` (1 處)
- ✅ 清理未使用的導入（`dart:math` in rune_targeting.dart）
- ✅ flutter analyze 無新錯誤
- ✅ flutter build 成功

**影響**：✅ 無邏輯變化，提升可維護性，消除循環依賴

**完成時間**：2025-10-23

---

#### 優化 8：統一空值安全模式 ✅ 已完成

**位置**：`lib/game/game_logic.dart` 多處

**問題**：
```dart
// 方法 A：防禦性檢查
if (gameState.currentTetromino == null) return;

// 方法 B：強制解包
if (canMove(gameState.currentTetromino!, dx: -1)) { ... }
```
兩種模式混用，缺乏一致性。

**實施方案**：
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

**實施結果**：
- ✅ 重構 7 個方法以使用一致的局部變數模式：
  - `drop()` (line 169)
  - `moveLeft()` (line 218)
  - `moveRight()` (line 227)
  - `moveDown()` (line 236)
  - `hardDrop()` (line 252)
  - `rotatePiece()` (line 291)
  - `calculateGhostPiece()` (line 381)
- ✅ 消除所有強制解包操作符 (`!`)
- ✅ 提升代碼可讀性和一致性
- ✅ flutter analyze 無新錯誤
- ✅ flutter build 成功

**影響**：✅ 無邏輯變化，提升代碼一致性和安全性

**完成時間**：2025-10-23

---

#### 優化 9：移除未使用的導入 ✅ 已完成

**位置**：`tools/chroma_key_processor_v2.dart:2`

**問題**：
```dart
import 'dart:math' as math; // 未使用
```

**實施結果**：
- ✅ 確認 `dart:math` 未在檔案中使用
- ✅ 移除未使用的導入
- ✅ 運行 `dart format` 格式化代碼
- ✅ flutter analyze 確認警告已消除

**影響**：✅ 無邏輯變化，清理代碼，消除 1 個 flutter analyze 警告

**完成時間**：2025-10-23

---

#### 優化 10：清理過時註釋 ✅ 已完成

**位置**：`lib/game/rune_system.dart:563-564, 567-568, 575-578`

**問題**：
```dart
// case RuneType.earthquake: // 已移除
//   return _executeEarthquake(board);

// case RuneType.columnBreaker: // 已移除
//   return _executeColumnBreaker(board, gameContext);

// case RuneType.timeSlow: // 已移除
//   return _executeTimeSlow();

// case RuneType.timeStop: // 已移除
//   return _executeTimeStop();
```

**實施結果**：
- ✅ 移除 4 處過時的註釋代碼：
  - `RuneType.earthquake`
  - `RuneType.columnBreaker`
  - `RuneType.timeSlow`
  - `RuneType.timeStop`
- ✅ 清理 switch 語句，提升可讀性
- ✅ 代碼可通過 git history 找回
- ✅ flutter analyze 無錯誤

**影響**：✅ 無邏輯變化，清理代碼，減少 8 行過時註釋

**完成時間**：2025-10-23

---

#### 優化 11：統一調試日誌前綴格式 ✅ 已完成

**位置**：各個檔案的 `debugPrint` 調用

**問題**：
```dart
debugPrint('[FlameBurst] ...');          // 使用方括號
debugPrint('RuneSystem: ...');           // 使用冒號
debugPrint('GameState: ...');            // 使用冒號
debugPrint('[GravityReset] ...');        // 使用方括號
```

**實施結果**：
- ✅ 統一使用方括號格式：`debugPrint('[ClassName] message')`
- ✅ 批量替換 60+ 處 debugPrint 調用
- ✅ 涉及檔案：
  - `lib/game/piece_provider.dart`
  - `lib/game/monotonic_timer.dart`
  - `lib/game/game_logic.dart`
  - `lib/game/game_state.dart`
  - `lib/game/game_board.dart`
  - `lib/game/rune_batch_processor.dart`
  - `lib/game/rune_energy_manager.dart`
  - `lib/game/rune_system.dart`
  - `lib/core/game_persistence.dart`
  - `lib/services/scoring_service.dart`
- ✅ flutter analyze 無錯誤

**影響**：✅ 無邏輯變化，提升日誌可讀性和一致性

**完成時間**：2025-10-23

---

#### 優化 12：優化列表複製性能 ✅ 已完成

**位置**：`lib/core/game_persistence.dart:187-192, 196-201`

**問題**：
```dart
// 雙重 map + toList() 產生中間列表
return board.map((row) => row.map(...).toList()).toList();
```

**實施方案**：
使用 `List.generate` 避免中間列表分配：
```dart
return List<List<int>>.generate(
  board.length,
  (i) => List<int>.generate(
    board[i].length,
    (j) {
      final color = board[i][j];
      return color == null ? -1 : (_colorToInt[color] ?? 0);
    },
  ),
);
```

**實施結果**：
- ✅ 優化 `_boardToIntList()` 方法
- ✅ 優化 `_intListToBoard()` 方法
- ✅ 減少中間列表分配，提升性能
- ✅ 代碼更清晰，使用索引而非迭代器
- ✅ flutter analyze 無錯誤

**影響**：✅ 無邏輯變化，性能提升（減少記憶體分配）

**完成時間**：2025-10-23

---

#### 優化 13：提取 Color 映射表到獨立檔案 ✅ 已完成

**位置**：`lib/core/game_persistence.dart:16-35`

**問題**：
Color 映射表定義冗長，且顏色值與 `tetromino.dart` 重複。

**實施方案**：
創建 `lib/theme/tetromino_colors.dart` 統一管理：
```dart
class TetrominoColors {
  static const Color I = Color(0xFF00E5FF);
  static const Color J = Color(0xFF0066FF);
  // ... 其他顏色定義

  static final Map<Color, int> colorToInt = { I: 1, J: 2, ... };
  static const Map<int, Color> intToColor = { 1: I, 2: J, ... };
}
```

**實施結果**：
- ✅ 創建 `lib/theme/tetromino_colors.dart`
- ✅ 定義 7 種 Tetromino 顏色常數
- ✅ 提供 `colorToInt` 和 `intToColor` 映射表
- ✅ 移除 `game_persistence.dart` 中 24 行重複定義
- ✅ 更新所有引用處使用新的映射表
- ✅ 提升可維護性，避免顏色值不一致
- ✅ flutter analyze 無錯誤
- ✅ flutter build 成功

**影響**：✅ 無邏輯變化，提升可維護性，減少重複代碼

**完成時間**：2025-10-23

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
| 優先級 2（中） | 7 | 7 ✅ | 0 | 已完成 |
| 優先級 3（低） | 14+ | 0 | 14+ | ~4 小時 |
| **總計** | **27+** | **13** | **14+** | **~4 小時** |

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

### 2025-10-23
- 🎉 **完成優先級 2 全部 7 項優化（100%）**

#### 第一批（優化 7-10）
- **優化 7**：提取棋盤座標計算邏輯
  - 📁 新增 `lib/game/board_constants.dart`
  - 🔧 優化 4 處重複計算，避免循環依賴
- **優化 8**：統一空值安全模式
  - 🔧 重構 7 個方法，消除強制解包操作符
- **優化 9**：移除未使用的導入
  - 🧹 清理 1 個 flutter analyze 警告
- **優化 10**：清理過時註釋
  - 🧹 移除 8 行過時代碼

#### 第二批（優化 11-13）
- **優化 11**：統一調試日誌前綴格式
  - 📝 統一 60+ 處 debugPrint 為方括號格式
  - 🎯 涉及 10 個檔案
- **優化 12**：優化列表複製性能
  - ⚡ 使用 List.generate 替代 map+toList
  - 🚀 減少中間列表分配，提升性能
- **優化 13**：提取 Color 映射表到獨立檔案
  - 📁 新增 `lib/theme/tetromino_colors.dart`
  - 🔧 移除 24 行重複定義
  - ✅ 統一顏色管理，避免不一致

### 2025-10-22
- ✅ 完成優先級 1 全部 6 項優化
- ✅ Commit `23a6578` 已推送到 GitHub
- 📊 減少 50 行重複代碼
- 📊 消除 1 個 flutter analyze 警告
- 📊 提升文檔覆蓋率

### 下次更新
- 可選：實施優先級 3 的優化項目（14 項低優先級優化）
- 主要優化工作已完成！

---

**最後更新**：2025-10-23
**文檔版本**：v2.0
**負責人**：Claude Code
**狀態**：✅ 優先級 1-2 已全部完成（13/13，100%），優先級 3 待實施
