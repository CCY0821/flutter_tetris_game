# 🔧 符文冷卻系統 Bug 修復記錄

## 📅 修復日期
**2025-09-09** - Commit: `1ca5611`

## 🐛 問題現象
- ✅ **第一次累積能量**：符文槽正常亮起
- ❌ **冷卻結束後**：即使能量足夠，符文槽不會重新亮起

## 🔍 根本原因分析

### 1. **狀態更新缺失**
```dart
// 問題代碼 (touch_controls.dart:78-96)
_cooldownUpdateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
  // 檢查是否有任何符文槽在冷卻中
  bool hasAnyCooling = false;
  for (final slot in widget.gameState.runeSystem.slots) {
    if (slot.isCooling) { // ❌ 狀態可能是過期的
      hasAnyCooling = true;
      break;
    }
  }
  
  // 只有在有符文冷卻中時才更新UI
  if (hasAnyCooling) { // ❌ 冷卻結束時不會觸發
    setState(() {});
  }
});
```

### 2. **狀態更新時機問題**
- **問題**：Timer 只在 `hasAnyCooling = true` 時才調用 `setState()`
- **結果**：冷卻結束瞬間，`hasAnyCooling` 變為 `false`，UI 停止更新
- **影響**：符文槽狀態卡在 `cooling`，永遠不會轉為 `ready`

### 3. **UI 與核心狀態脫節**
- **UI 渲染時**：`runeSlot.canCast = false`（過期狀態）
- **核心狀態**：冷卻實際已結束，應該是 `ready`
- **結果**：UI 顯示暗淡，但實際可以施法

## ✅ 解決方案

### **修復代碼** (touch_controls.dart:78-98)
```dart
_cooldownUpdateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
  if (mounted) {
    // 檢查是否有任何符文槽在冷卻中
    bool hasAnyCooling = false;
    if (widget.gameState.hasRuneSystemInitialized) {
      for (final slot in widget.gameState.runeSystem.slots) {
        // 🔥 關鍵修復：每次檢查時都更新槽位狀態
        slot.update();
        if (slot.isCooling) {
          hasAnyCooling = true;
        }
      }
    }

    // 🔥 修復：無論是否有冷卻都要更新UI，確保狀態同步
    setState(() {
      // 冷卻倒數UI更新
    });
  }
});
```

### **修復要點**

#### 1. **強制狀態更新**
```dart
slot.update(); // 每秒調用，確保狀態及時從 cooling → ready
```

#### 2. **無條件 UI 更新**
```dart
setState(() {}); // 每秒都調用，不管有沒有冷卻
```

#### 3. **移除提前退出**
```dart
// 移除了 break; 讓所有槽位都能更新
```

## 🎯 修復位置
- **檔案**: `lib/game/touch_controls.dart`
- **方法**: `_startCooldownUpdateTimer()`
- **行數**: 78-98

## 💡 技術原理

### **狀態更新流程**
1. **Timer 每秒觸發** → 確保定期檢查
2. **調用 slot.update()** → 更新內部狀態
3. **狀態轉換** → `cooling` → `ready`
4. **調用 setState()** → 觸發 UI 重繪
5. **符文槽亮起** → UI 反映最新狀態

### **時間同步機制**
```dart
// RuneSlot.update() 內部邏輯
final cooldownRemainingMs = _getCooldownRemaining(now);
if (cooldownRemainingMs > 16) {
  state = RuneSlotState.cooling;
} else {
  state = RuneSlotState.ready; // 🔥 關鍵轉換
}
```

## 🔄 修復前後對比

| 項目 | 修復前 | 修復後 |
|------|--------|--------|
| **第一次能量累積** | ✅ 正常亮起 | ✅ 正常亮起 |
| **冷卻結束後** | ❌ 不會亮起 | ✅ 正常亮起 |
| **狀態同步** | ❌ UI 與核心脫節 | ✅ 完全同步 |
| **UI 更新頻率** | 僅冷卻時 | 每秒無條件 |
| **CPU 消耗** | 較低 | 略高但可接受 |

## 🚨 相關問題

### **可能的副作用**
1. **略增 CPU 消耗**：每秒都調用 `setState()`
2. **輕微性能影響**：每秒更新所有槽位狀態

### **預防措施**
```dart
if (mounted) { // 確保組件仍然掛載
  // 更新邏輯
}
```

## 🔧 測試驗證

### **測試步驟**
1. 啟動遊戲，累積能量至可施法
2. 施放符文，觀察符文槽變暗並開始倒數
3. 等待冷卻結束（8秒）
4. 確認符文槽重新亮起（如有足夠能量）

### **驗證結果** ✅
- 第一次能量累積：正常亮起
- 冷卻結束後：正常亮起
- 狀態同步：UI 與邏輯完全一致

## 📝 學習要點

1. **定期狀態同步**：UI 組件要定期更新狀態，不能只依賴事件觸發
2. **狀態管理**：複雜狀態系統需要主動同步機制
3. **UI 生命週期**：Timer 與組件生命週期要正確配合
4. **除錯策略**：通過日誌追蹤狀態變化找出問題根源

## 🔗 相關檔案
- `lib/game/touch_controls.dart` - UI 控制器與修復位置
- `lib/game/rune_system.dart` - 符文狀態邏輯
- `lib/game/monotonic_timer.dart` - 時間管理系統

---
**修復者**: Claude  
**測試者**: 用戶驗證  
**狀態**: ✅ 已修復並推送到 GitHub