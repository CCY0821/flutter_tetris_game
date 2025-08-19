# Android 模擬器故障排除指南

## 常見問題：ADB 連接失敗

### 症狀
- `flutter devices` 顯示模擬器離線或找不到設備
- 錯誤訊息：`adb.exe: device 'emulator-5554' not found`
- 應用構建成功但安裝失敗

### 根本原因
1. **ADB 連接不穩定** - 模擬器在長時間構建過程中失去 ADB 連接
2. **設備狀態不同步** - Flutter 檢測到模擬器但 ADB 無法找到設備
3. **模擬器啟動時序問題** - 模擬器進程啟動但未完全初始化

### 標準解決流程

#### 步驟 1：檢查設備狀態
```bash
flutter devices --device-timeout 30
```

#### 步驟 2：如果設備離線，重啟模擬器
```bash
# 方法 1: 使用 Flutter 命令
flutter emulators --launch TestPhone

# 方法 2: 使用項目修復腳本
start fix_emulator_position.bat
```

#### 步驟 3：驗證連接
```bash
# 等待設備完全啟動
flutter devices --device-timeout 60

# 檢查詳細狀態
flutter doctor -v
```

#### 步驟 4：重新部署應用
```bash
flutter run -d emulator-5554
```

### 預防措施

1. **啟動後等待** - 模擬器啟動後等待完全載入再部署應用
2. **使用修復腳本** - 定期運行 `fix_emulator_position.bat` 保持連接穩定
3. **監控構建時間** - 長時間構建（>2分鐘）後檢查設備連接狀態

### 備用方案

如果上述步驟無效：

1. **完全重置模擬器**
   ```bash
   # 強制終止模擬器進程
   powershell "Stop-Process -Name emulator -Force"
   
   # 重新啟動
   flutter emulators --launch TestPhone
   ```

2. **使用其他部署目標**
   ```bash
   # 部署到 Web 瀏覽器進行快速測試
   flutter run -d chrome
   
   # 部署到 Windows 桌面版
   flutter run -d windows
   ```

### 成功指標

✅ `flutter devices` 顯示模擬器為在線狀態  
✅ `flutter doctor -v` 在 "Connected device" 部分顯示模擬器  
✅ 應用能夠成功安裝並啟動  
✅ 控制台顯示 "Flutter run key commands" 選單  

### 注意事項

- 這個問題在 Android 模擬器上很常見，特別是在 Windows 環境下
- 模擬器進程可能運行但 ADB 橋接失敗
- 重啟通常是最有效的解決方案
- 保持耐心，模擬器完全啟動需要時間

---

最後更新：2025-08-19  
適用版本：Flutter 3.22.2, Android SDK 36.0.0