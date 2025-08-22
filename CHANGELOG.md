# Changelog

All notable changes to this project will be documented in this file.

## [1.2.0] - 2025-08-22

### 🌃 New Theme System
- **Cyberpunk 2077 霓虹主題**：完整的未來科技風格視覺系統
- **霓虹調色盤**：霓虹青色 (#00E5FF)、霓虹洋紅 (#FF2ED1)、電光紫 (#8A2BE2)
- **三級光暈系統**：軟光/中等/強烈光暈效果 (4px/8px/16px)
- **深層背景設計**：深空藍與暗夜藍雙層背景系統

### 🎨 Visual Enhancements
- **標題光暈特效**：雙重霓虹陰影 (青色+洋紅)
- **按鈕互動升級**：透明背景 + 霓虹邊框 + Hover 光暈反饋
- **背景圖案重設**：霓虹網格線與裝飾性光點
- **全域主題統一**：Scaffold/Card/Button 完整 Cyberpunk 風格

### 🔧 Technical Integrity
- **遊戲邏輯完整保留**：所有功能與行為毫無變化
- **UI 佈局結構不變**：元件層級/位置/尺寸完全保持
- **效能優化持續**：Profile 模式效能表現依然優異
- **功能相容性維持**：支援所有原有遊戲特性

### ✅ Quality Assurance
- **多次重開機測試**：穩定性驗證通過
- **音頻系統正常**：背景音樂與音效完全正常
- **視覺效果流暢**：霓虹光暈與動畫表現優異

## [1.1.0] - 2025-08-22

### 🔧 Fixed
- **重開機崩潰問題完全解決**：修復 AudioPlayer 重複初始化導致的記憶體洩漏
- **震動特效穩定性**：改善 Timer 資源管理，防止震動特效計時器衝突
- **AnimationController 生命週期**：強化生命週期管理，添加 mounted 檢查保護

### ⚡ Performance
- **渲染效能大幅提升**：BoardPainter 快取 Paint 物件，減少重複建立
- **精確重繪控制**：實作 shouldRepaint 邏輯，避免不必要的重繪操作
- **重繪範圍隔離**：添加 RepaintBoundary 隔離遊戲板重繪，提升整體幀率
- **記憶體使用優化**：優化資源管理，記憶體使用更加平穩

### 🎮 Gaming Experience
- **震動特效保留**：消行震動特效正常運作且更加穩定
- **流暢度提升**：Profile 模式下效能表現顯著改善
- **穩定性增強**：遊戲長時間運行更加穩定

### 🧪 Testing
- ✅ Android 模擬器測試通過
- ✅ Profile 模式效能驗證通過
- ✅ 重開機壓力測試通過
- ✅ 記憶體洩漏測試通過

## [1.0.0] - 2025-08-21

### 🎮 Initial Release
- 完整的 Tetris 遊戲實現
- Marathon 和 Classic 遊戲模式
- 音頻系統與音量控制
- 震動特效與視覺回饋
- SRS 旋轉系統
- Ghost Piece 預覽
- 響應式 UI 設計
- 觸控控制支援
- 多平台支援（Android/Desktop）