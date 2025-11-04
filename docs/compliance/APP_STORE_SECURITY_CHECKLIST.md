# App Store 上架資安審核檢查清單
**完整的提交前驗證指南 - Tetris Runes**

---

## 📋 文件概述

本檢查清單涵蓋 App Store 和 Google Play 的所有資安要求。每個項目都標註了：
- ✅ 已完成
- ⚠️ 需手動操作
- 🔴 阻擋上架（必須完成）
- 🟡 建議完成（提升通過率）

---

## 🔴 關鍵阻擋項（必須全數完成）

### **1. iOS 網路安全設定 (ATS)**

**檔案**: `ios/Runner/Info.plist`

**檢查項目**:
- [x] 已移除 `NSAllowsArbitraryLoads: true`
- [x] 已設定 AdMob 專用白名單
- [x] 僅允許 `googlesyndication.com`, `googleadservices.com`, `googleapis.com`

**驗證方法**:
```bash
cat ios/Runner/Info.plist | grep -A 30 "NSAppTransportSecurity"
```

**預期結果**:
```xml
<key>NSAllowsArbitraryLoads</key>
<false/>
<key>NSExceptionDomains</key>
<!-- 僅包含 AdMob 域名 -->
```

**狀態**: ✅ **已完成**（已於本次修復）

---

### **2. iOS 追蹤用途說明**

**檔案**: `ios/Runner/Info.plist`

**檢查項目**:
- [x] 已新增 `NSUserTrackingUsageDescription`
- [x] 說明文字清楚易懂（繁體中文）
- [x] 說明廣告用途與使用者利益

**驗證方法**:
```bash
cat ios/Runner/Info.plist | grep -A 1 "NSUserTrackingUsageDescription"
```

**預期結果**:
```xml
<key>NSUserTrackingUsageDescription</key>
<string>我們使用您的資料來提供個人化廣告，以支持遊戲的免費運營。您可以隨時在設定中變更此選項。</string>
```

**狀態**: ✅ **已完成**（已於本次修復）

---

### **3. AdMob 正式 App ID 設定**

**iOS 檔案**: `ios/Runner/Info.plist:51`
**Android 檔案**: `android/app/src/main/AndroidManifest.xml:13`

**檢查項目**:
- [ ] ⚠️ iOS App ID 已替換（目前為測試 ID）
- [ ] ⚠️ Android App ID 已替換（目前為測試 ID）
- [ ] ⚠️ 程式碼中無硬編碼測試廣告單元 ID

**驗證方法**:
```bash
# 搜尋測試 ID（應該找不到）
grep -r "3940256099942544" .

# 確認已替換為正式 ID
grep -r "ca-app-pub-" ios/Runner/Info.plist android/app/src/main/AndroidManifest.xml
```

**預期結果**: 不包含 `3940256099942544`

**狀態**: 🔴 **需手動完成** - 請參考 `ADMOB_PRODUCTION_SETUP.md`

---

### **4. 隱私政策公開託管**

**檢查項目**:
- [ ] ⚠️ 隱私政策已上傳至公開 URL
- [ ] ⚠️ URL 可正常訪問（無需登入）
- [ ] ⚠️ 包含繁體中文與英文版本
- [ ] ⚠️ 已填寫至 App Store Connect / Google Play Console

**建議託管方式**:
1. **GitHub Pages**（免費）:
   ```bash
   # 1. 複製隱私政策到 docs 資料夾
   cp docs/compliance/PRIVACY_POLICY.md docs/privacy.md

   # 2. 在 GitHub Repo 設定中啟用 GitHub Pages
   # 3. URL 將為：https://your-username.github.io/flutter_tetris_game/privacy
   ```

2. **Google Sites**（免費）: https://sites.google.com/
3. **個人網站**

**驗證方法**:
```bash
curl -I https://your-privacy-policy-url.com
# 應回傳 HTTP 200 OK
```

**狀態**: 🔴 **需手動完成** - 範本已建立於 `docs/compliance/PRIVACY_POLICY.md`

---

### **5. App Store Connect 隱私權標籤**

**檢查項目**:
- [ ] ⚠️ 已設定「資料類型」標籤
- [ ] ⚠️ 已標註「裝置 ID」用於廣告追蹤
- [ ] ⚠️ 已標註「產品互動」用於廣告分析
- [ ] ⚠️ 已正確設定「是否用於追蹤」

**設定位置**: App Store Connect → App 資訊 → App 隱私權

**參考指南**: `PRIVACY_POLICY.md` 底部的「App Store Connect 隱私權標籤設定指南」

**狀態**: 🔴 **需手動完成**（上架時填寫）

---

## 🟡 強烈建議完成項（提升通過率）

### **6. GDPR 合規（歐盟使用者）**

**檢查項目**:
- [ ] ⚠️ 已實作 Google UMP SDK 同意對話框
- [ ] ⚠️ Android Manifest 已設定 `DELAY_APP_MEASUREMENT_INIT`
- [ ] ⚠️ 已測試歐盟 IP 流程（使用 VPN）

