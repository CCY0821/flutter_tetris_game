# Gemini CLI 設置指南

## 🚀 Claude x Gemini 協作除錯機制已就緒！

### ✅ 已完成的設置：
- Gemini CLI 已安裝（版本 0.1.21）
- 協作腳本已創建：`debug_collaboration.js`
- CLAUDE.md 已更新協作機制文檔

### 🔧 需要完成的最後步驟：

#### 1. 取得有效的 Gemini API 金鑰
當前提供的 API 金鑰無效，請：
1. 前往 [Google AI Studio](https://makersuite.google.com/app/apikey)
2. 使用你的 Google 帳號登入
3. 創建新的 API 金鑰
4. 複製有效的 API 金鑰

#### 2. 設置環境變數（選擇一種方式）

**方式 1：永久設置（推薦）**
```cmd
setx GEMINI_API_KEY "your_real_api_key_here"
```

**方式 2：暫時設置**
```cmd
set GEMINI_API_KEY=your_real_api_key_here
```

#### 3. 測試協作機制
```bash
# 測試 Gemini CLI 連接
echo "Hello" | gemini -p "Please respond briefly"

# 測試協作腳本
node debug_collaboration.js "測試bug" "錯誤訊息" "程式碼位置" "堆疊追蹤"
```

### 🤝 協作機制使用時機
我會在遇到以下複雜問題時呼叫 Gemini 協作：

1. **Flutter 狀態管理問題**
   - setState called after dispose
   - Complex widget lifecycle issues

2. **遊戲邏輯 Bug**
   - 方塊旋轉系統問題
   - 碰撞檢測錯誤

3. **性能問題**
   - 畫面延遲或卡頓
   - 記憶體洩漏

4. **音頻系統問題**
   - 音效播放衝突
   - 背景音樂控制

5. **多平台兼容性**
   - Android/iOS 特定問題
   - 觸控手勢衝突

### 📊 協作流程
1. **問題識別**：我偵測到複雜 bug
2. **資訊收集**：整理錯誤日志、程式碼上下文、堆疊追蹤
3. **協作啟動**：呼叫 `debug_collaboration.js` 腳本
4. **雙重分析**：Claude + Gemini 共同分析
5. **解決方案**：整合雙方見解提供最佳解決方案
6. **記錄保存**：將協作過程記錄在 `debug-session.log`

### 🎯 準備好了嗎？
一旦你設置好有效的 API 金鑰，我們就能開始真正的協作除錯了！

當你遇到任何 Flutter Tetris 遊戲的複雜問題時，只需告訴我，我會：
1. 分析問題
2. 呼叫 Gemini 協作
3. 整合雙重 AI 的見解
4. 提供最佳解決方案

**協作力量，無與倫比！** 🚀✨