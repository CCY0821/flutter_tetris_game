# Android 模擬器音頻除錯指南

## 可能原因
1. **模擬器音頻驅動問題**: 預設音頻後端不相容
2. **Windows音頻設定**: 系統音頻裝置衝突
3. **Flutter音頻插件問題**: audioplayers插件在模擬器上的限制
4. **AVD音頻配置**: 模擬器本身的音頻設定

## 除錯步驟

### 1. 檢查模擬器音頻設定
```bash
emulator -avd TestPhone -audio-out default -audio-in default
```

### 2. 測試系統音頻
在模擬器中開啟設定 > 聲音，測試鈴聲是否有聲音

### 3. 檢查Flutter日誌
查看是否有音頻相關錯誤訊息

### 4. 替代解決方案
- 使用-audio-backend參數
- 嘗試不同的音頻輸出模式
- 檢查Windows音量混合器

## 已嘗試的解決方案
- [x] 重啟模擬器並指定音頻參數
- [ ] 測試模擬器系統音效
- [ ] 檢查audioplayers插件設定
- [ ] 嘗試不同音頻後端