**實作指南**: 參考 `docs/compliance/GDPR_IMPLEMENTATION_GUIDE.md`

**驗證方法**:
```bash
# 檢查 Android 設定
grep -A 2 "DELAY_APP_MEASUREMENT_INIT" android/app/src/main/AndroidManifest.xml

# 測試歐盟流程（使用 VPN 連線至德國後執行）
flutter run --release
```

**狀態**: 🟡 **需手動實作**（已提供完整指南）

**影響範圍**: 歐盟地區可能無法通過審核

---

### **7. 資料儲存安全性**

**當前狀態**: 使用 `SharedPreferences`（明文儲存）

**檢查項目**:
- [x] 儲存資料為非敏感資訊（遊戲進度、分數）
- [ ] 🟢 可選：升級至 `flutter_secure_storage`（加密儲存）

**實作指南**: 參考 `docs/compliance/SECURITY_HARDENING_GUIDE.md`

**風險評估**:
- 低風險：無個人資訊、無密碼、無金流
- Apple 傾向要求所有持久化資料加密

**狀態**: ✅ **可接受**（如遇審核問題再加密）

---

### **8. 程式碼混淆**

**檢查項目**:
- [ ] ⚠️ 正式建置時啟用 `--obfuscate` 參數
- [ ] ⚠️ 已保存符號檔案（`split-debug-info` 輸出）

**執行命令**:
```bash
# iOS
flutter build ios --release --obfuscate --split-debug-info=build/ios/symbols

# Android
flutter build appbundle --release --obfuscate --split-debug-info=build/android/symbols
```

**驗證方法**:
```bash
# 檢查符號檔案是否存在
ls -lh build/ios/symbols
ls -lh build/android/symbols
```

**狀態**: 🟡 **需手動執行**（建置時新增參數）

**影響範圍**: 不影響審核，但提升安全性

---

## 🟢 可選項（視需求實作）

### **9. Root/Jailbreak 檢測**

**當前評估**: 不需要（單機遊戲，無線上排行榜）

**檢查項目**:
- [ ] 🟢 可選：整合 `flutter_jailbreak_detection`
- [ ] 🟢 可選：顯示警告但不阻擋遊戲

**狀態**: 🟢 **不需要**

---

### **10. 防截圖保護**

**當前評估**: 不需要（無敏感內容）

**狀態**: 🟢 **不需要**

---

## 🧪 提交前測試檢查清單

### **A. 功能測試**

```bash
# 1. 清除快取並重新建置
flutter clean
flutter pub get

# 2. iOS 測試
flutter build ios --release --obfuscate --split-debug-info=build/ios/symbols
# 在實體裝置上安裝並測試所有功能

# 3. Android 測試
flutter build appbundle --release --obfuscate --split-debug-info=build/android/symbols
# 在實體裝置上安裝並測試所有功能

# 4. 廣告測試
# 確認廣告正常顯示（需使用正式 AdMob ID）
```

**測試項目**:
- [ ] 遊戲正常啟動
- [ ] 遊戲進度正常儲存與載入
- [ ] 符文系統正常運作
- [ ] 廣告正常顯示（Banner / Interstitial）
- [ ] iOS ATT 彈窗正常顯示（iOS 14.5+）
- [ ] GDPR 對話框正常顯示（歐盟 IP）
- [ ] 高分正常儲存與更新
- [ ] 無 Crash 或錯誤

---

### **B. 資安掃描測試**

```bash
# 1. 使用 flutter analyze 檢查程式碼
flutter analyze

# 2. 檢查是否有敏感資訊洩漏
grep -r "password\|secret\|api_key\|private_key" lib/

# 3. 檢查測試 ID（應該找不到）
grep -r "3940256099942544" .

# 4. 檢查 Log 輸出（不應有敏感資訊）
flutter run --release
# 檢查 Console 輸出
```

**預期結果**:
- [ ] `flutter analyze` 無錯誤
- [ ] 無敏感資訊洩漏
- [ ] 無測試 ID 殘留
- [ ] Log 無敏感資訊

---

### **C. 檔案大小與效能測試**

```bash
# 檢查 APK/IPA 大小
ls -lh build/app/outputs/bundle/release/app-release.aab
ls -lh build/ios/ipa/*.ipa

# 效能測試
flutter run --profile
# 檢查 FPS、記憶體使用、CPU 使用率
```

**預期結果**:
- [ ] APK/AAB 大小 < 50 MB
- [ ] IPA 大小 < 100 MB
- [ ] FPS 維持 60 FPS（或目標幀率）
- [ ] 記憶體使用 < 200 MB

---

## 📝 提交準備文件清單

### **必須準備的文件**

1. **隱私政策 URL**
   - [ ] 已託管至公開網址
   - [ ] URL: `___________________________`

2. **AdMob 帳號資訊**
   - [ ] iOS App ID: `ca-app-pub-________________~__________`
   - [ ] Android App ID: `ca-app-pub-________________~__________`
   - [ ] 廣告單元 ID 列表

