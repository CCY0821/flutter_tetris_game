# 符文音效實作任務
**任務 ID**: RUNE-SOUND-001
**建立日期**: 2025-01-XX
**狀態**: ⏸️ 暫存中 - 等待用戶提供音效文件資訊

---

## 📋 任務描述

為每個符文的動畫觸發添加音效，提升遊戲沉浸感和用戶體驗。

---

## ✅ 已確認的需求

### **1. 音效方案**
- **選擇**: 方案 A - 每個符文獨特音效
- **數量**: 10 個符文音效文件

### **2. 音效文件準備狀態**
- **狀態**: 用戶已有符文音效文件
- **待確認**: 音效文件名稱列表和對應關係

### **3. 音效觸發時機**
- **時機**: 動畫開始時播放（與動畫同步）
- **位置**: 在每個 `_play*Animation()` 方法中添加

### **4. 音量控制**
- **方式**: 使用現有的音效音量設定（不需要獨立控制）

### **5. 特殊需求**
- **音效重疊**: 否（不需要處理）
- **音效優先級**: 否（不需要處理）
- **失敗音效**: 否（不需要處理）

---

## ⏳ 待確認資訊

### **必須確認**

#### **1. 音效文件列表**
請用戶提供現有音效文件名稱：
```bash
# 執行此命令獲取音效列表
dir assets\audio\*.mp3
```

#### **2. 符文音效對應關係**

| 符文名稱 | 符文 ID | 音效文件名 | 狀態 |
|---------|---------|-----------|------|
| 🔥 火焰爆裂 | flameBurst | ？ | ⏳ 待確認 |
| ⚡ 雷霆一擊（右） | thunderStrike | ？ | ⏳ 待確認 |
| ⚡ 雷霆一擊（左） | thunderStrikeLeft | ？ | ⏳ 待確認 |
| 😇 天使恩典 | angelsGrace | ？ | ⏳ 待確認 |
| ⏰ 時間扭曲 | timeChange | ？ | ⏳ 待確認 |
| ✨ 祝福連擊 | blessedCombo | ？ | ⏳ 待確認 |
| 🐉 龍吼 | dragonRoar | ？ | ⏳ 待確認 |
| 🔄 重力重置 | gravityReset | ？ | ⏳ 待確認 |
| 🏔️ 泰坦重力 | titanGravity | ？ | ⏳ 待確認 |
| 🔮 元素變形 | elementMorph | ？ | ⏳ 待確認 |

#### **3. 音效文件位置**
- [ ] `assets/audio/` （與現有音效同資料夾）
- [ ] `assets/audio/runes/` （獨立子資料夾）
- [ ] 其他路徑：`___________`

---

## 🔧 實作計畫

### **階段一：準備工作**
- [ ] 確認音效文件列表
- [ ] 確認符文音效對應關係
- [ ] 確認音效文件位置
- [ ] 檢查 `pubspec.yaml` 是否包含音效資源

### **階段二：代碼實作**
- [ ] 修改 `lib/game/game_board.dart`
- [ ] 在每個 `_play*Animation()` 方法中添加音效播放
- [ ] 實作音效對應邏輯

**預計修改的方法**（10 個）：
```dart
void _playFlameBurstAnimation() {
  if (_flameBurstAnimation == null || !_flameBurstAnimation!.isLoaded) return;

  // 🔊 新增：播放音效
  gameState.audioService.playSoundEffect('rune_flame_burst');

  widget.spellAnimationController.play(_flameBurstAnimation!);
}

// ... 其他 9 個方法
```

### **階段三：測試驗證**
- [ ] 測試每個符文音效是否正常播放
- [ ] 測試音效與動畫同步
- [ ] 測試音量控制是否生效
- [ ] 執行 `flutter analyze` 檢查代碼

### **階段四：文檔更新**
- [ ] 更新音效文件列表文檔
- [ ] 更新符文系統文檔
- [ ] 提交 Git commit

---

## 📂 相關文件

### **需要修改的文件**
- `lib/game/game_board.dart` (行 498-607)
  - 10 個 `_play*Animation()` 方法

### **可能需要修改的文件**
- `pubspec.yaml`（如音效資源未配置）
- `assets/audio/README.md`（添加符文音效說明）

---

