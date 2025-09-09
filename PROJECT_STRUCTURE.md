# Flutter Tetris Game - 檔案結構與功能對照表

## 🎮 核心遊戲系統檔案

### 遊戲狀態與邏輯
- `lib/game/game_state.dart` - **遊戲核心狀態管理**
  - 遊戲板、分數、暫停狀態
  - 符文系統整合入口
  - 單例模式的中央狀態管理器

- `lib/game/game_logic.dart` - **遊戲核心邏輯**
  - 方塊移動、旋轉、放置
  - 消行邏輯、遊戲結束判斷
  - 符文施法入口

- `lib/game/game_board.dart` - **遊戲板面渲染**
  - 主遊戲畫面組件
  - 整合所有UI元件

### 輸入控制
- `lib/game/touch_controls.dart` - **🎯 觸控UI控制器**
  - **符文槽UI顯示與點擊處理** ⭐
  - 移動、旋轉、下降按鈕
  - 符文槽冷卻動畫與狀態同步

- `lib/game/input_handler.dart` - 輸入事件處理
- `lib/game/controller_handler.dart` - 外部手把支援

## 🔮 符文系統檔案

### 核心符文邏輯
- `lib/game/rune_system.dart` - **符文系統核心**
  - RuneSystem 主類別
  - RuneSlot 狀態管理
  - 符文效果實現

- `lib/game/rune_energy_manager.dart` - **能量管理**
  - 能量累積與消耗邏輯
  - 能量檢查方法

- `lib/game/rune_definitions.dart` - **符文定義**
  - 所有符文的配置資料
  - 能量消耗、冷卻時間等

### 符文UI組件
- `lib/widgets/rune_energy_hud.dart` - **能量條UI**
- `lib/widgets/rune_selection_page.dart` - **符文選擇頁面**
- `lib/widgets/rune_introduction_page.dart` - 符文介紹頁面

### 符文輔助系統
- `lib/game/rune_loadout.dart` - 符文配置管理
- `lib/game/rune_batch_processor.dart` - 批處理系統
- `lib/game/rune_events.dart` - 事件處理

## 🎨 UI組件檔案

### 主要UI面板
- `lib/widgets/integrated_stats_panel.dart` - **整合統計面板**
- `lib/widgets/marathon_info_panel.dart` - 馬拉松資訊面板
- `lib/widgets/combo_stats_panel.dart` - 連擊統計面板
- `lib/widgets/settings_panel.dart` - 設定面板

### 視覺效果組件
- `lib/widgets/cyberpunk_hud_tag.dart` - 賽博龐克HUD標籤
- `lib/widgets/scanline_overlay.dart` - 掃描線覆蓋效果

### 遊戲畫面渲染
- `lib/game/board_painter.dart` - **遊戲板繪製器**
- `lib/game/game_ui_components.dart` - UI組件集合

## 📱 應用程式結構

### 主程式
- `lib/main.dart` - **應用程式進入點**

### 核心工具
- `lib/core/constants.dart` - 常數定義
- `lib/core/dual_logger.dart` - 雙重日誌系統
- `lib/core/game_persistence.dart` - 遊戲狀態持久化
- `lib/core/pixel_snap.dart` - 像素對齊工具

### 模型與服務
- `lib/models/tetromino.dart` - 俄羅斯方塊模型
- `lib/services/audio_service.dart` - 音效服務
- `lib/services/scoring_service.dart` - 計分服務
- `lib/services/high_score_service.dart` - 高分紀錄

### 遊戲系統
- `lib/game/marathon_system.dart` - 馬拉松模式
- `lib/game/srs_system.dart` - 旋轉系統
- `lib/game/monotonic_timer.dart` - 單調時間器

### 主題與配置
- `lib/theme/game_theme.dart` - 遊戲主題
- `lib/config/ad_config.dart` - 廣告配置

### 廣告系統
- `lib/services/ads/` - 廣告服務集合
- `lib/widgets/ad_banner.dart` - 廣告橫幅

## 🎯 快速定位指南

### 要修改符文槽UI/冷卻動畫/點擊處理？
→ `lib/game/touch_controls.dart`

### 要修改符文效果/施法邏輯？
→ `lib/game/rune_system.dart`

### 要修改遊戲核心邏輯？
→ `lib/game/game_logic.dart`

### 要修改遊戲狀態管理？
→ `lib/game/game_state.dart`

### 要修改能量系統？
→ `lib/game/rune_energy_manager.dart`

### 要修改符文配置？
→ `lib/game/rune_definitions.dart`

---
*此檔案幫助開發者快速定位需要修改的檔案，避免每次都要全檔案搜尋*