3. **App Store Connect 截圖**
   - [ ] iPhone 6.7" (1290x2796) x 3 張
   - [ ] iPhone 6.5" (1242x2688) x 3 張
   - [ ] iPad Pro 12.9" (2048x2732) x 3 張

4. **Google Play Console 截圖**
   - [ ] 手機 (1080x1920 或 720x1280) x 2-8 張
   - [ ] 平板 (1920x1200 或 2560x1600) x 2-8 張

5. **應用程式說明**
   - [ ] 繁體中文版本
   - [ ] 英文版本
   - [ ] 包含符文系統、遊戲特色說明

6. **審核備註**（提供給審核員的說明）
   ```
   測試帳號（如有）: 無需帳號
   測試步驟:
   1. 啟動應用程式
   2. 開始遊戲並測試基本功能
   3. 符文系統可在遊戲中透過消除行數累積能量後使用

   特殊注意事項:
   - 應用程式使用 Google AdMob 顯示廣告
   - GDPR 對話框僅在歐盟地區顯示
   - iOS ATT 彈窗會在首次啟動時顯示
   ```

---

## 🚀 提交流程

### **App Store (iOS)**

1. 在 Xcode 中建置並上傳至 App Store Connect
   ```bash
   flutter build ios --release --obfuscate --split-debug-info=build/ios/symbols
   open ios/Runner.xcworkspace
   # 在 Xcode 中: Product → Archive → Distribute App
   ```

2. 在 App Store Connect 填寫資訊
   - App 資訊
   - 定價與供應狀況
   - App 隱私權（使用 PRIVACY_POLICY.md 的標籤設定指南）
   - 審核資訊

3. 提交審核
   - 選擇建置版本
   - 填寫「新增功能」
   - 點擊「提交審核」

---

### **Google Play (Android)**

1. 建置並上傳 App Bundle
   ```bash
   flutter build appbundle --release --obfuscate --split-debug-info=build/android/symbols
   ```

2. 在 Google Play Console 上傳
   - 建立內部測試版（推薦先測試）
   - 升級至正式版

3. 填寫商店資訊
   - 應用程式內容（廣告、目標年齡層）
   - 隱私權政策
   - 商店資訊（截圖、說明）

4. 提交審核

---

## 📊 審核時間預估

| 平台 | 首次審核 | 更新審核 | 被拒後重審 |
|------|---------|---------|-----------|
| App Store | 1-3 天 | 1-2 天 | 1-2 天 |
| Google Play | 數小時-2 天 | 數小時-1 天 | 數小時-1 天 |

---

## ❌ 常見審核被拒原因與解決方法

### **iOS 常見被拒原因**

1. **Guideline 2.1 - App Completeness**
   - 原因：App Crash 或功能不完整
   - 解決：確保所有功能正常運作

2. **Guideline 5.1.1 - Privacy - Data Collection and Storage**
   - 原因：隱私政策不完整或缺失
   - 解決：確認隱私政策 URL 可訪問

3. **Guideline 2.3.1 - Performance**
   - 原因：使用測試 AdMob ID
   - 解決：替換為正式 AdMob ID

---

### **Android 常見被拒原因**

1. **Inappropriate Content**
   - 原因：內容分級錯誤
   - 解決：正確設定為「Everyone」

2. **Privacy Policy**
   - 原因：隱私政策連結失效
   - 解決：確認 URL 可正常訪問

3. **Target API Level**
   - 原因：目標 API 版本過舊
   - 解決：確保 `targetSdkVersion >= 33`（Android 13）

---

## ✅ 最終確認清單

### **提交前 30 分鐘檢查**

- [ ] 所有必須項目（🔴）已完成
- [ ] 所有建議項目（🟡）已評估
- [ ] 測試檢查清單全數通過
- [ ] 截圖與說明已準備完成
- [ ] AdMob 測試 ID 已完全移除
- [ ] 隱私政策 URL 可正常訪問
- [ ] 應用程式版本號已更新
- [ ] 已備份符號檔案（symbol files）
- [ ] 已閱讀審核指南最新版本

---

## 📞 緊急聯絡資源

**Apple 開發者支援**: https://developer.apple.com/contact/
**Google Play 支援**: https://support.google.com/googleplay/android-developer/

**社群資源**:
- Stack Overflow: https://stackoverflow.com/questions/tagged/flutter
- Flutter Discord: https://discord.gg/flutter
- r/FlutterDev: https://reddit.com/r/FlutterDev

---

## 📈 審核通過後續步驟

1. **監控 Crashlytics**（如已整合）
   - 確認無重大 Crash

2. **檢查 AdMob 收益**
   - 確認廣告正常投放
   - 檢查 eCPM 與填充率

3. **收集使用者回饋**
   - 監控 App Store / Google Play 評論
   - 快速回應負面評論

4. **規劃下一版本**
   - 修復回報的 Bug
   - 新增使用者建議的功能

---

**祝您上架順利！🎉**

**版本**: 1.0.0
**最後更新**: 2025-01-XX
**適用範圍**: Tetris Runes v1.2.0+
