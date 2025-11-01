# 惡魔方塊系統 - 設計決策記錄

**文檔版本**: 1.0
**決策日期**: 2025-11-01
**狀態**: ✅ 已確認

---

## 📋 決策總覽

本文檔記錄惡魔方塊系統開發過程中所有關鍵設計決策及其理由。

---

## 1️⃣ 方塊生成規則

### Q1: 洪水填充擴展權重
**決策**: **A - 均等機率（上下左右各 25%）**

**理由**:
- 真正隨機化，增加方塊形狀多樣性
- 配合 Q-A 的智能驗證，可以過濾掉不可放置的極端形狀

**實作影響**:
```dart
// DemonPieceGenerator 中使用 Random().nextInt(4)
// 不需要設置偏好權重
```

---

### Q2: 極端形狀限制
**決策**: **確認 - 5×5 限制下不應出現 1×10 或 10×1 極端方塊**

**理由**:
- 棋盤寬度僅 10 格，1×10 長條幾乎無法放置
- 5×5 邊界框已經有效避免此類極端情況

**實作影響**:
- 邊界框驗證：`maxWidth = 5, maxHeight = 5`
- 生成演算法本身已防護

---

### Q-A: 極端形狀防護機制（新增）
**決策**: **B - 智能驗證：生成後測試是否能在空棋盤上放置**

**理由**:
- 惡魔方塊無法旋轉，極端形狀會導致無法放置
- 軟限制（3:2 比例）可能過於嚴格，減少變化性
- 智能驗證確保生成的每個方塊至少有一種可放置的情況

**實作方案**:
```dart
class DemonPieceGenerator {
  static List<List<bool>> generateShape() {
    for (int retry = 0; retry < 10; retry++) {
      final shape = _floodFillGenerate();
      if (_canBePlacedOnEmptyBoard(shape)) {
        return shape;
      }
    }
    // 降級方案：返回簡單的 2×5 矩形
    return _generateFallbackShape();
  }

  static bool _canBePlacedOnEmptyBoard(List<List<bool>> shape) {
    // 模擬在 10 寬的空棋盤上，測試所有橫向位置
    // 如果任一位置可容納（無超出邊界），返回 true
    final width = shape[0].length;
    final boardWidth = 10;
    return width <= boardWidth;
  }
}
```

---

## 2️⃣ 旋轉系統

### Q6 & Q7: 旋轉能力（重大變更）
**決策**: **惡魔方塊無法旋轉，僅支援左右移動和下降**

**理由**:
- 簡化實作（無需自定義 SRS Kick Table）
- 增加挑戰難度（玩家需根據生成形狀直接判斷放置位置）
- 避免複雜形狀旋轉後的邊界處理問題

**實作影響**:
```dart
// 移除計劃中的檔案
❌ lib/utils/demon_kick_tables.dart

// Tetromino.dart 中簡化邏輯
Tetromino rotate(bool clockwise) {
  if (type == TetrominoType.DEMON) {
    return this; // 不旋轉，直接返回自身
  }
  return _rotateStandard(clockwise);
}
```

**UI 控制調整**:
- 旋轉按鈕在惡魔方塊時變灰/禁用（可選）
- 或保持啟用但無實際效果（提示音效）

---

### Q-E: 旋轉中心（未來保留）
**決策**: **跳過 - 目前不實作旋轉功能**

**備註**: 如日後需要添加旋轉，建議使用 **A（固定 2,2）**，實作簡單

---

## 3️⃣ 觸發機制

### Q3: 遊戲重啟後計數器重置
**決策**: **是 - Game Over 後 demonSpawnCount 歸零**

**理由**:
- 每局遊戲獨立難度曲線
- 避免玩家因前一局進度而面對過高起始難度

**實作影響**:
```dart
class GameState {
  void resetGame() {
    demonSpawnCount = 0;
    _demonSpawnManager.reset();
    // ...其他重置邏輯
  }
}
```

---

### Q-B: 觸發最大次數（新增）
**決策**: **B - 上限 15 次**

**理由**:
- 避免後期過於頻繁（第 15 次門檻約 375,000 分）
- 平衡挑戰與可玩性
- 對應關卡約 Level 150+，已是長時間遊戲

**實作方案**:
```dart
class DemonSpawnManager {
  static const int MAX_SPAWNS = 15;

  bool shouldSpawn(int currentScore) {
    if (_spawnCount >= MAX_SPAWNS) {
      return false; // 達到上限，不再觸發
    }
    // ...原有邏輯
  }
}
```

