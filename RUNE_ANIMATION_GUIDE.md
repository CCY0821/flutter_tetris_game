# 符文動畫調用完整指南

## 📋 概述

本指南詳細說明如何為符文添加**全 APP 覆蓋**動畫效果，以 **Angel's Grace** 和 **Flame Burst** 符文為範例。

**⚠️ 重要標準**:
1. 所有符文動畫統一使用 **fadeInOut** 模式（淡入淡出）
2. 資源為單張完整圖片，不使用 sprite sheet 分格動畫
3. **動畫覆蓋整個 APP 螢幕**（包含遊戲場和所有 UI 元素）
4. 動畫控制器在 `main.dart` 管理，傳遞給 `GameBoard`

---

## 🏗️ 架構總覽

### Widget 層級結構
```
main.dart
└── Stack
    ├── BackgroundPattern (背景裝飾)
    ├── SafeArea
    │   └── GameBoard (遊戲內容)
    │       └── 接收 spellAnimationController
    ├── ScanlineOverlay (掃描線效果)
    └── Positioned.fill (最上層)
        └── SpellAnimationOverlay ✨ (符文動畫 - 覆蓋整個 APP)
```

### 動畫觸發流程
```
玩家點擊符文槽
  ↓
rune_system.dart: RuneEventBus.emitCast()
  ↓
game_board.dart: 監聽到事件
  ↓
game_board.dart: widget.spellAnimationController.play()
  ↓
main.dart: SpellAnimationOverlay 顯示動畫
  ↓
全螢幕爆炸效果（覆蓋所有 UI）
```

---

## 🎯 Angel's Grace 動畫實現流程

### 1️⃣ 準備動畫資源

**檔案位置**: `assets/animations/angels_grace.png`

**格式要求**:
- **圖片類型**: 單張完整圖片（非 Sprite Sheet）
- **尺寸**: 建議 960x1088 或類似比例
- **背景**: 必須是透明背景（PNG Alpha 通道）
- **顏色**: 藍紫色爆炸效果
- **動畫方式**: 透過淡入淡出控制顯示

---

### 2️⃣ 在 GameBoard 中定義動畫變數

**檔案**: `lib/game/game_board.dart`

**位置**: 在 `_GameBoardState` 類別中，約第 65 行

**⚠️ 重要**: 動畫控制器現在由 `main.dart` 管理，`GameBoard` 只負責存儲動畫資源

```dart
class GameBoard extends StatefulWidget {
  final SpellAnimationController spellAnimationController; // 接收外部控制器

  const GameBoard({
    super.key,
    required this.spellAnimationController,
  });
}

class _GameBoardState extends State<GameBoard> {
  // 👇 只定義動畫資源變數（控制器由 main.dart 管理）
  SpriteSheetAnimation? _angelsGraceAnimation;
  SpriteSheetAnimation? _flameBurstAnimation;

  // 其他符文動畫變數可以在這裡添加
  // SpriteSheetAnimation? _thunderStrikeAnimation;
  // SpriteSheetAnimation? _dragonRoarAnimation;
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
- `AnimationType.fadeInOut`: 淡入淡出效果（**所有符文統一使用**）
- ~~`AnimationType.spriteSheet`: 逐幀播放 4x4 網格~~（已棄用）

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

  // 👇 使用外部傳入的控制器播放動畫
  widget.spellAnimationController.play(_angelsGraceAnimation!);
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
  → widget.spellAnimationController.play()
  → main.dart: SpellAnimationOverlay 顯示動畫
  → 全螢幕爆炸效果（覆蓋整個 APP）
```

---

### 7️⃣ 在 main.dart 設置全局動畫控制器和顯示層

**檔案**: `lib/main.dart`

**這是關鍵步驟！** 動畫顯示在整個 APP 層級，而非 GameBoard 內部。

#### A. 創建全局控制器

```dart
import 'game/spell_animation_controller.dart'; // 導入

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  // 👇 創建全局動畫控制器
  final SpellAnimationController _spellAnimationController =
      SpellAnimationController();

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _spellAnimationController.dispose(); // 清理控制器
    super.dispose();
  }
}
```

#### B. 傳遞控制器給 GameBoard

```dart
SafeArea(
  child: Center(
    child: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 👇 傳遞控制器給 GameBoard
            GameBoard(
              spellAnimationController: _spellAnimationController,
            ),
          ],
        ),
      ),
    ),
  ),
),
```

#### C. 添加全螢幕動畫疊加層（最上層）

```dart
home: Scaffold(
  body: Container(
    child: Stack(
      children: [
        BackgroundPattern(...),
        SafeArea(child: GameBoard(...)),
        ScanlineOverlay(),

        // 👇 全螢幕法術動畫疊加層（最上層，覆蓋所有 UI）
        Positioned.fill(
          child: SpellAnimationOverlay(
            controller: _spellAnimationController,
            visibleAreaTop: 0,
            visibleAreaHeight: MediaQuery.of(context).size.height,
            fit: BoxFit.cover, // 填滿螢幕
          ),
        ),
      ],
    ),
  ),
),
```

