# 符文動畫調用完整指南

## 📋 概述

本指南詳細說明如何為符文添加全螢幕動畫效果，以 **Angel's Grace** 符文為範例。

---

## 🎯 Angel's Grace 動畫實現流程

### 1️⃣ 準備動畫資源

**檔案位置**: `assets/animations/angels_grace.png`

**格式要求**:
- **Sprite Sheet**: 4x4 網格（16 幀動畫）
- **尺寸**: 建議 960x1088 或類似比例
- **背景**: 必須是透明背景（PNG Alpha 通道）
- **顏色**: 藍紫色爆炸效果

**範例**:
```
┌────┬────┬────┬────┐
│ 1  │ 2  │ 3  │ 4  │  第一排：動畫開始
├────┼────┼────┼────┤
│ 5  │ 6  │ 7  │ 8  │  第二排：動畫中段
├────┼────┼────┼────┤
│ 9  │ 10 │ 11 │ 12 │  第三排：動畫高潮
├────┼────┼────┼────┤
│ 13 │ 14 │ 15 │ 16 │  第四排：動畫結束
└────┴────┴────┴────┘
```

---

### 2️⃣ 在 GameBoard 中定義動畫變數

**檔案**: `lib/game/game_board.dart`

**位置**: 在 `_GameBoardState` 類別中，約第 65 行

```dart
class _GameBoardState extends State<GameBoard>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {

  // 法術動畫控制器
  final SpellAnimationController _spellAnimationController =
      SpellAnimationController();

  // 👇 定義 Angel's Grace 動畫變數
  SpriteSheetAnimation? _angelsGraceAnimation;

  // 其他符文動畫變數可以在這裡添加
  // SpriteSheetAnimation? _flameBurstAnimation;
  // SpriteSheetAnimation? _thunderStrikeAnimation;
```

---

### 3️⃣ 在 initState 中載入動畫

**檔案**: `lib/game/game_board.dart`

**位置**: `_loadSpellAnimations()` 方法，約第 110-130 行

```dart
Future<void> _loadSpellAnimations() async {
  try {
    // 載入 Angel's Grace 動畫
    debugPrint('[GameBoard] Loading Angel\'s Grace animation...');

    // 👇 創建動畫實例
    _angelsGraceAnimation = SpriteSheetAnimation(
      assetPath: "assets/animations/angels_grace.png",  // 圖片路徑
      animationType: AnimationType.fadeInOut,           // 動畫類型

      // 淡入淡出參數
      fadeInDuration: const Duration(milliseconds: 200),   // 淡入 0.2s
      holdDuration: const Duration(milliseconds: 500),     // 停留 0.5s
      fadeOutDuration: const Duration(milliseconds: 200),  // 淡出 0.2s
    );

    // 👇 載入動畫資源
    await _angelsGraceAnimation!.load();

    debugPrint('[GameBoard] ✅ Angel\'s Grace animation loaded successfully');
  } catch (e, stackTrace) {
    debugPrint('[GameBoard] ❌ Failed to load spell animations: $e');
    debugPrint('[GameBoard] Stack trace: $stackTrace');
  }
}
```

**動畫類型說明**:
- `AnimationType.spriteSheet`: 逐幀播放 4x4 網格（適合連續動畫）
- `AnimationType.fadeInOut`: 淡入淡出效果（適合單張爆炸圖）

---

### 4️⃣ 創建播放動畫的方法

**檔案**: `lib/game/game_board.dart`

**位置**: 約第 300-310 行

```dart
/// 播放 Angel's Grace 爆炸動畫
void _playAngelsGraceAnimation() {
  // 👇 檢查動畫是否已載入
  if (_angelsGraceAnimation == null || !_angelsGraceAnimation!.isLoaded) {
    debugPrint('[GameBoard] Angel\'s Grace animation not ready');
    return;
  }

  debugPrint('[GameBoard] Playing Angel\'s Grace animation');

  // 👇 使用動畫控制器播放動畫
  _spellAnimationController.play(_angelsGraceAnimation!);
}
```