---

## 4️⃣ 分數加成系統

### Q8: Game Over 處理
**決策**: **A - 無特殊處理（普通 Game Over）**

**理由**:
- 保持遊戲邏輯簡潔
- 惡魔方塊失敗與正常方塊失敗無本質區別

**實作影響**: 無額外邏輯

---

### Q-C: 加成疊加規則（新增）
**決策**: **B - 疊加時間（延長至剩餘時間 + 10 秒）**

**理由**:
- 獎勵玩家快速放置多個惡魔方塊
- 提供更刺激的遊戲體驗
- 計時器最多可累積至 30 秒（3 次惡魔方塊）

**實作方案**:
```dart
class GameState {
  void startScoreMultiplier() {
    final now = DateTime.now();
    if (multiplierEndTime != null && now.isBefore(multiplierEndTime!)) {
      // 當前仍在加成期間，疊加時間
      final remaining = multiplierEndTime!.difference(now);
      multiplierEndTime = now.add(remaining + Duration(seconds: 10));
    } else {
      // 加成已結束或未啟動，重新開始
      multiplierEndTime = now.add(Duration(seconds: 10));
    }
    scoreMultiplier = 3.0;
    notifyListeners();
  }
}
```

**UI 顯示**:
- 計時器顯示疊加後的總時間（例如 "18.5s"）
- 疊加時播放額外音效（可選）

---

### Q-D: 暫停期間計時器（新增）
**決策**: **B - 暫停計時（恢復遊戲後繼續剩餘時間）**

**理由**:
- 公平性：玩家暫停不應消耗加成時間
- 符合玩家預期（與其他遊戲行為一致）

**實作方案**:
```dart
class GameState {
  Duration? _pausedMultiplierRemaining;

  void pauseGame() {
    isPaused = true;
    if (multiplierEndTime != null) {
      _pausedMultiplierRemaining = multiplierEndTime!.difference(DateTime.now());
    }
  }

  void resumeGame() {
    isPaused = false;
    if (_pausedMultiplierRemaining != null) {
      multiplierEndTime = DateTime.now().add(_pausedMultiplierRemaining!);
      _pausedMultiplierRemaining = null;
    }
  }
}
```

---

## 5️⃣ 視覺效果

### Q10: 幽靈方塊啟用範圍
**決策**: **A - 所有方塊都有幽靈預覽**

**理由**:
- 提供友好的遊戲體驗
- 惡魔方塊因無法旋轉，更需要精確預覽
- 實作成本低（邏輯統一）

**實作影響**: 幽靈方塊系統適用於所有 TetrominoType

---

### Q-F: 幽靈方塊旋轉預覽（新增）
**決策**: **確認 - 惡魔方塊幽靈僅顯示「直接下降」的落點**

**理由**:
- 惡魔方塊無法旋轉，無需考慮旋轉後預覽
- 簡化實作邏輯

**實作方案**:
```dart
Tetromino? _calculateGhostPiece() {
  if (currentPiece == null) return null;

  // 複製當前方塊（保持相同旋轉狀態）
  Tetromino ghost = currentPiece!.copy();

  // 模擬硬降到底部
  while (_canMove(ghost, 0, 1)) {
    ghost = ghost.moveDown();
  }

  return ghost;
}
```

---

## 📊 決策影響總結

### 移除的計劃功能
- ❌ 惡魔方塊旋轉系統
- ❌ `demon_kick_tables.dart` 檔案
- ❌ 複雜的旋轉 UI 控制

### 新增的實作需求
- ✅ 智能形狀驗證（`_canBePlacedOnEmptyBoard`）
- ✅ 觸發次數上限（MAX_SPAWNS = 15）
- ✅ 加成時間疊加邏輯
- ✅ 暫停計時器處理

### 簡化的實作
- ✅ 旋轉邏輯（直接返回自身）
- ✅ 幽靈方塊預覽（無需旋轉計算）

---

## 🔄 版本歷史

| 版本 | 日期       | 變更內容                          |
|------|------------|-----------------------------------|
| 1.0  | 2025-11-01 | 初始版本，記錄所有設計決策        |

---

## 📝 備註

- 所有決策基於簡化實作與提升可玩性的原則
- 如需調整決策，請更新本文檔並同步修改 `demon_block_system_design.md`
- 實作過程中如發現決策衝突，優先以本文檔為準