**重點說明**:
- ✅ `Positioned.fill`: 填滿整個 Stack（覆蓋所有內容）
- ✅ `visibleAreaHeight: MediaQuery.of(context).size.height`: 使用整個螢幕高度
- ✅ `fit: BoxFit.cover`: 填滿螢幕（可能裁切邊緣）
- ✅ 位於 Stack 最上層（在 ScanlineOverlay 之後）

---

## 🔧 為其他符文添加動畫

### 範例：Flame Burst 符文

**⚠️ 重要**: 添加新符文動畫時，**只需修改 `game_board.dart`**，`main.dart` 的全局動畫層已經配置好，無需再修改！

#### 1. 準備圖片
```
assets/animations/flame_burst.png  (單張完整圖片，透明背景)
```

#### 2. 在 game_board.dart 定義變數
```dart
SpriteSheetAnimation? _flameBurstAnimation;
```

#### 3. 在 _loadSpellAnimations() 載入
```dart
_flameBurstAnimation = SpriteSheetAnimation(
  assetPath: "assets/animations/flame_burst.png",
  animationType: AnimationType.fadeInOut,  // 使用淡入淡出模式
  fadeInDuration: const Duration(milliseconds: 200),  // 淡入 0.2s
  holdDuration: const Duration(milliseconds: 500),     // 停留 0.5s
  fadeOutDuration: const Duration(milliseconds: 200),  // 淡出 0.2s
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
  // 👇 使用外部控制器（會自動顯示在全螢幕）
  widget.spellAnimationController.play(_flameBurstAnimation!);
}
```

#### 5. 在 _setupRuneEventListeners() 監聽
```dart
if (event.runeType == RuneType.flameBurst &&
    event.type == RuneEventType.cast) {
  _playFlameBurstAnimation();
}
```

**就這麼簡單！** 動畫會自動在整個 APP 螢幕上顯示，覆蓋所有 UI 元素。

---

## 📊 動畫參數對照表

### ✅ AnimationType.fadeInOut（淡入淡出）- 所有符文統一使用

| 參數 | 說明 | 推薦值 | 可調範圍 |
|------|------|--------|---------|
| `fadeInDuration` | 淡入時長 | 200ms | 100-300ms |
| `holdDuration` | 停留時長 | 500ms | 300-800ms |
| `fadeOutDuration` | 淡出時長 | 200ms | 100-300ms |

**總時長**: fadeIn + hold + fadeOut = 900ms（推薦）

**適用場景**: 所有符文爆炸效果、閃光效果

**視覺效果時間軸**:
```
0ms ────── 200ms ────── 700ms ────── 900ms
  │           │            │            │
淡入開始    完全顯示    開始淡出     完全消失
```

### ❌ AnimationType.spriteSheet（已棄用）

~~此模式不再使用於符文動畫系統~~

---

## 🎨 動畫資源製作建議

### 圖片規格
- **格式**: PNG 32-bit (含 Alpha 通道)
- **背景**: 完全透明（Alpha = 0）
- **尺寸**: 960x1088 或 1920x1080（建議保持一致）
- **圖片類型**: 單張完整爆炸/特效圖

### 視覺效果
- **構圖**: 完整的爆炸或特效靜態圖
- **透明度**: 完全依賴 PNG Alpha 通道（不要用半透明灰色背景）
- **顏色**: 避免使用純綠色 #00FF00（Chroma Key 可能會誤判）
- **細節**: 可包含粒子、光芒、衝擊波等靜態元素

### 製作工具
- **Adobe Photoshop**: 創建爆炸/特效圖，確保背景透明
- **Adobe After Effects**: 渲染單幀特效（選擇最佳視覺瞬間）
- **Blender**: 3D 爆炸效果渲染（導出 PNG 序列選最佳幀）
- **線上資源**:
  - https://opengameart.org/ （免費遊戲素材）
  - https://kenney.nl/ （免費 2D/3D 素材）

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

**原因**: 圖片背景不是完全透明，或包含綠色像素

**解決方案**:
- 使用圖片編輯器（Photoshop/GIMP）確保背景 Alpha = 0
- 檢查圖片是否包含 #00FF00 純綠色（Chroma Key 會去除）
- 確認 PNG 格式為 32-bit RGBA

### 3. 動畫播放太快/太慢

