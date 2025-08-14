/**
 * Debug Collaboration Script
 * 當 Claude 遇到複雜 bug 時，呼叫此腳本與 Gemini CLI 協作
 */

const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');

class DebugCollaborator {
  constructor() {
    this.projectRoot = process.cwd();
    this.debugLogPath = path.join(this.projectRoot, 'debug-session.log');
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
   * 啟動與 Gemini 的協作會話
   */
  async collaborateWithGemini(bugInfoPath) {
    const prompt = `
你好 Gemini！我是 Claude，正在協助開發一個 Flutter 俄羅斯方塊遊戲。
我遇到了一個複雜的 bug 需要你的協助分析。

請幫我分析以下 bug 資訊檔案：${bugInfoPath}

請提供：
1. 可能的根本原因分析
2. 建議的除錯步驟
3. 可能的解決方案
4. 預防類似問題的建議

讓我們一起解決這個問題！
    `;

    console.log('🤝 正在啟動 Claude x Gemini 協作會話...');
    console.log('📝 Bug 資訊已準備：', bugInfoPath);
    
    // 設置環境變數並使用 Gemini CLI 分析
    const env = { ...process.env, GEMINI_API_KEY: process.env.GEMINI_API_KEY };
    
    try {
      // 使用 cmd 在 Windows 上執行
      const isWindows = process.platform === 'win32';
      const geminiCmd = isWindows ? 'cmd' : 'bash';
      const geminiArgs = isWindows 
        ? ['/c', `set GEMINI_API_KEY=${env.GEMINI_API_KEY} && gemini -p "${prompt}"`]
        : ['-c', `GEMINI_API_KEY=${env.GEMINI_API_KEY} gemini -p "${prompt}"`];

      const geminiProcess = spawn(geminiCmd, geminiArgs, {
        cwd: this.projectRoot,
        stdio: 'inherit',
        env: env
      });

      return new Promise((resolve, reject) => {
        geminiProcess.on('close', (code) => {
          if (code === 0) {
            console.log('✅ Gemini 分析完成');
            resolve();
          } else {
            console.error('❌ Gemini 分析失敗，退出碼：', code);
            reject(new Error(`Gemini process exited with code ${code}`));
          }
        });

        geminiProcess.on('error', (error) => {
          console.error('❌ 啟動 Gemini 時發生錯誤：', error.message);
          reject(error);
        });
      });
      
    } catch (error) {
      console.error('❌ 執行 Gemini 命令時發生錯誤：', error.message);
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
      participants: ['Claude', 'Gemini']
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
      console.log('🚀 Claude x Gemini 協作除錯開始');
      console.log('🐛 Bug 描述：', bugDescription);

      // 準備 bug 資訊
      const bugInfoPath = this.prepareBugInfo(bugDescription, errorLogs, codeContext, stackTrace);

      // 與 Gemini 協作
      await this.collaborateWithGemini(bugInfoPath);

      // 記錄協作會話
      this.logCollaborationSession(bugDescription, 'Gemini 分析完成，請查看上方輸出');

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