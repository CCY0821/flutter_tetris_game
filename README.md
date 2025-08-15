# 🎮 Flutter Tetris Game

一個基於 Flutter 的現代俄羅斯方塊遊戲，完全實現官方指導原則和競技級功能。

## ✨ 特色功能

### 🎯 官方得分系統
- 基於 [Tetris.wiki/Scoring](https://tetris.wiki/Scoring) 的現代指導原則
- 標準消行得分：Single(100) → Double(300) → Triple(500) → Tetris(800)
- T-Spin 系統：完整的 Mini/Normal T-Spin 支援
- Back-to-Back 獎勵：困難消除的 1.5倍 分數加成

### 🔥 官方連擊系統
- 基於 [Tetris.wiki/Combo](https://tetris.wiki/Combo) 的標準規範
- 6 級連擊等級：Nice → Great → Excellent → Amazing → Incredible → LEGENDARY
- 動態視覺效果：連擊等級對應不同顏色和特效
- 完整統計追蹤：當前/最大連擊、總次數、積分統計

### 🏃‍♂️ Marathon 模式
- 20 個關卡的專業速度曲線
- 從慢速到光速的漸進挑戰
- 重力值精確計算 (0.02G → 20.00G)
- 符合競技標準的速度系統

### 🎮 多重控制系統
- **鍵盤控制**：標準方向鍵 + WASD + Z/X 旋轉
- **手把支援**：完整的遊戲手把映射
- **觸控介面**：專為行動裝置優化的觸控按鈕
- **SRS 旋轉**：超級旋轉系統 (Super Rotation System)

### 🎨 現代化 UI
- 材質設計風格的遊戲介面
- Ghost Piece：方塊落地位置預覽
- 即時得分顯示和成就系統
- 響應式設計支援多種螢幕尺寸

### 🔊 音頻系統
- 背景音樂和音效支援
- 分層音效優先級系統
- 可切換的音樂/音效控制

## 🚀 快速開始

### 本地 Web 測試
```bash
# 1. 編譯 Web 版本
flutter build web

# 2. 啟動本地伺服器
node simple_server.js

# 3. 在瀏覽器中訪問
http://localhost:3000
```

### 行動裝置編譯
```bash
# Android
flutter build apk

# iOS (需要 macOS 和 Xcode)
flutter build ios
```

## 📖 文檔

- **[TESTING.md](TESTING.md)** - 完整測試指南
- **[COMBO_GUIDE.md](COMBO_GUIDE.md)** - 連擊系統說明
- **[LOCAL_TESTING_GUIDE.md](LOCAL_TESTING_GUIDE.md)** - Marathon 模式測試

## 🎯 技術特點

### 核心架構
- **Flutter/Dart** 跨平台框架
- **模組化設計** 便於維護和擴展
- **狀態管理** 精確的遊戲狀態控制
- **響應式 UI** 適配多種裝置

### 遊戲引擎
- **SRS 旋轉系統** 官方標準旋轉邏輯
- **精確碰撞檢測** 防止方塊重疊和穿透
- **緩衝區系統** 20 行上方緩衝區支援
- **60FPS 流暢渲染** 競技級遊戲體驗

## 🛠️ 開發

### 環境需求
- Flutter SDK 3.0+
- Dart 2.17+
- Node.js (用於本地伺服器)

### 專案結構
```
lib/
├── core/           # 核心常數和配置
├── game/           # 遊戲邏輯和 UI 組件
├── models/         # 資料模型 (Tetromino 等)
├── services/       # 服務層 (音頻、得分等)
├── theme/          # UI 主題和樣式
└── widgets/        # 可重用 UI 組件
```

## 🏆 競技特性

### 官方標準相容
- ✅ 現代 Tetris 指導原則
- ✅ SRS 超級旋轉系統
- ✅ 標準得分和連擊系統
- ✅ T-Spin 和 Perfect Clear 支援

### 效能優化
- ✅ 60FPS 穩定幀率
- ✅ 低延遲輸入響應
- ✅ 記憶體使用優化
- ✅ 多平台效能調校

---

🎯 **目標**：提供符合官方標準的專業級俄羅斯方塊遊戲體驗

🚀 **願景**：成為 Flutter 生態系統中最完整的俄羅斯方塊實現