**調整參數**:
```dart
// 播放較慢（更戲劇化）
fadeInDuration: const Duration(milliseconds: 300),  // 增加淡入時間
holdDuration: const Duration(milliseconds: 800),    // 增加停留時間
fadeOutDuration: const Duration(milliseconds: 300), // 增加淡出時間

// 播放較快（更爽快）
fadeInDuration: const Duration(milliseconds: 100),
holdDuration: const Duration(milliseconds: 300),
fadeOutDuration: const Duration(milliseconds: 100),
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

為新符文添加**全 APP 覆蓋**動畫的步驟（僅需修改 `game_board.dart`）：

### 一次性設置（已完成，不需重複）✅
- [x] **main.dart**: 創建全局 `SpellAnimationController`
- [x] **main.dart**: 傳遞 controller 給 `GameBoard`
- [x] **main.dart**: 添加 `Positioned.fill` + `SpellAnimationOverlay`

### 每個新符文需要做的事
- [ ] **1. 準備圖片**: 單張完整 PNG 圖片，放到 `assets/animations/your_rune.png`
- [ ] **2. 定義變數**: 在 `game_board.dart` 添加 `SpriteSheetAnimation? _yourRuneAnimation;`
- [ ] **3. 載入動畫**: 在 `_loadSpellAnimations()` 中使用 `fadeInOut` 模式載入
- [ ] **4. 創建播放方法**: `void _playYourRuneAnimation() { ... }`
- [ ] **5. 監聽事件**: 在 `_setupRuneEventListeners()` 中監聽施法事件
- [ ] **6. 測試**: 運行遊戲，觸發符文，確認動畫覆蓋整個 APP 螢幕

**標準模板代碼**（複製貼上後修改符文名稱）:
```dart
// ==================== game_board.dart ====================

// 步驟 2: 定義變數
SpriteSheetAnimation? _yourRuneAnimation;

// 步驟 3: 載入動畫（在 _loadSpellAnimations() 中）
_yourRuneAnimation = SpriteSheetAnimation(
  assetPath: "assets/animations/your_rune.png",
  animationType: AnimationType.fadeInOut,
  fadeInDuration: const Duration(milliseconds: 200),
  holdDuration: const Duration(milliseconds: 500),
  fadeOutDuration: const Duration(milliseconds: 200),
);
await _yourRuneAnimation!.load();

// 步驟 4: 播放方法
void _playYourRuneAnimation() {
  if (_yourRuneAnimation == null || !_yourRuneAnimation!.isLoaded) {
    debugPrint('[GameBoard] Your Rune animation not ready');
    return;
  }
  debugPrint('[GameBoard] Playing Your Rune animation');
  widget.spellAnimationController.play(_yourRuneAnimation!); // 使用外部控制器
}

// 步驟 5: 監聽事件（在 _setupRuneEventListeners() 中）
if (event.runeType == RuneType.yourRune &&
    event.type == RuneEventType.cast) {
  _playYourRuneAnimation();
}
```

**重點**:
- ✅ 使用 `widget.spellAnimationController`（外部控制器）
- ✅ 動畫會自動在 `main.dart` 的全螢幕層顯示
- ✅ 無需修改 `main.dart`

---

## 📚 延伸閱讀

- **Sprite Sheet 製作**: `docs/sprite_sheet_guide.md`（如果有）
- **符文系統架構**: `docs/troubleshooting/rune_system_debug.md`
- **動畫性能優化**: 確保圖片尺寸適中，避免過大影響性能

---

---

## 📝 已實現的符文動畫清單

| 符文名稱 | 動畫文件 | 實現狀態 | 動畫模式 | 備註 |
|---------|---------|---------|---------|------|
| Angel's Grace | `angels_grace.png` | ✅ 已完成 | fadeInOut | 藍紫色爆炸 |
| Flame Burst | `flame_burst.png` | ✅ 已完成 | fadeInOut | 火焰爆炸 |
| Thunder Strike | `thunder_strike_left.png`<br>`thunder_strike_right.png` | ✅ 已完成 | fadeInOut | 左右雷擊 |
| Dragon Roar | `dragon_roar.png` | ✅ 已完成 | fadeInOut | 龍吼效果 |
| Blessed Combo | `blessed_combo.png` | ✅ 已完成 | fadeInOut | 祝福光芒 |
| Gravity Reset | `gravity_reset.png` | ✅ 已完成 | fadeInOut | 重力波動 |
| Element Morph | `element_morph.png` | ✅ 已完成 | fadeInOut | 元素變化 |
| Time Change | `time_change.png` | ⏳ 待實現 | fadeInOut | 時間扭曲 |
| Titan Gravity | `titan_gravity.png` | ⏳ 待實現 | fadeInOut | 泰坦重力 |

---

**最後更新**: 2025-10-20
**已實現符文**: Angel's Grace, Flame Burst, Thunder Strike (Left & Right), Blessed Combo, Dragon Roar, Element Morph, Gravity Reset
**動畫模式**: 統一使用 fadeInOut（淡入淡出）
**動畫覆蓋範圍**: 整個 APP 螢幕（全局疊加層）
**架構模式**: Controller 在 `main.dart`，動畫資源在 `game_board.dart`
**適用版本**: v1.2.0+
