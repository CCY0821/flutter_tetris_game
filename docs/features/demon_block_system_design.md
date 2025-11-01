# 惡魔方塊系統設計文檔
**版本**: 2.0
**建立日期**: 2025-10-28
**最後更新**: 2025-11-01
**狀態**: 待開發（規格已確定）

---

## 📋 目錄
1. [系統概述](#系統概述)
2. [核心需求](#核心需求)
3. [技術規格](#技術規格)
4. [開發階段](#開發階段)
5. [測試計劃](#測試計劃)
6. [未來擴展](#未來擴展)

---

## 系統概述

### 🎯 設計目標
在現有遊戲模式中加入動態難度系統，透過「惡魔方塊」機制提升挑戰性與獎勵回饋：
- **挑戰**: 10格隨機形狀方塊，難以放置
- **獎勵**: 成功放置後10秒內分數×3倍
- **漸進難度**: 隨著分數增長，觸發頻率加快

### 🎮 核心特性
- ✅ 洪水填充隨機生成（5×5範圍，10格連續）
- ✅ 加速式觸發曲線（指數增長）
- ✅ 標準 SRS 旋轉系統擴展
- ✅ 金底紅邊徑向漸層視覺
- ✅ 幽靈方塊輔助預覽
- ✅ 紅色脈動預警系統
- ✅ 分數加成計時器

---

## 核心需求

### 1️⃣ 方塊生成規則

#### 演算法：洪水填充法（Flood Fill）
```
輸入：無（純隨機生成）
輸出：10格連續方塊，限制在5×5範圍內

步驟：
1. 初始化 5×5 空白網格
2. 設置起點 (2, 2) 為第一格
3. 重複執行 9 次（共10格）：
   a. 從現有方塊中隨機選一個
   b. 找出其四周空格（上下左右）
   c. 隨機選擇一個空格作為新格（均等機率 25%）
   d. 確保不超出 5×5 邊界
4. 驗證連通性（所有格子互相連接）
5. 驗證可放置性（能在空棋盤上至少有一個位置放置）
6. 如果驗證失敗則重新生成（最多重試10次）
7. 如果10次都失敗，返回降級方案（2×5 矩形）

約束條件：
- 所有格子必須連續（不允許分離）
- 邊界框不超過 5×5
- 寬度不超過棋盤寬度（10格）
- 惡魔方塊無法旋轉，僅支援左右移動
```

#### 智能驗證機制
```dart
// 確保生成的方塊可在空棋盤上放置
static bool _canBePlacedOnEmptyBoard(List<List<bool>> shape) {
  final shapeWidth = shape[0].length;
  final boardWidth = 10;

  // 檢查方塊寬度是否超過棋盤
  if (shapeWidth > boardWidth) {
    return false;
  }

  return true; // 5×5 限制已確保高度安全
}
```

#### 降級方案
```
如果 10 次生成都無法通過驗證：
- 返回固定的 2×5 矩形方塊
- 確保遊戲不會因生成失敗而卡住
```

---

### 2️⃣ 觸發機制

#### 加速式難度曲線
```
公式：Score ≥ 10,000 × (n^1.2)
其中 n = 當前遊戲中已觸發次數（1-based）
最大次數：15 次（防止後期過度頻繁）

觸發時機表：
┌────┬─────────┬──────────────┐
│ 次數│ 分數門檻 │ 對應關卡（估算）│
├────┼─────────┼──────────────┤
│  1 │  10,000 │ Level 8-10   │
│  2 │  23,097 │ Level 18     │
│  3 │  39,189 │ Level 28     │
│  4 │  58,032 │ Level 38     │
│  5 │  79,432 │ Level 48     │
│  6 │ 103,246 │ Level 58     │
│  7 │ 129,358 │ Level 68     │
│  8 │ 157,678 │ Level 78     │
│  9 │ 188,132 │ Level 88     │
│ 10 │ 220,659 │ Level 98     │
│ 11 │ 255,103 │ Level 108    │
│ 12 │ 291,413 │ Level 118    │
│ 13 │ 329,543 │ Level 128    │
│ 14 │ 369,451 │ Level 138    │
│ 15 │ 411,101 │ Level 148    │ ← 最後一次
└────┴─────────┴──────────────┘

實現邏輯：
- 在 GameState 中維護 demonSpawnCount（當前遊戲中的計數）
- 每次更新分數時檢查是否達到門檻
- 達到門檻且 demonSpawnCount < 15 時插入惡魔方塊
- 計數器 +1，計算下一個門檻
- Game Over 後計數器歸零（每局獨立難度）
```

---

### 3️⃣ 控制系統

#### 惡魔方塊移動規則
```
支援操作：
✅ 左移（Left）   - 每次移動 1 格
✅ 右移（Right）  - 每次移動 1 格
✅ 下移（Down）   - 軟降（Soft Drop）
✅ 硬降（Drop）   - 瞬間落到底部
❌ 旋轉（Rotate） - 無法旋轉

設計理由：
- 簡化實作（無需自定義 SRS Kick Table）
- 增加挑戰難度（玩家需根據生成形狀直接判斷）
- 避免複雜形狀旋轉後的邊界處理問題
```

#### 實現邏輯
```dart
class Tetromino {
  Tetromino rotate(bool clockwise) {
    if (type == TetrominoType.DEMON) {
      return this; // 惡魔方塊不旋轉，返回自身
    }
    return _rotateStandard(clockwise);
  }
}
```

#### UI 控制處理（可選）
```
方案 A：旋轉按鈕禁用
- 檢測當前方塊類型
- 如果是 DEMON，按鈕變灰色
- 點擊無反應

方案 B：保持啟用但無效果
- 按鈕正常顯示
- 點擊時播放提示音效
- 顯示短暫提示「惡魔方塊無法旋轉」

建議使用方案 A（更直觀）
```

---

### 4️⃣ 視覺效果

#### 方塊渲染（徑向漸層）
```
每一格繪製規格：
- 中心顏色：金色 #FFD700
- 邊緣顏色：深紅 #DC143C
- 漸層方式：徑向漸層（Radial Gradient）
  - 從格子中心點開始
  - 向四邊線性過渡
  - 半徑 = min(cellWidth, cellHeight) / 2
- 邊框：2px 實線，顏色 #8B0000

繪製程式碼參考（偽代碼）：
Paint paint = Paint()
  ..shader = RadialGradient(
    center: Alignment.center,
    colors: [Color(0xFFFFD700), Color(0xFFDC143C)],
    stops: [0.0, 1.0],
  ).createShader(cellRect);
```

#### 幽靈方塊預覽
```
功能：顯示當前方塊的落點預覽

實現邏輯：
1. 複製當前方塊（保持相同旋轉狀態）
2. 模擬硬降（Hard Drop）到底部
3. 在落點位置繪製半透明版本

樣式規格：
- 正常方塊：原色彩 + opacity: 0.3
- 惡魔方塊：保持金紅漸層 + opacity: 0.4
- 邊框虛線化（可選）

適用範圍：所有方塊（非僅惡魔方塊）

惡魔方塊特殊處理：
- 由於惡魔方塊無法旋轉
- 幽靈預覽僅顯示「當前方向」的直降落點
- 無需考慮旋轉後的預覽計算
- 簡化實作邏輯

程式碼範例：
Tetromino? _calculateGhostPiece() {
  if (currentPiece == null) return null;

  Tetromino ghost = currentPiece!.copy();

  // 模擬硬降（惡魔方塊保持原方向）
  while (_canMove(ghost, 0, 1)) {
    ghost = ghost.moveDown();
  }

  return ghost;
}
```

#### Next Piece 預警系統
```
觸發條件：下一個方塊為惡魔方塊

視覺效果：
1. 紅色脈動光環
   - 週期：1.0 秒
   - Opacity 範圍：0.5 ↔ 1.0
   - 顏色：#FF0000
   - 半徑：方塊邊界外擴 8px

2. 警告文字
   - 內容：「⚠️ 惡魔方塊」
   - 顏色：紅色 #DC143C
   - 字體：粗體，16px
   - 位置：Next Piece 下方居中

實現方式：
- 使用 AnimationController（循環動畫）
- 在 TouchControls Widget 中檢測 nextPiece.type
```

---

### 4️⃣ 分數加成系統

#### 計時器邏輯
```
觸發時機：惡魔方塊放置到底部（lockDelay 結束）

執行流程：
1. 檢測方塊類型是否為 DEMON
2. 啟動 10 秒計時器
3. 設置 GameState.scoreMultiplier = 3.0
4. 所有消除分數計算：finalScore = baseScore × multiplier
5. 10 秒後恢復 multiplier = 1.0

影響範圍：
- 單行消除：100 → 300
- 雙行消除：300 → 900
- 三行消除：500 → 1500
- 四行消除（Tetris）：800 → 2400
- 連擊加成（Combo）：也乘以 multiplier
```

#### 疊加規則
```
場景：10 秒加成期間內，再次放置惡魔方塊

處理方式：時間疊加
- 計算當前剩餘時間（remaining）
- 新的結束時間 = 現在 + remaining + 10 秒
- 最大可累積約 30 秒（連續放置 3 個惡魔方塊）

實現程式碼：
if (multiplierEndTime != null && now.isBefore(multiplierEndTime!)) {
  final remaining = multiplierEndTime!.difference(now);
  multiplierEndTime = now.add(remaining + Duration(seconds: 10));
} else {
  multiplierEndTime = now.add(Duration(seconds: 10));
}
```

#### 暫停處理
```
玩家暫停遊戲時的行為：
1. 計時器暫停（不繼續倒數）
2. 儲存剩餘時間到 _pausedMultiplierRemaining
3. 恢復遊戲時，從剩餘時間繼續倒數

設計理由：
- 公平性：暫停不應消耗加成時間
- 符合玩家預期

實現程式碼：
void pauseGame() {
  if (multiplierEndTime != null) {
    _pausedMultiplierRemaining = multiplierEndTime!.difference(DateTime.now());
  }
}

void resumeGame() {
  if (_pausedMultiplierRemaining != null) {
    multiplierEndTime = DateTime.now().add(_pausedMultiplierRemaining!);
    _pausedMultiplierRemaining = null;
  }
}
```

#### UI 顯示
```
位置：螢幕頂部（分數下方）

元素：
1. 圖示：🔥 火焰 emoji
2. 文字：「三倍加成」
3. 倒數計時：「9.5s」（疊加時可能顯示 "18.2s"）
4. 進度條：
   - 寬度：螢幕寬度 80%
   - 高度：4px
   - 顏色：紅到黃漸層
   - 動畫：從滿格（100%）遞減到空（0%）

特殊效果：
- 最後 3 秒：文字閃爍（0.5秒週期）
- 計時結束：淡出動畫（0.3秒）
- 疊加時：播放額外音效（可選）

疊加顯示範例：
- 第 1 個惡魔方塊：顯示 "10.0s"
- 5 秒後放置第 2 個：顯示 "15.0s"（5 + 10）
- 進度條自動調整總長度
```

---

## 技術規格

### 📦 新增/修改檔案清單

#### 新增檔案
```
lib/game/
├── demon_piece_generator.dart    # 洪水填充演算法 + 智能驗證
├── demon_spawn_manager.dart      # 觸發邏輯管理（15次上限）
└── multiplier_timer_widget.dart  # 加成計時器 UI（支援疊加顯示）
```

#### 修改檔案
```
lib/game/
├── tetromino_definitions.dart    # 新增 DEMON 枚舉
├── tetromino.dart                # 支援 5×5 矩陣 + 旋轉邏輯（惡魔方塊返回自身）
├── game_state.dart               # 新增狀態欄位 + 暫停處理
├── game_logic.dart               # 整合觸發與加成 + 疊加邏輯
├── piece_provider.dart           # 插入惡魔方塊邏輯
├── tetromino_painter.dart        # 徑向漸層渲染
└── touch_controls.dart           # 預警動畫 + 幽靈方塊 + 旋轉按鈕禁用（可選）

lib/scoring/
└── scoring.dart                  # 乘數計算邏輯
```

#### 移除的檔案
```
❌ lib/utils/demon_kick_tables.dart  # 惡魔方塊不旋轉，無需 Kick Table
```

---

### 🔧 核心類別設計

#### DemonPieceGenerator
```dart
class DemonPieceGenerator {
  /// 使用洪水填充生成 10 格隨機方塊
  static List<List<bool>> generateShape({
    int maxWidth = 5,
    int maxHeight = 5,
    int targetCells = 10,
    int maxRetries = 10,
  }) {
    for (int retry = 0; retry < maxRetries; retry++) {
      final shape = _floodFillGenerate(maxWidth, maxHeight, targetCells);
      if (_isConnected(shape) && _canBePlacedOnEmptyBoard(shape)) {
        return shape;
      }
    }
    // 降級方案：返回 2×5 矩形
    return _generateFallbackShape();
  }

  /// 驗證形狀連通性
  static bool _isConnected(List<List<bool>> grid);

  /// 驗證方塊可在空棋盤上放置
  static bool _canBePlacedOnEmptyBoard(List<List<bool>> shape) {
    final shapeWidth = shape[0].length;
    return shapeWidth <= 10; // 棋盤寬度限制
  }

  /// 從現有方塊擴展一格（均等機率）
  static List<(int, int)> _getAvailableNeighbors(
    List<List<bool>> grid,
    List<(int, int)> existingCells,
  );

  /// 降級方案：2×5 矩形
  static List<List<bool>> _generateFallbackShape() {
    return [
      [true, true, true, true, true],
      [true, true, true, true, true],
    ];
  }
}
```

#### DemonSpawnManager
```dart
class DemonSpawnManager {
  static const int MAX_SPAWNS = 15; // 最大觸發次數

  int _spawnCount = 0;
  int _lastScore = 0;

  /// 計算下一個觸發門檻
  int getNextThreshold() {
    if (_spawnCount >= MAX_SPAWNS) {
      return -1; // 已達上限，返回無效值
    }
    return (10000 * pow(_spawnCount + 1, 1.2)).round();
  }

  /// 檢查是否應該生成惡魔方塊
  bool shouldSpawn(int currentScore) {
    if (_spawnCount >= MAX_SPAWNS) {
      return false; // 已達最大次數
    }

    if (currentScore >= getNextThreshold() && currentScore > _lastScore) {
      _lastScore = currentScore;
      _spawnCount++;
      return true;
    }
    return false;
  }

  /// 重置計數器（遊戲重新開始）
  void reset() {
    _spawnCount = 0;
    _lastScore = 0;
  }

  /// 獲取當前已觸發次數
  int get spawnCount => _spawnCount;
}
```

#### GameState 擴展
```dart
class GameState extends ChangeNotifier {
  // 新增欄位
  int demonSpawnCount = 0;      // 當前遊戲中已觸發次數
  double scoreMultiplier = 1.0; // 分數乘數（1.0 或 3.0）
  DateTime? multiplierEndTime;  // 加成結束時間
  Duration? _pausedMultiplierRemaining; // 暫停時儲存剩餘時間

  // 新增方法：啟動加成（支援疊加）
  void startScoreMultiplier({Duration duration = const Duration(seconds: 10)}) {
    final now = DateTime.now();

    if (multiplierEndTime != null && now.isBefore(multiplierEndTime!)) {
      // 當前仍在加成期間，疊加時間
      final remaining = multiplierEndTime!.difference(now);
      multiplierEndTime = now.add(remaining + duration);
    } else {
      // 加成已結束或未啟動，重新開始
      multiplierEndTime = now.add(duration);
    }

    scoreMultiplier = 3.0;
    notifyListeners();
  }

  // 檢查加成是否到期
  void checkMultiplierExpiry() {
    if (multiplierEndTime != null && DateTime.now().isAfter(multiplierEndTime!)) {
      scoreMultiplier = 1.0;
      multiplierEndTime = null;
      notifyListeners();
    }
  }

  // 暫停遊戲（暫停計時器）
  void pauseGame() {
    isPaused = true;
    if (multiplierEndTime != null) {
      _pausedMultiplierRemaining = multiplierEndTime!.difference(DateTime.now());
    }
    notifyListeners();
  }

  // 恢復遊戲（恢復計時器）
  void resumeGame() {
    isPaused = false;
    if (_pausedMultiplierRemaining != null) {
      multiplierEndTime = DateTime.now().add(_pausedMultiplierRemaining!);
      _pausedMultiplierRemaining = null;
    }
    notifyListeners();
  }

  // 重置遊戲（歸零計數器）
  void resetGame() {
    demonSpawnCount = 0;
    scoreMultiplier = 1.0;
    multiplierEndTime = null;
    _pausedMultiplierRemaining = null;
    // ...其他重置邏輯
    notifyListeners();
  }
}
```

#### Tetromino 擴展
```dart
class Tetromino {
  final TetrominoType type;
  List<List<bool>> shape; // 改為動態大小（支援 5×5）

  // 新增建構函式
  Tetromino.demon()
      : type = TetrominoType.DEMON,
        shape = DemonPieceGenerator.generateShape();

  // 簡化旋轉邏輯（惡魔方塊不旋轉）
  Tetromino rotate(bool clockwise) {
    if (type == TetrominoType.DEMON) {
      return this; // 惡魔方塊不旋轉，直接返回自身
    }
    return _rotateStandard(clockwise);
  }

  // 獲取邊界框（支援 5×5）
  Rect getBoundingBox() {
    int minX = shape[0].length;
    int minY = shape.length;
    int maxX = 0;
    int maxY = 0;

    for (int y = 0; y < shape.length; y++) {
      for (int x = 0; x < shape[y].length; x++) {
        if (shape[y][x]) {
          minX = min(minX, x);
          minY = min(minY, y);
          maxX = max(maxX, x);
          maxY = max(maxY, y);
        }
      }
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }
}
```

---

## 開發階段總覽

### 📊 25 個子階段任務清單

| 階段 | 子階段 | 任務名稱 | 預估時間 | 驗收標準 |
|------|--------|----------|----------|----------|
| **階段 1** | 1.1 | 新增 DEMON 枚舉與顏色定義 | 15 分鐘 | 枚舉存在且有顏色定義 |
| | 1.2 | 建立 DemonPieceGenerator 基礎架構 | 20 分鐘 | 能生成基本連續方塊 |
| | 1.3 | 實現驗證機制 | 25 分鐘 | 通過連通性與寬度驗證 |
| | 1.4 | 擴展 Tetromino 支援動態矩陣 | 30 分鐘 | demon() 能創建且無法旋轉 |
| | 1.5 | 單元測試與驗證 | 20 分鐘 | 所有單元測試通過 |
| **階段 2** | 2.1 | 實現 DemonSpawnManager 核心邏輯 | 20 分鐘 | 正確計算門檻值 |
| | 2.2 | 擴展 GameState 狀態管理 | 25 分鐘 | 正確管理加成狀態 |
| | 2.3 | 整合 DemonSpawnManager 到 GameState | 15 分鐘 | 達到門檻時觸發通知 |
| | 2.4 | 修改 PieceProvider 插入惡魔方塊 | 20 分鐘 | 下一個方塊變為 DEMON |
| | 2.5 | 實現計時器與單元測試 | 20 分鐘 | 所有單元測試通過 |
| **階段 3** | 3.1 | 實現惡魔方塊徑向漸層渲染 | 35 分鐘 | 顯示金紅漸層 |
| | 3.2 | 實現幽靈方塊預覽系統 | 40 分鐘 | 正確顯示所有方塊落點 |
| | 3.3 | 實現 Next Piece 預警動畫 | 30 分鐘 | DEMON 時顯示脈動預警 |
| | 3.4 | 創建分數加成計時器 UI | 45 分鐘 | 清晰顯示剩餘時間 |
| | 3.5 | 旋轉按鈕禁用與整合測試 | 20 分鐘 | 按鈕正確禁用 |
| **階段 4** | 4.1 | 整合分數乘數系統 | 25 分鐘 | 所有分數正確 ×3 |
| | 4.2 | 整合計時器到遊戲循環 | 20 分鐘 | 到期後立即恢復 |
| | 4.3 | 處理暫停與恢復邏輯 | 15 分鐘 | 不影響計時器準確性 |
| | 4.4 | 處理 Game Over 與重啟邏輯 | 20 分鐘 | 所有狀態正確重置 |
| | 4.5 | 邊界情況測試與修復 | 20 分鐘 | 所有邊界情況正確 |
| **階段 5** | 5.1 | 完整功能測試 | 35 分鐘 | 核心功能正常運作 |
| | 5.2 | 性能基準測試 | 25 分鐘 | 所有性能指標達標 |
| | 5.3 | 難度曲線平衡 | 40 分鐘 | 難度曲線符合預期 |
| | 5.4 | 邊界情況壓力測試 | 30 分鐘 | 穩定無崩潰 |
| | 5.5 | 最終驗收與文檔 | 20 分鐘 | 系統完整可發布 |

**總預估時間**: 7-10 小時

---

## 開發階段詳細說明

### 🚀 階段 1：核心數據結構（1.5-2小時）

#### 子階段拆解（5個子任務）

##### 1.1 新增 DEMON 枚舉與顏色定義（15分鐘）
- [ ] 1.1.1 在 `tetromino_definitions.dart` 新增 `TetrominoType.DEMON` 枚舉值
- [ ] 1.1.2 新增 DEMON 顏色定義（金色 `Color(0xFFFFD700)`）
- [ ] 1.1.3 在顏色 Map 中註冊 DEMON 類型
- [ ] 1.1.4 驗證枚舉可正確訪問
- **驗收**: `TetrominoType.DEMON` 枚舉存在且有顏色定義
- **測試**: 參考 `demon_block_test_plan.md` 第 1.1 節（3 個單元測試）

##### 1.2 建立 DemonPieceGenerator 基礎架構（20分鐘）
- [ ] 1.2.1 創建 `lib/game/demon_piece_generator.dart` 檔案
- [ ] 1.2.2 定義類別結構與公開 API（`generateShape` 方法簽名）
- [ ] 1.2.3 實現 `_floodFillGenerate` 洪水填充核心邏輯
- [ ] 1.2.4 實現 `_getAvailableNeighbors` 擴展方法（均等機率）
- **驗收**: 能夠生成基本的連續方塊（暫不驗證）

##### 1.3 實現驗證機制（25分鐘）
- [ ] 1.3.1 實現 `_isConnected` 連通性驗證（DFS/BFS）
- [ ] 1.3.2 實現 `_canBePlacedOnEmptyBoard` 智能驗證
- [ ] 1.3.3 實現 `_generateFallbackShape` 降級方案（2×5 矩形）
- [ ] 1.3.4 整合所有驗證到 `generateShape` 主方法（10次重試邏輯）
- **驗收**: 生成的方塊通過連通性與寬度驗證

##### 1.4 擴展 Tetromino 支援動態矩陣（30分鐘）
- [ ] 1.4.1 修改 `Tetromino` 類別支援動態 `List<List<bool>>` 大小
- [ ] 1.4.2 新增 `Tetromino.demon()` 建構函式（調用 DemonPieceGenerator）
- [ ] 1.4.3 修改 `rotate()` 方法（DEMON 類型返回自身）
- [ ] 1.4.4 更新 `getBoundingBox()` 方法支援 5×5 計算
- **驗收**: `Tetromino.demon()` 能成功創建且無法旋轉

##### 1.5 單元測試與驗證（20分鐘）
- [ ] 1.5.1 編寫測試：生成 100 次方塊，驗證都是 10 格
- [ ] 1.5.2 編寫測試：驗證所有生成的方塊連通
- [ ] 1.5.3 編寫測試：驗證方塊寬度不超過 10
- [ ] 1.5.4 編寫測試：驗證惡魔方塊旋轉返回自身
- [ ] 1.5.5 執行所有測試確保通過
- **驗收**: 所有單元測試通過

#### 階段 1 總驗收標準
- ✅ 能夠生成 10 格隨機方塊
- ✅ 所有生成的方塊形狀連續
- ✅ 方塊寬度不超過 10 格（可放置性驗證）
- ✅ 惡魔方塊無法旋轉（調用 rotate 返回自身）
- ✅ 單元測試覆蓋率 100%

---

### ⚡ 階段 2：觸發系統（1-2小時）

#### 子階段拆解（5個子任務）

##### 2.1 實現 DemonSpawnManager 核心邏輯（20分鐘）
- [ ] 2.1.1 創建 `lib/game/demon_spawn_manager.dart` 檔案
- [ ] 2.1.2 實現 `getNextThreshold()` 門檻計算（n^1.2，最大15次）
- [ ] 2.1.3 實現 `shouldSpawn()` 觸發檢測邏輯
- [ ] 2.1.4 實現 `reset()` 重置方法
- [ ] 2.1.5 新增 `spawnCount` getter
- **驗收**: DemonSpawnManager 能正確計算門檻值

##### 2.2 擴展 GameState 狀態管理（25分鐘）
- [ ] 2.2.1 在 `game_state.dart` 新增4個欄位（demonSpawnCount, scoreMultiplier, multiplierEndTime, _pausedMultiplierRemaining）
- [ ] 2.2.2 實現 `startScoreMultiplier()` 方法（支援疊加邏輯）
- [ ] 2.2.3 實現 `checkMultiplierExpiry()` 方法
- [ ] 2.2.4 修改 `pauseGame()` 與 `resumeGame()` 方法（計時器暫停邏輯）
- [ ] 2.2.5 修改 `resetGame()` 方法（歸零計數器）
- **驗收**: GameState 能正確管理加成狀態

##### 2.3 整合 DemonSpawnManager 到 GameState（15分鐘）
- [ ] 2.3.1 在 GameState 中創建 `_demonSpawnManager` 實例
- [ ] 2.3.2 在分數更新時調用 `_demonSpawnManager.shouldSpawn()`
- [ ] 2.3.3 觸發時發送通知給 GameLogic
- [ ] 2.3.4 在 resetGame 時調用 `_demonSpawnManager.reset()`
- **驗收**: 達到門檻時能正確觸發通知

##### 2.4 修改 PieceProvider 插入惡魔方塊（20分鐘）
- [ ] 2.4.1 在 `piece_provider.dart` 新增 `insertDemonPiece()` 方法
- [ ] 2.4.2 實現插入邏輯（插入到佇列頂部）
- [ ] 2.4.3 在 GameLogic 中監聽觸發通知
- [ ] 2.4.4 調用 `pieceProvider.insertDemonPiece()`
- [ ] 2.4.5 驗證下一個方塊確實為 DEMON
- **驗收**: 觸發時下一個方塊變為惡魔方塊

##### 2.5 實現計時器與單元測試（20分鐘）
- [ ] 2.5.1 在 GameLogic 中檢測方塊放置類型（lockPiece 方法）
- [ ] 2.5.2 如果是 DEMON，調用 `gameState.startScoreMultiplier()`
- [ ] 2.5.3 在遊戲循環中調用 `gameState.checkMultiplierExpiry()`
- [ ] 2.5.4 編寫測試：驗證前 15 個門檻值正確
- [ ] 2.5.5 編寫測試：驗證疊加邏輯與暫停邏輯
- **驗收**: 所有單元測試通過

#### 階段 2 總驗收標準
- ✅ 達到 10,000 分時自動生成惡魔方塊
- ✅ 最多觸發 15 次（第 16 次不再生成）
- ✅ 放置惡魔方塊後啟動 10 秒計時器
- ✅ 計時器期間分數正確 ×3
- ✅ 疊加邏輯正常（連續放置時時間累加）
- ✅ 暫停/恢復遊戲時計時器正確處理
- ✅ Game Over 後計數器歸零

---

### 🎨 階段 3：視覺效果（2.5-3小時）

#### 子階段拆解（5個子任務）

##### 3.1 實現惡魔方塊徑向漸層渲染（35分鐘）
- [ ] 3.1.1 在 `tetromino_painter.dart` 新增 `_paintDemonCell()` 方法
- [ ] 3.1.2 實現徑向漸層 Shader（金色 #FFD700 → 紅色 #DC143C）
- [ ] 3.1.3 實現深紅色邊框（#8B0000，2px）
- [ ] 3.1.4 在 `paint()` 方法中檢測 DEMON 類型並調用新方法
- [ ] 3.1.5 測試漸層效果（視覺確認）
- **驗收**: 惡魔方塊顯示金紅漸層與深紅邊框

##### 3.2 實現幽靈方塊預覽系統（40分鐘）
- [ ] 3.2.1 在 `touch_controls.dart` 新增 `_calculateGhostPiece()` 方法
- [ ] 3.2.2 實現硬降模擬邏輯（複製方塊後循環 moveDown）
- [ ] 3.2.3 實現幽靈方塊繪製（半透明 opacity: 0.3-0.4）
- [ ] 3.2.4 整合到主繪製流程（在當前方塊下方繪製）
- [ ] 3.2.5 測試所有方塊類型（包含 DEMON）
- **驗收**: 幽靈方塊正確顯示所有方塊的落點

##### 3.3 實現 Next Piece 預警動畫（30分鐘）
- [ ] 3.3.1 在 `touch_controls.dart` 新增 AnimationController（1.0秒週期）
- [ ] 3.3.2 檢測 nextPiece 是否為 DEMON
- [ ] 3.3.3 實現紅色脈動光環（Opacity 0.5 ↔ 1.0）
- [ ] 3.3.4 顯示警告文字「⚠️ 惡魔方塊」（紅色粗體）
- [ ] 3.3.5 測試動畫效果（視覺確認）
- **驗收**: Next Piece 為 DEMON 時顯示脈動預警

##### 3.4 創建分數加成計時器 UI（45分鐘）
- [ ] 3.4.1 創建 `lib/game/multiplier_timer_widget.dart` 檔案
- [ ] 3.4.2 實現倒數計時顯示（監聽 GameState.multiplierEndTime）
- [ ] 3.4.3 實現進度條動畫（紅到黃漸層，遞減效果）
- [ ] 3.4.4 實現最後 3 秒閃爍效果（0.5秒週期）
- [ ] 3.4.5 整合到遊戲 UI（分數下方）
- **驗收**: 計時器清晰顯示剩餘時間與進度條

##### 3.5 旋轉按鈕禁用與整合測試（20分鐘）
- [ ] 3.5.1 在 `touch_controls.dart` 檢測當前方塊類型
- [ ] 3.5.2 如果是 DEMON，旋轉按鈕變灰色（opacity: 0.5）
- [ ] 3.5.3 禁用旋轉按鈕點擊（ignorePointer）
- [ ] 3.5.4 整合測試所有視覺效果
- [ ] 3.5.5 性能測試（確保 60 FPS）
- **驗收**: 旋轉按鈕在惡魔方塊時正確禁用

#### 階段 3 總驗收標準
- ✅ 惡魔方塊顯示金紅漸層
- ✅ 幽靈方塊正確顯示落點（惡魔方塊無旋轉預覽）
- ✅ Next Piece 顯示預警特效
- ✅ 計時器 UI 清晰可見（疊加時顯示累計時間）
- ✅ 旋轉按鈕在惡魔方塊時禁用
- ✅ 所有動畫維持 60 FPS

---

### 🔍 階段 4：遊戲邏輯整合（1-2小時）

#### 子階段拆解（5個子任務）

##### 4.1 整合分數乘數系統（25分鐘）
- [ ] 4.1.1 在 `scoring.dart` 找到所有分數計算位置
- [ ] 4.1.2 修改單行/多行消除分數計算（乘以 scoreMultiplier）
- [ ] 4.1.3 修改連擊加成（Combo）分數計算
- [ ] 4.1.4 修改軟降/硬降分數計算
- [ ] 4.1.5 測試加成期間分數正確（手動驗證）
- **驗收**: 加成期間所有分數正確 ×3

##### 4.2 整合計時器到遊戲循環（20分鐘）
- [ ] 4.2.1 在 `game_logic.dart` 的 game loop 中調用 `checkMultiplierExpiry()`
- [ ] 4.2.2 確保每幀都檢查（或使用 Timer）
- [ ] 4.2.3 測試計時器精準度（誤差 < 100ms）
- [ ] 4.2.4 處理計時器到期時的 UI 更新
- [ ] 4.2.5 測試疊加情況下計時器正確性
- **驗收**: 計時器到期後立即恢復 multiplier = 1.0

##### 4.3 處理暫停與恢復邏輯（15分鐘）
- [ ] 4.3.1 驗證 `pauseGame()` 正確保存剩餘時間
- [ ] 4.3.2 驗證 `resumeGame()` 正確恢復計時器
- [ ] 4.3.3 測試暫停期間分數不累積
- [ ] 4.3.4 測試多次暫停/恢復的穩定性
- [ ] 4.3.5 處理暫停時 UI 顯示
- **驗收**: 暫停/恢復不影響計時器準確性

##### 4.4 處理 Game Over 與重啟邏輯（20分鐘）
- [ ] 4.4.1 在 Game Over 時調用 `gameState.resetGame()`
- [ ] 4.4.2 驗證 `demonSpawnCount` 歸零
- [ ] 4.4.3 驗證 `scoreMultiplier` 重置為 1.0
- [ ] 4.4.4 驗證 `_demonSpawnManager.reset()` 被調用
- [ ] 4.4.5 測試重啟後第一個惡魔方塊在 10,000 分觸發
- **驗收**: Game Over 後所有狀態正確重置

##### 4.5 邊界情況測試與修復（20分鐘）
- [ ] 4.5.1 測試連續放置 3 個惡魔方塊的疊加情況
- [ ] 4.5.2 測試在加成期間 Game Over 的處理
- [ ] 4.5.3 測試達到 15 次上限後不再觸發
- [ ] 4.5.4 測試記憶體洩漏（Timer 正確釋放）
- [ ] 4.5.5 修復發現的所有 bug
- **驗收**: 所有邊界情況正確處理

#### 階段 4 總驗收標準
- ✅ 加成期間分數計算正確
- ✅ 計時器到期後立即恢復正常
- ✅ 暫停/恢復不影響計時器
- ✅ 遊戲重啟後計數器歸零
- ✅ 所有邊界情況正確處理
- ✅ 無記憶體洩漏

---

### 🧪 階段 5：測試與平衡（2-3小時）

#### 子階段拆解（5個子任務）

##### 5.1 完整功能測試（35分鐘）
- [ ] 5.1.1 手動測試：從 0 分玩到第一個惡魔方塊（10,000 分）
- [ ] 5.1.2 驗證惡魔方塊生成形狀多樣性（重複生成 20 次）
- [ ] 5.1.3 驗證所有生成的形狀可放置（無極端情況）
- [ ] 5.1.4 驗證分數加成正確（×3）
- [ ] 5.1.5 記錄功能測試結果（截圖/影片）
- **驗收**: 所有核心功能正常運作

##### 5.2 性能基準測試（25分鐘）
- [ ] 5.2.1 測試惡魔方塊生成時間（應 < 50ms）
- [ ] 5.2.2 測試渲染幀率（FPS 監控，應維持 60 FPS）
- [ ] 5.2.3 測試記憶體使用（玩 30 分鐘，觀察記憶體趨勢）
- [ ] 5.2.4 測試計時器無記憶體洩漏（重複觸發 10 次）
- [ ] 5.2.5 優化性能瓶頸（如有）
- **驗收**: 所有性能指標達標

##### 5.3 難度曲線平衡（40分鐘）
- [ ] 5.3.1 測試第一個惡魔方塊出現時間（應在 5-8 分鐘）
- [ ] 5.3.2 測試連續觸發間隔（觀察 n^1.2 曲線是否合理）
- [ ] 5.3.3 調整觸發公式（如需要，改為 n^1.15 或 n^1.25）
- [ ] 5.3.4 測試 15 次上限是否合理（長時間遊戲體驗）
- [ ] 5.3.5 記錄最終平衡參數
- **驗收**: 難度曲線符合設計預期

##### 5.4 邊界情況壓力測試（30分鐘）
- [ ] 5.4.1 測試降級方案觸發頻率（10 次重試是否足夠）
- [ ] 5.4.2 測試連續 3 個惡魔方塊疊加（30 秒計時器）
- [ ] 5.4.3 測試加成期間暫停/恢復多次
- [ ] 5.4.4 測試達到 15 次上限後的行為
- [ ] 5.4.5 測試快速重啟遊戲（狀態清空）
- **驗收**: 所有邊界情況穩定無崩潰

##### 5.5 最終驗收與文檔（20分鐘）
- [ ] 5.5.1 執行完整遊戲流程（0 分 → Game Over）
- [ ] 5.5.2 記錄所有發現的 bug（如有）
- [ ] 5.5.3 更新設計文檔（標記實際參數）
- [ ] 5.5.4 創建測試報告（性能數據、平衡參數）
- [ ] 5.5.5 提交程式碼與文檔
- **驗收**: 系統完整可發布

#### 階段 5 總驗收標準
- ✅ 所有功能正常運作
- ✅ 無崩潰或卡頓
- ✅ 難度曲線合理（第一次觸發約 5-8 分鐘）
- ✅ 性能達標（生成 < 50ms，60 FPS）
- ✅ 無記憶體洩漏
- ✅ 所有邊界情況穩定
- ✅ 測試報告完成

---

## 測試方案

### 📋 測試總覽

完整的測試計劃請參考：**`docs/features/demon_block_test_plan.md`**

#### 測試類型分佈
| 測試類型 | 數量 | 工具 | 覆蓋階段 |
|---------|------|------|----------|
| 單元測試 | 50+ | `flutter test` | 階段 1-2 |
| 整合測試 | 8 | `flutter test integration_test/` | 階段 2-4 |
| 視覺測試 | 12 | 手動確認 + Golden Test | 階段 3 |
| 性能測試 | 5 | Flutter DevTools | 階段 5 |
| 壓力測試 | 5 | 手動 + 自動化 | 階段 5 |

**總測試數量**: 80+ 個具體測試案例

---

### 🎯 各階段測試要點

#### 階段 1：核心數據結構
```dart
// 關鍵測試
✅ test/tetromino_definitions_test.dart (3 個測試)
✅ test/demon_piece_generator_test.dart (4 個測試)
✅ test/demon_piece_generator_validation_test.dart (7 個測試)
✅ test/tetromino_demon_test.dart (5 個測試)
✅ test/demon_block_phase1_integration_test.dart (2 個測試)

// 驗收標準
- 生成時間 < 50ms
- 100 次生成全部通過驗證
- 方塊寬度 ≤ 10 格
- 惡魔方塊無法旋轉
```

#### 階段 2：觸發系統
```dart
// 關鍵測試
✅ test/demon_spawn_manager_test.dart (5 個測試)
✅ test/game_state_demon_test.dart (6 個測試)
✅ test/piece_provider_demon_test.dart (3 個測試)
✅ test/game_logic_demon_timer_test.dart (4 個測試)

// 驗收標準
- 前 15 個門檻值正確（誤差 ±10）
- 疊加邏輯：剩餘時間 + 10 秒
- 計時器精度 < 100ms
- 暫停/恢復保留剩餘時間
```

#### 階段 3：視覺效果
```markdown
// 關鍵測試
✅ testWidgets 惡魔方塊顯示金紅漸層（Golden Test）
✅ test/ghost_piece_test.dart (3 個測試)
✅ testWidgets Next Piece 為 DEMON 時顯示預警
✅ testWidgets 計時器 UI 顯示剩餘時間
✅ 手動視覺確認檢查表（12 項）

// 驗收標準
- 漸層正確：金色 #FFD700 → 紅色 #DC143C
- 幽靈方塊與硬降位置一致
- 預警動畫 1.0 秒週期
- FPS 維持 60
```

#### 階段 4：遊戲邏輯整合
```dart
// 關鍵測試
✅ test/scoring_multiplier_test.dart (5 個測試)
✅ test/game_loop_timer_test.dart (2 個測試)
✅ test/pause_resume_timer_test.dart (3 個測試)
✅ test/game_over_reset_test.dart (3 個測試)
✅ test/edge_cases_test.dart (4 個測試)

// 驗收標準
- 所有分數正確 ×3
- 計時器到期誤差 < 100ms
- 暫停不消耗時間
- Game Over 後所有狀態歸零
```

#### 階段 5：測試與平衡
```markdown
// 關鍵測試
✅ 完整功能測試（0 → Game Over）
✅ 性能基準測試（生成、FPS、記憶體）
✅ 難度曲線測試（第一次 5-8 分鐘）
✅ 壓力測試（降級率 < 1%）
✅ 最終驗收檢查表

// 驗收標準
- 生成時間 < 50ms
- FPS ≥ 60
- 記憶體增長 < 20 MB
- 無記憶體洩漏
- 形狀多樣性 > 10 種
```

---

### 🛠️ 測試執行指南

#### 開發階段測試
```bash
# 每完成一個子任務後執行
flutter test test/<對應測試檔案>.dart

# 階段完成後執行整合測試
flutter test test/demon_block_phase<N>_integration_test.dart

# 查看覆蓋率
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

#### 視覺測試
```bash
# 運行 app 進行手動測試
flutter run

# Golden test（視覺回歸測試）
flutter test --update-goldens  # 更新基準圖片
flutter test                    # 比對差異
```

#### 性能測試
```bash
# 啟動 profile 模式
flutter run --profile

# 打開 DevTools
flutter pub global activate devtools
flutter pub global run devtools

# 監控指標
- Performance: FPS、幀渲染時間
- Memory: 記憶體使用、洩漏檢測
```

---

### 📊 測試覆蓋率目標

| 類型 | 目標 | 工具 |
|------|------|------|
| 單元測試覆蓋率 | > 90% | `flutter test --coverage` |
| 核心功能測試 | 100% | 手動測試檢查表 |
| 整合測試 | 100% | `integration_test/` |
| 性能測試通過率 | > 80% | Flutter DevTools |

---

### 📝 測試文檔結構

```
docs/features/
├── demon_block_test_plan.md          # 完整測試計劃（本文檔引用）
│   ├── 階段 1 測試方案（15 個測試）
│   ├── 階段 2 測試方案（20 個測試）
│   ├── 階段 3 測試方案（12 個測試）
│   ├── 階段 4 測試方案（15 個測試）
│   ├── 階段 5 測試方案（18 個測試）
│   └── 測試報告模板

test/
├── tetromino_definitions_test.dart
├── demon_piece_generator_test.dart
├── demon_spawn_manager_test.dart
├── game_state_demon_test.dart
├── scoring_multiplier_test.dart
└── ... (50+ 測試檔案)

integration_test/
├── demon_block_phase1_integration_test.dart
├── demon_block_phase2_integration_test.dart
└── demon_block_full_flow_test.dart
```

---

### ✅ 測試檢查清單快速參考

詳細檢查清單請參考：**`docs/features/demon_block_task_checklist.md`**

**階段 1 測試**（21 個檢查項）
- [ ] 枚舉與顏色定義（3 項）
- [ ] 生成器基礎（4 項）
- [ ] 驗證機制（7 項）
- [ ] Tetromino 擴展（5 項）
- [ ] 性能測試（2 項）

**階段 2 測試**（25 個檢查項）
- [ ] DemonSpawnManager（5 項）
- [ ] GameState 狀態（6 項）
- [ ] 整合測試（4 項）
- [ ] PieceProvider（5 項）
- [ ] 計時器（5 項）

**階段 3 測試**（25 個檢查項）
- [ ] 徑向漸層（5 項）
- [ ] 幽靈方塊（5 項）
- [ ] 預警動畫（5 項）
- [ ] 計時器 UI（5 項）
- [ ] 按鈕禁用（5 項）

**階段 4 測試**（25 個檢查項）
- [ ] 分數乘數（5 項）
- [ ] 計時器循環（5 項）
- [ ] 暫停/恢復（5 項）
- [ ] Game Over（5 項）
- [ ] 邊界情況（5 項）

**階段 5 測試**（25 個檢查項）
- [ ] 功能測試（5 項）
- [ ] 性能測試（5 項）
- [ ] 難度平衡（5 項）
- [ ] 壓力測試（5 項）
- [ ] 最終驗收（5 項）

---

### 🎯 關鍵性能指標

| 指標 | 目標值 | 測試方法 |
|------|--------|----------|
| 惡魔方塊生成時間 | < 50ms | Stopwatch 測量 100 次平均 |
| 遊戲 FPS | ≥ 60 | DevTools Performance |
| 幀渲染時間 | < 16.67ms | DevTools Performance |
| 記憶體增長 | < 20 MB | DevTools Memory（30 分鐘遊玩） |
| 計時器精度 | < 100ms | DateTime 比對 |
| 降級方案觸發率 | < 1% | 1000 次生成統計 |
| 形狀多樣性 | > 10 種 | Hash 去重統計 |

---

### 🐛 Bug 追蹤與報告

發現 bug 時請記錄：
1. **Bug ID**: DEMON-XXX
2. **嚴重性**: P0/P1/P2/P3
3. **階段**: 1-5
4. **子任務**: X.Y.Z
5. **重現步驟**: 詳細描述
6. **預期行為**: 應該如何
7. **實際行為**: 實際發生什麼
8. **修復方案**: 如何修復

**Bug 報告範例**:
```markdown
Bug ID: DEMON-001
嚴重性: P1
階段: 2
子任務: 2.2.2
重現步驟:
1. 觸發惡魔方塊
2. 放置後等待 5 秒
3. 再次觸發並放置第二個惡魔方塊
預期行為: 計時器顯示 15 秒（5 + 10）
實際行為: 計時器顯示 10 秒（重置而非疊加）
修復方案: 修改 startScoreMultiplier() 疊加邏輯
```

---

### 📈 測試進度追蹤

使用 **`demon_block_task_checklist.md`** 追蹤測試進度：
- 總進度: 0/121 測試項（0%）
- 階段 1: 0/21 (0%)
- 階段 2: 0/25 (0%)
- 階段 3: 0/25 (0%)
- 階段 4: 0/25 (0%)
- 階段 5: 0/25 (0%)

每完成一個測試項目，在對應的檢查清單中打勾 `[x]`

---

### 🚀 測試執行時程

| 階段 | 開發時間 | 測試時間 | 總時間 |
|------|----------|----------|--------|
| 階段 1 | 1.5-2h | 30min | 2-2.5h |
| 階段 2 | 1-2h | 30min | 1.5-2.5h |
| 階段 3 | 2.5-3h | 45min | 3.25-3.75h |
| 階段 4 | 1-2h | 30min | 1.5-2.5h |
| 階段 5 | 2-3h | 1h | 3-4h |
| **總計** | **8-12h** | **3-4h** | **11-16h** |

**建議**: 邊開發邊測試，不要等到最後才測試

---

## 測試方案版本歷史

| 版本 | 日期 | 變更內容 |
|------|------|----------|
| 1.0 | 2025-11-01 | 初始測試方案，包含 80+ 測試案例 |

---

### 🎵 階段 6：音效整合（待後續）

#### 待添加音效
```
事件                    建議音效
─────────────────────────────────
惡魔方塊即將出現        低沉警告音（horn.wav）
惡魔方塊生成            邪惡笑聲（evil_laugh.wav）
惡魔方塊放置成功        史詩鼓點（epic_drum.wav）
×3 加成啟動             力量增強音（power_up.wav）
加成計時結束            能量消散音（fade_out.wav）
```

#### 音效庫建議
- **OpenGameArt.org**（CC0 授權）
- **Freesound.org**（需註明來源）
- **Zapsplat.com**（免費方案）

---

## 測試計劃

### 🧪 單元測試

#### DemonPieceGenerator 測試
```dart
test('生成的方塊必須是 10 格', () {
  final shape = DemonPieceGenerator.generateShape();
  int count = 0;
  for (var row in shape) {
    for (var cell in row) {
      if (cell) count++;
    }
  }
  expect(count, 10);
});

test('生成的方塊必須連續', () {
  final shape = DemonPieceGenerator.generateShape();
  expect(DemonPieceGenerator._isConnected(shape), true);
});

test('邊界框不超過 5×5', () {
  final shape = DemonPieceGenerator.generateShape();
  expect(shape.length, lessThanOrEqualTo(5));
  expect(shape[0].length, lessThanOrEqualTo(5));
});
```

#### DemonSpawnManager 測試
```dart
test('門檻值計算正確', () {
  final manager = DemonSpawnManager();
  expect(manager.getNextThreshold(), 10000);

  manager.shouldSpawn(10000);
  expect(manager.getNextThreshold(), closeTo(23097, 10));
});

test('重置後計數器歸零', () {
  final manager = DemonSpawnManager();
  manager.shouldSpawn(10000);
  manager.reset();
  expect(manager.getNextThreshold(), 10000);
});
```

---

### 🎮 整合測試

#### 完整流程測試
```
測試案例：惡魔方塊完整週期

前置條件：
- 遊戲正常運行
- 分數為 9,500

步驟：
1. 消除一行（分數達到 10,000+）
2. 觀察下一個方塊變為惡魔方塊
3. 確認 Next Piece 顯示紅色預警
4. 放置惡魔方塊
5. 確認計時器 UI 出現
6. 在 10 秒內消除一行
7. 確認分數正確×3
8. 等待計時器結束
9. 確認乘數恢復為 1.0

預期結果：
- ✅ 所有 UI 正確顯示
- ✅ 分數計算無誤
- ✅ 計時器精準
```

---

### 🐛 已知問題與注意事項

#### 已解決問題
```
✅ 極端形狀處理     - 通過智能驗證機制防護
✅ 加成疊加規則     - 採用時間疊加方案
✅ 暫停計時器行為   - 暫停時保存剩餘時間
✅ 旋轉系統複雜度   - 簡化為不可旋轉
```

#### 待驗證事項
```
優先級 | 問題描述                         | 狀態
──────┼──────────────────────────────┼──────
 P1   | 記憶體洩漏風險（Timer 未釋放）    | 待驗證
 P2   | 降級方案觸發頻率（10次重試）      | 待測試
 P3   | 疊加時間上限（是否需要限制）      | 待平衡
 P4   | 幽靈方塊性能（5×5 計算）          | 待優化
```

---

## 未來擴展

### 🎯 第二階段功能（可選）

#### 多種惡魔方塊
```
類型              格數  特殊效果
───────────────────────────────────
戰車型（Tank）    10   基礎型
螃蟹型（Crab）    12   橫向移動速度 ×1.5
惡魔王（Boss）    15   放置後 ×5 倍加成（5秒）
```

#### 成就系統
```
成就名稱              條件                  獎勵
────────────────────────────────────────────
惡魔獵人              放置 10 次惡魔方塊     解鎖金色主題
完美控制              惡魔方塊零失誤 5 次    解鎖特殊音效
速度惡魔              在 Level 50 前觸發     額外 10,000 分
```

#### 難度模式選擇
```
簡單模式：觸發公式改為 n^1.0（線性）
困難模式：觸發公式改為 n^1.5（極速增長）
```

---

### 📊 數據追蹤（可選）

如果未來需要分析，可記錄：
```dart
class DemonBlockStats {
  int totalSpawned = 0;           // 總觸發次數
  int successfulPlacements = 0;   // 成功放置次數
  int failedPlacements = 0;       // 失敗次數
  double avgPlacementTime = 0.0;  // 平均放置時間
  int totalBonusScore = 0;        // 加成期間獲得分數
}
```

---

## 附錄

### 🔧 開發環境需求
- Flutter SDK: >= 3.0.0
- Dart SDK: >= 3.0.0
- 相依套件：無新增（使用現有）

### 📚 參考資料
- [SRS 旋轉系統規範](https://tetris.wiki/Super_Rotation_System)
- [洪水填充演算法](https://en.wikipedia.org/wiki/Flood_fill)
- [Flutter 動畫最佳實踐](https://docs.flutter.dev/development/ui/animations)

### 🎨 設計資產需求
- 圖示：無需額外資產（程序生成）
- 音效：待後續添加（見階段 6）
- 字體：使用系統預設

---

## 文檔維護

**最後更新**: 2025-11-01
**更新者**: Claude Code
**變更日誌**:
- v2.0 (2025-11-01): 整合所有設計決策，移除待確認問題
  - ✅ 確認惡魔方塊無法旋轉（簡化實作）
  - ✅ 新增智能形狀驗證機制
  - ✅ 新增 15 次觸發上限
  - ✅ 新增分數加成疊加邏輯
  - ✅ 新增暫停計時器處理
  - ✅ 更新所有技術規格與開發階段
  - ❌ 移除 demon_kick_tables.dart 檔案
- v1.0 (2025-10-28): 初始版本，完整設計規格

**相關文檔**:
- 設計決策記錄：`docs/features/demon_block_decisions.md`
- 任務檢查清單：`docs/features/demon_block_task_checklist.md`
- 詳細測試計劃：`docs/features/demon_block_test_plan.md`
