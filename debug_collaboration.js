/**
 * Debug Collaboration Script
 * 當 Claude 遇到複雜 bug 時，呼叫此腳本與 Gemini CLI 協作
 */

const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');

class DebugCollaborator {
  constructor(apiKey = null) {
    this.projectRoot = process.cwd();
    this.debugLogPath = path.join(this.projectRoot, 'debug-session.log');
    this.apiKey = apiKey;
  }

  /**
   * 準備 bug 資訊檔案給 Gemini 分析
   */
  prepareBugInfo(bugDescription, errorLogs, codeContext, stackTrace) {
    const bugInfo = {
      timestamp: new Date().toISOString(),
      description: bugDescription,
      errorLogs: errorLogs,
      codeContext: codeContext,
      stackTrace: stackTrace,
      projectType: 'Flutter Tetris Game',
      environment: process.platform
    };

    const bugInfoPath = path.join(this.projectRoot, 'bug-analysis.json');
    fs.writeFileSync(bugInfoPath, JSON.stringify(bugInfo, null, 2));
    
    return bugInfoPath;
  }

  /**
   * 啟動與 ChatGPT 的協作會話
   */
  async collaborateWithChatGPT(bugInfoPath) {
    const bugInfo = JSON.parse(fs.readFileSync(bugInfoPath, 'utf8'));
    
    const prompt = `你好 ChatGPT！我是 Claude，正在協助開發一個 Flutter 俄羅斯方塊遊戲。
我遇到了一個複雜的 bug 需要你的協助分析。

Bug 資訊：
- 時間戳: ${bugInfo.timestamp}
- 描述: ${bugInfo.description}
- 錯誤日誌: ${bugInfo.errorLogs}
- 程式碼上下文: ${bugInfo.codeContext}
- 堆疊追蹤: ${bugInfo.stackTrace}
- 專案類型: ${bugInfo.projectType}
- 環境: ${bugInfo.environment}

請提供：
1. 可能的根本原因分析
2. 建議的除錯步驟
3. 可能的解決方案
4. 預防類似問題的建議

讓我們一起解決這個問題！`;

    console.log('🤝 正在啟動 Claude x ChatGPT 協作會話...');
    console.log('📝 Bug 資訊已準備：', bugInfoPath);
    
    const apiKey = process.env.OPENAI_API_KEY || this.apiKey;
    if (!apiKey) {
      throw new Error('OPENAI_API_KEY 環境變數未設定，請設定環境變數或通過參數傳入');
    }
    
    try {
      // 使用 node 內建的 fetch API 調用 OpenAI
      const response = await fetch('https://api.openai.com/v1/chat/completions', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${apiKey}`
        },
        body: JSON.stringify({
          model: 'gpt-4',
          messages: [
            {
              role: 'user',
              content: prompt
            }
          ],
          max_tokens: 2000,
          temperature: 0.7
        })
      });

      if (!response.ok) {
        const errorText = await response.text();
        console.error(`❌ OpenAI API 詳細錯誤: ${response.status} ${response.statusText}`);
        console.error(`錯誤內容: ${errorText}`);
        throw new Error(`OpenAI API 請求失敗: ${response.status} ${response.statusText} - ${errorText}`);
      }

      const data = await response.json();
      const analysis = data.choices[0].message.content;

      console.log('\n🤖 ChatGPT 分析結果：');
      console.log('=' .repeat(50));
      console.log(analysis);
      console.log('=' .repeat(50));
      console.log('✅ ChatGPT 分析完成');
      
      return analysis;
      
    } catch (error) {
      console.error('❌ 調用 ChatGPT API 時發生錯誤：', error.message);
      throw error;
    }
  }

  /**
   * 記錄協作會話
   */
  logCollaborationSession(bugDescription, resolution) {
    const logEntry = {
      timestamp: new Date().toISOString(),
      type: 'COLLABORATION',
      bug: bugDescription,
      resolution: resolution,
      participants: ['Claude', 'ChatGPT']
    };

    const existingLog = fs.existsSync(this.debugLogPath) 
      ? JSON.parse(fs.readFileSync(this.debugLogPath, 'utf8'))
      : { sessions: [] };

    existingLog.sessions.push(logEntry);
    fs.writeFileSync(this.debugLogPath, JSON.stringify(existingLog, null, 2));
  }

  /**
   * 主要的協作流程
   */
  async startCollaboration(bugDescription, errorLogs = '', codeContext = '', stackTrace = '') {
    try {
      console.log('🚀 Claude x ChatGPT 協作除錯開始');
      console.log('🐛 Bug 描述：', bugDescription);

      // 準備 bug 資訊
      const bugInfoPath = this.prepareBugInfo(bugDescription, errorLogs, codeContext, stackTrace);

      // 與 ChatGPT 協作
      await this.collaborateWithChatGPT(bugInfoPath);

      // 記錄協作會話
      this.logCollaborationSession(bugDescription, 'ChatGPT 分析完成，請查看上方輸出');

      console.log('📊 協作會話已記錄到：', this.debugLogPath);

    } catch (error) {
      console.error('💥 協作過程中發生錯誤：', error.message);
      
      // 記錄錯誤會話
      this.logCollaborationSession(bugDescription, `錯誤: ${error.message}`);
      
      // 提供備用建議
      console.log('\n🔧 備用除錯建議：');
      console.log('1. 檢查 Flutter 錯誤日志');
      console.log('2. 運行 flutter analyze');
      console.log('3. 檢查最近的程式碼變更');
      console.log('4. 確認依賴版本兼容性');
    }
  }
}

// 如果直接執行此腳本
if (require.main === module) {
  const collaborator = new DebugCollaborator();
  
  // 從命令列參數獲取 bug 資訊
  const args = process.argv.slice(2);
  const bugDescription = args[0] || 'Unknown bug';
  const errorLogs = args[1] || '';
  const codeContext = args[2] || '';
  const stackTrace = args[3] || '';

  collaborator.startCollaboration(bugDescription, errorLogs, codeContext, stackTrace);
}

module.exports = DebugCollaborator;