---

### 5️⃣ 監聽符文施法事件

**檔案**: `lib/game/game_board.dart`

**位置**: `_setupRuneEventListeners()` 方法，約第 220-230 行

```dart
void _setupRuneEventListeners() {
  debugPrint('[GameBoard] Setting up rune event listeners');

  // 監聽所有符文事件
  _runeEventSubscription = RuneEventBus.events.listen((event) {
    debugPrint('[GameBoard] Received rune event: ${event.runeType} - ${event.type}');

    if (!mounted) return;

    // 👇 監聽 Angel's Grace 施法事件，觸發動畫
    if (event.runeType == RuneType.angelsGrace &&
        event.type == RuneEventType.cast) {
      debugPrint('[GameBoard] Angel\'s Grace cast detected, triggering animation');
      _playAngelsGraceAnimation();  // 觸發動畫
    }

    // 其他符文事件監聽...
  });
}
```

---

### 6️⃣ 符文系統發送施法事件

**檔案**: `lib/game/rune_system.dart`

**位置**: `castRune()` 方法，約第 484 行

```dart
// 在符文施法時自動發送事件
RuneEventBus.emitCast(slot.runeType!);  // 👈 這會觸發動畫
```

**流程**:
```
玩家點擊符文槽
  → rune_system.dart: castRune()
  → RuneEventBus.emitCast(RuneType.angelsGrace)
  → game_board.dart: 監聽到事件
  → _playAngelsGraceAnimation()
  → 動畫顯示在螢幕上
```

---

## 🔧 為其他符文添加動畫

### 範例：Flame Burst 符文

#### 1. 準備圖片
```
assets/animations/flame_burst.png  (4x4 sprite sheet)
```

#### 2. 在 game_board.dart 定義變數
```dart
SpriteSheetAnimation? _flameBurstAnimation;
```

#### 3. 在 _loadSpellAnimations() 載入
```dart
_flameBurstAnimation = SpriteSheetAnimation(
  assetPath: "assets/animations/flame_burst.png",
  animationType: AnimationType.spriteSheet,  // 使用逐幀動畫
  rows: 4,
  columns: 4,
  frameDuration: const Duration(milliseconds: 60),  // 每幀 60ms
);
await _flameBurstAnimation!.load();
```

#### 4. 創建播放方法
```dart
void _playFlameBurstAnimation() {
  if (_flameBurstAnimation == null || !_flameBurstAnimation!.isLoaded) {
    debugPrint('[GameBoard] Flame Burst animation not ready');
    return;
  }
  _spellAnimationController.play(_flameBurstAnimation!);
}
```

#### 5. 在 _setupRuneEventListeners() 監聽
```dart
if (event.runeType == RuneType.flameBurst &&
    event.type == RuneEventType.cast) {
  _playFlameBurstAnimation();
}
```

---

## 📊 動畫參數對照表

### AnimationType.fadeInOut（淡入淡出）

| 參數 | 說明 | 推薦值 |
|------|------|--------|
| `fadeInDuration` | 淡入時長 | 200ms |
| `holdDuration` | 停留時長 | 500ms |
| `fadeOutDuration` | 淡出時長 | 200ms |

**總時長**: fadeIn + hold + fadeOut = 900ms

**適用場景**: 單張圖片爆炸效果、閃光效果

### AnimationType.spriteSheet（逐幀動畫）

| 參數 | 說明 | 推薦值 |
|------|------|--------|
| `rows` | 網格行數 | 4 |
| `columns` | 網格列數 | 4 |
| `totalFrames` | 總幀數 | 16 (預設 rows*columns) |
| `frameDuration` | 每幀時長 | 60ms |

**總時長**: frameDuration × totalFrames = 960ms

**適用場景**: 連續動畫、複雜特效

---

## 🎨 動畫資源製作建議

### 圖片規格
- **格式**: PNG 32-bit (含 Alpha 通道)
- **背景**: 完全透明
- **尺寸**: 960x1088 或 1920x1080
- **網格**: 4x4 均勻分割

