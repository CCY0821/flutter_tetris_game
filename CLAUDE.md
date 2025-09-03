# Claude Instructions for Flutter Tetris Game

This is a Flutter-based Tetris game project. When working on this codebase, please follow these guidelines:

## Project Structure
- This is a Flutter application written in Dart
- Main game logic and UI components are likely in the `lib/` directory
- Game features include:
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
- UI 渲染問題 → 查看 `docs/troubleshooting/ui_overflow_fixes.md`  
- 法術功能問題 → 查看 `docs/troubleshooting/spell_implementation.md`

**常見問題快速診斷**:
- 符文槽位不亮：檢查 runeType 是否為 null
- UI 像素溢出：檢查動畫值是否超出 0.0-1.0 範圍
- 法術無效果：確認使用正確的操作模式（直接操作 vs 批處理）

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
1. `lib/game/rune_system.dart` - 查看 Flame Burst 和 Dragon Roar 的成功實現模式
2. `lib/game/rune_batch_processor.dart` - 了解批處理操作系統
3. `lib/core/rune_definitions.dart` - 符文配置定義

### 核心開發原則
- **直接操作模式**: 仿照 Flame Burst 的成功架構模式
- **簡化優先**: 避免過度複雜的實現 (參考 Dragon Roar: 174行→20行)
- **調試日誌**: 使用標準格式 `[SymbolName] 操作描述: 關鍵數據`
- **UI 更新**: 直接操作後必須調用 `batchProcessor.notifyBoardChanged()`

### 成功案例參考
- **Flame Burst**: 智能目標選擇 + 直接操作
- **Dragon Roar**: 固定目標選擇 + 簡化實現

## 🤝 協作除錯

**遇到複雜 bug 時，啟動 Claude x Gemini 協作**:

```bash
node debug_collaboration.js "bug描述" "錯誤日誌" "程式碼檔案" "堆疊追蹤"
```

**觸發條件**: 狀態管理、生命週期、性能、音頻、觸控等複雜問題
**設置說明**: 查看 `docs/collaboration/gemini_setup.md`