## 🎯 實作範例

### **修改前**
```dart
void _playFlameBurstAnimation() {
  if (_flameBurstAnimation == null || !_flameBurstAnimation!.isLoaded) {
    debugPrint('[GameBoard] Flame Burst animation not ready');
    return;
  }

  debugPrint('[GameBoard] Playing Flame Burst animation');
  widget.spellAnimationController.play(_flameBurstAnimation!);
}
```

### **修改後**
```dart
void _playFlameBurstAnimation() {
  if (_flameBurstAnimation == null || !_flameBurstAnimation!.isLoaded) {
    debugPrint('[GameBoard] Flame Burst animation not ready');
    return;
  }

  // 🔊 播放符文音效
  gameState.audioService.playSoundEffect('rune_flame_burst');

  debugPrint('[GameBoard] Playing Flame Burst animation with sound effect');
  widget.spellAnimationController.play(_flameBurstAnimation!);
}
```

---

## 📝 音效命名建議

### **標準命名格式**
```
rune_{rune_id}.mp3
```

### **建議的音效文件名稱**
```
✅ rune_flame_burst.mp3
✅ rune_thunder_strike.mp3
✅ rune_thunder_strike_left.mp3
✅ rune_angels_grace.mp3
✅ rune_time_change.mp3
✅ rune_blessed_combo.mp3
✅ rune_dragon_roar.mp3
✅ rune_gravity_reset.mp3
✅ rune_titan_gravity.mp3
✅ rune_element_morph.mp3
```

**或者用戶自定義的名稱**（待確認）

---

## 🧪 測試指南

### **測試步驟**

1. **啟動遊戲**：
   ```bash
   flutter run
   ```

2. **測試每個符文**：
   - 累積能量至 3 格
   - 依序施放每個符文
   - 確認音效與動畫同步播放

3. **測試音量控制**：
   - 進入設定頁面
   - 調整音效音量
   - 確認符文音效音量隨之變化

4. **測試音效開關**：
   - 關閉音效
   - 確認符文音效不播放
   - 開啟音效
   - 確認符文音效恢復播放

### **預期結果**

| 測試項目 | 預期結果 |
|---------|---------|
| 音效播放 | ✅ 所有符文音效正常播放 |
| 動畫同步 | ✅ 音效與動畫同時開始 |
| 音量控制 | ✅ 符文音效遵循音效音量設定 |
| 音效開關 | ✅ 符文音效遵循音效開關狀態 |
| 無錯誤 | ✅ Console 無錯誤訊息 |

---

## ⚠️ 注意事項

### **可能的問題**

1. **音效文件未找到**：
   - 錯誤：`Error playing sound effect rune_xxx: ...`
   - 解決：檢查文件名稱和路徑是否正確

2. **音效延遲**：
   - 問題：音效比動畫晚播放
   - 解決：檢查 `audioService.playSoundEffect()` 的位置

3. **音效過大**：
   - 問題：符文音效太響亮
   - 解決：降低音效文件的音量（需要重新製作音效）

### **開發建議**

- ✅ 先測試一個符文音效，確認可行後再批量實作
- ✅ 使用統一的音效命名規範
- ✅ 在每個方法中添加詳細的調試日誌
- ✅ 測試時注意 Console 輸出

---

## 📞 恢復任務時需要的資訊

當用戶準備好繼續時，請提供：

1. **音效文件列表**（執行 `dir assets\audio\*.mp3` 的結果）
2. **符文音效對應關係**（哪個音效對應哪個符文）
3. **音效文件位置**（`assets/audio/` 或其他路徑）

提供以上資訊後，可以立即開始實作。

---

## 📊 任務狀態追蹤

- [x] 需求溝通完成
- [ ] 音效文件資訊確認
- [ ] 代碼實作完成
- [ ] 測試驗證通過
- [ ] 文檔更新完成
- [ ] Git commit 提交

---

**任務暫存時間**: 2025-01-XX
**預計恢復時間**: 待用戶提供音效文件資訊
**預計完成時間**: 資訊確認後 30-60 分鐘

---

**備註**: 所有實作都將嚴格遵守硬性前提：
- ❌ 不修改遊戲邏輯
- ❌ 不修改 UI 佈局
- ✅ 僅添加音效播放功能
