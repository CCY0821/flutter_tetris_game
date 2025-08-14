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
- Next piece display functionality
- Game pause/restart mechanics
- Game Over detection and alerts
- Scoring system with combo mechanics
- Various bug fixes and improvements

## Guidelines
- Follow Flutter/Dart conventions and best practices
- Maintain existing code style and patterns
- Test changes when possible before committing
- Focus on game mechanics, UI, and user experience improvements
- When adding new features or refactoring code, maintain existing functionality as the top priority

## Testing
Before making commits, ensure:
1. Code compiles without errors (`flutter analyze`)
2. Code is properly formatted (`flutter format .`)
3. App builds successfully (`flutter build apk`)
4. Game functionality works as expected

## Claude x Gemini 協作除錯機制
當遇到複雜的 bug 無法獨自解決時，使用以下協作流程：

### 設置 Gemini CLI
1. 確保 Gemini CLI 已安裝：`npm install -g @google/gemini-cli`
2. 設置身份驗證：
   - 選項 1：Google 登入（推薦）- 免費額度
   - 選項 2：API 金鑰 - 從 Google AI Studio 取得
   - 設置環境變數：`GEMINI_API_KEY=your_api_key`

### 協作除錯流程
使用協作腳本：`debug_collaboration.js`

```bash
# 啟動協作除錯
node debug_collaboration.js "bug描述" "錯誤日志" "程式碼上下文" "堆疊追蹤"

# 範例
node debug_collaboration.js "遊戲暫停後無法恢復" "Error: setState called after dispose" "lib/game/game_logic.dart" "stack_trace_here"
```

### 協作觸發條件
當遇到以下情況時，啟動 Claude x Gemini 協作：
- 複雜的狀態管理問題
- Flutter 生命週期相關錯誤
- 性能瓶頸分析
- 多平台兼容性問題
- 音頻播放問題
- 觸控/手勢衝突
- 複雜的演算法 bug

### 協作輸出
- bug-analysis.json：詳細的 bug 資訊
- debug-session.log：協作會話記錄
- Gemini 的分析建議和解決方案