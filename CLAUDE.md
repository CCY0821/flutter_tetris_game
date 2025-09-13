# Claude Instructions for Flutter Tetris Game

This is a Flutter-based Tetris game project. When working on this codebase, please follow these guidelines:

## Project Structure
- This is a Flutter application written in Dart
- **📋 詳細檔案結構參考**: 查看 `PROJECT_STRUCTURE.md` 獲得完整的檔案功能對照表
- **⚡ 快速定位指南**:
  - 符文槽UI/冷卻動畫 → `lib/game/touch_controls.dart`
  - 符文效果/施法邏輯 → `lib/game/rune_system.dart`
  - 遊戲核心邏輯 → `lib/game/game_logic.dart`
  - 遊戲狀態管理 → `lib/game/game_state.dart`
  - 能量系統 → `lib/game/rune_energy_manager.dart`
- Game features include:
  - Complete rune system with energy management
  - Next piece preview
  - Game pause/restart functionality
  - Game Over detection and display
  - Scoring system with combo logic

## Development Commands
When making changes to this project, please run these commands to ensure code quality:

```bash
# Format code
flutter format .

# Analyze code for issues
flutter analyze

# Run tests (if available)
flutter test

# Build the app
flutter build apk
```

## Recent Features (based on git history)
- **Rune System**: Complete rune system with energy management and spell casting
- **Rune Configuration Persistence**: Save/load rune loadouts across app restarts
- **Rune UI**: Rune slots that light up when energy is sufficient and respond to clicks
- **Energy System**: Rune energy bars that fill through line clearing
- Next piece display functionality
- Game pause/restart mechanics
- Game Over detection and alerts
- Scoring system with combo mechanics
- Various bug fixes and improvements

## 🐛 問題診斷指引

**遇到已知問題時，請閱讀詳細解決方案文檔**:
- 符文系統問題 → 查看 `docs/troubleshooting/rune_system_debug.md`
- **符文冷卻問題** → 查看 `docs/troubleshooting/rune_cooldown_fix.md` ⭐
- **Gravity Reset 類型錯誤** → 查看 `docs/troubleshooting/gravity_reset_type_error_fix.md` ⭐
- UI 渲染問題 → 查看 `docs/troubleshooting/ui_overflow_fixes.md`  
- 法術功能問題 → 查看 `docs/troubleshooting/spell_implementation.md`

**常見問題快速診斷**:
- 符文槽位不亮：檢查 runeType 是否為 null
- UI 像素溢出：檢查動畫值是否超出 0.0-1.0 範圍
- 法術無效果：確認使用正確的操作模式（直接操作 vs 批處理）
- **類型錯誤**：檢查是否混淆了管理器與接口實現（如 PieceProviderStack vs IPieceProvider）

## 📋 程式碼模式

**需要實作新功能時，請閱讀完整程式碼模式文檔**: `docs/patterns/coding_patterns.md`

**核心模式速記**:
- PAT-RUNE-001: 符文實作 → 使用直接操作模式
- PAT-ANIM-001: 動畫安全 → 所有值 clamp(0.0, 1.0) 
- PAT-PERSIST-001: 狀態持久化 → 正確初始化順序
- PAT-SAFE-001: 系統整合 → null 檢查
- PAT-DEBUG-001: 除錯日誌 → 統一格式

## Guidelines
- Follow Flutter/Dart conventions and best practices
- **Apply Code Patterns**: 新功能必須遵循上述 5 個核心模式
- Test changes when possible before committing
- Focus on game mechanics, UI, and user experience improvements  
- When adding new features or refactoring code, maintain existing functionality as the top priority
- **Simplicity First**: 優先選擇簡單方案（如 Dragon Roar: 174行→20行）

## Testing
Before making commits, ensure:
1. Code compiles without errors (`flutter analyze`)
2. Code is properly formatted (`flutter format .`)
3. App builds successfully (`flutter build apk`)
4. Game functionality works as expected

## 🧙‍♂️ 符文法術開發指引

**重要提醒**: 當需要開發新符文法術時，請先閱讀以下核心檔案以了解標準化流程：

### 必讀檔案 (僅在開發符文時閱讀)
1. `lib/game/rune_system.dart` - 查看 Flame Burst、Thunder Strike 和 Dragon Roar 的成功實現模式
2. `lib/game/game_state.dart` - 了解棋盤架構和座標系統定義
3. `lib/game/rune_definitions.dart` - 符文配置定義

### 🎯 棋盤座標系統 (必須理解)
```
總棋盤: 10寬 x 40高
├── 緩衝區: rows 0-19 (法術不操作)
└── 可視區域: rows 20-39 (法術目標區域)
    列範圍: columns 0-9 (無緩衝區)

標準計算: startRow = max(0, board.length - 20)
```

### 核心開發原則
- **只操作可視區域**: 法術只作用於 rows 20-39，不碰緩衝區
- **直接操作模式**: 仿照 Flame Burst/Thunder Strike 成功架構
- **標準座標計算**: `boardHeight = board.length (40), boardWidth = board[0].length (10)`
- **調試日誌**: 使用標準格式 `[SymbolName] boardH=40, boardW=10`
- **UI 更新**: 直接操作後必須調用 `batchProcessor.notifyBoardChanged()`

### 成功案例參考
- **Flame Burst**: 智能行選擇 + 水平清除 (1行)
- **Thunder Strike**: 固定列選擇 + 垂直清除 (2列)  
- **Dragon Roar**: 固定行選擇 + 水平清除 (3行)

## 🤝 協作除錯

**遇到複雜 bug 時，啟動 Claude x Gemini 協作**:

```bash
node debug_collaboration.js "bug描述" "錯誤日誌" "程式碼檔案" "堆疊追蹤"
```

**觸發條件**: 狀態管理、生命週期、性能、音頻、觸控等複雜問題
**設置說明**: 查看 `docs/collaboration/gemini_setup.md`