### 視覺效果
- **起始幀**: 從小或淡開始
- **中段幀**: 逐漸放大/變亮
- **結束幀**: 淡出或縮小
- **顏色**: 避免使用綠色（以免誤判為綠幕）

### 製作工具
- Adobe After Effects → 導出序列幀 → 合併成 4x4 Sprite Sheet
- Spine / DragonBones → 導出 PNG 序列
- 線上工具: https://www.codeandweb.com/texturepacker

---

## 🐛 常見問題排查

### 1. 動畫不顯示

**檢查點**:
- [ ] 圖片是否放在 `assets/animations/` 目錄
- [ ] `pubspec.yaml` 是否包含 `assets/animations/`
- [ ] 圖片是否有 Alpha 通道（透明背景）
- [ ] 動畫是否成功載入（查看 Debug 日誌）
- [ ] 符文是否正確發送 `emitCast` 事件

**Debug 日誌範例**:
```
[GameBoard] Loading Angel's Grace animation...
[SpriteSheetAnimation] ✅ Loaded: assets/animations/angels_grace.png
[SpriteSheetAnimation] Size: 960x1088
[SpriteSheetAnimation] ✅ Format: RGBA (with alpha channel)
[GameBoard] ✅ Angel's Grace animation loaded successfully
```

### 2. 動畫有綠色殘留

**原因**: 圖片背景不是完全透明

**解決方案**:
- 使用圖片編輯器（Photoshop/GIMP）確保背景 Alpha = 0
- 或使用 `tools/chroma_key_processor_v2.dart` 去背（但已還原原始圖片，不需要）

### 3. 動畫播放太快/太慢

**調整參數**:
```dart
// 淡入淡出模式
fadeInDuration: const Duration(milliseconds: 300),  // 增加淡入時間
holdDuration: const Duration(milliseconds: 800),    // 增加停留時間

// 逐幀模式
frameDuration: const Duration(milliseconds: 80),    // 增加每幀時間
```

---

## 📁 相關檔案位置

### 核心檔案

| 檔案 | 功能 | 關鍵內容 |
|------|------|----------|
| `lib/game/game_board.dart` | 動畫載入與播放 | 第 65, 110-130, 220-230, 300-310 行 |
| `lib/game/spell_animation_controller.dart` | 動畫控制器 | 完整動畫邏輯 |
| `lib/game/rune_system.dart` | 符文施法邏輯 | 第 484 行發送事件 |
| `lib/game/rune_events.dart` | 事件系統 | 事件定義與 EventBus |

### 資源檔案

| 路徑 | 說明 |
|------|------|
| `assets/animations/angels_grace.png` | Angel's Grace 動畫圖片 |
| `assets/animations/flame_burst.png` | Flame Burst 動畫圖片（示例）|
| `assets/animations/thunder_strike_left.png` | Thunder Strike 左側動畫 |
| `assets/animations/thunder_strike_right.png` | Thunder Strike 右側動畫 |

---

## 🚀 快速套用清單

為新符文添加動畫的步驟：

- [ ] **1. 準備圖片**: 放到 `assets/animations/your_rune.png`
- [ ] **2. 定義變數**: `SpriteSheetAnimation? _yourRuneAnimation;`
- [ ] **3. 載入動畫**: 在 `_loadSpellAnimations()` 中添加載入邏輯
- [ ] **4. 創建播放方法**: `void _playYourRuneAnimation() { ... }`
- [ ] **5. 監聽事件**: 在 `_setupRuneEventListeners()` 中添加監聽
- [ ] **6. 測試**: 運行遊戲，觸發符文，確認動畫顯示

---

## 📚 延伸閱讀

- **Sprite Sheet 製作**: `docs/sprite_sheet_guide.md`（如果有）
- **符文系統架構**: `docs/troubleshooting/rune_system_debug.md`
- **動畫性能優化**: 確保圖片尺寸適中，避免過大影響性能

---

**最後更新**: 2025-01-18
**範例符文**: Angel's Grace
**適用版本**: v1.2.0+
