# AdMob 正式版 ID 設定指南
**從測試 ID 遷移至正式生產環境**

---

## ⚠️ 當前狀態警告

**🔴 應用程式目前使用的是 Google 測試 AdMob ID**

**必須在上架前替換**，否則將導致：
- ❌ App Store / Google Play 審核被拒
- ❌ 廣告無法正常顯示
- ❌ 違反 AdMob 政策，可能導致帳號停權

---

## 📋 當前測試 ID 位置

### iOS (Info.plist)
**檔案**: `ios/Runner/Info.plist`
**行數**: 51

```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-3940256099942544~1458002511</string>
<!-- ⚠️ 這是測試 ID，必須替換！ -->
```

---

### Android (AndroidManifest.xml)
**檔案**: `android/app/src/main/AndroidManifest.xml`
**行數**: 13

```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-3940256099942544~3347511713"/>
<!-- ⚠️ 這是測試 ID，必須替換！ -->
```

---

## 🔧 取得正式 AdMob ID 步驟

### **步驟一：登入 AdMob Console**

1. 前往 [Google AdMob](https://apps.admob.com/)
2. 使用您的 Google 帳號登入
3. 如果是首次使用，需完成帳號設定

---

### **步驟二：建立應用程式**

#### **建立 iOS 應用程式**

1. 點擊側邊欄 **「應用程式」** → **「新增應用程式」**
2. 選擇 **「iOS」** 平台
3. 填寫應用程式資訊：
   - **應用程式名稱**: `Tetris Runes`（或您的遊戲名稱）
   - **選擇應用程式是否已發布到商店**: 選擇 **「否」**（首次上架）
   - **App Store ID**: 留空（上架後再填）
4. 點擊 **「新增」**
5. **記下 App ID**（格式：`ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX`）

---

#### **建立 Android 應用程式**

1. 點擊側邊欄 **「應用程式」** → **「新增應用程式」**
2. 選擇 **「Android」** 平台
3. 填寫應用程式資訊：
   - **應用程式名稱**: `Tetris Runes`
   - **套件名稱**: `com.yourcompany.flutter_tetris_game`（從 `build.gradle` 取得）
4. 點擊 **「新增」**
5. **記下 App ID**

---

### **步驟三：建立廣告單元（Ad Unit）**

為您的應用程式建立至少一個廣告單元：

1. 選擇剛建立的應用程式
2. 點擊 **「廣告單元」** → **「新增廣告單元」**
3. 選擇廣告格式：
   - **橫幅廣告（Banner）**: 適合遊戲底部
   - **插頁廣告（Interstitial）**: 適合關卡切換、遊戲結束
   - **獎勵廣告（Rewarded）**: 適合兌換復活機會
4. 填寫廣告單元名稱（例如：`game_over_interstitial`）
5. 點擊 **「建立廣告單元」**
6. **記下廣告單元 ID**（格式：`ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX`）

---

### **步驟四：替換專案中的測試 ID**

#### **替換 iOS App ID**

編輯 `ios/Runner/Info.plist:51`：

```xml
<!-- 修改前（測試 ID）-->
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-3940256099942544~1458002511</string>

<!-- 修改後（您的正式 ID）-->
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX</string>
```

**⚠️ 注意**：請將 `XXXXXXXXXXXXXXXX` 替換為您在 AdMob Console 取得的真實 ID。

---

#### **替換 Android App ID**

編輯 `android/app/src/main/AndroidManifest.xml:13`：

```xml
<!-- 修改前（測試 ID）-->
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-3940256099942544~3347511713"/>

<!-- 修改後（您的正式 ID）-->
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX"/>
```

---

#### **更新 Dart 程式碼中的廣告單元 ID**

檢查專案中是否有使用測試廣告單元 ID：

```bash
# 搜尋測試廣告單元 ID
grep -r "ca-app-pub-3940256099942544" lib/
```

如果找到，請替換為您在步驟三取得的真實廣告單元 ID。

---

## 🧪 驗證設定

### **方法一：透過 Log 驗證**

執行應用程式，檢查 Console 輸出：

```bash
flutter run
```

**尋找以下 Log**：
```
[AdMob] GADApplicationIdentifier: ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX
```

**如果看到測試 ID，表示替換失敗**：
```
[AdMob] GADApplicationIdentifier: ca-app-pub-3940256099942544~...
❌ 這是錯誤的！
```

---

### **方法二：檢查廣告顯示**

1. 執行應用程式並觸發廣告
2. 廣告應該正常顯示（可能需要等待 1-2 小時生效）
3. 如果顯示「測試廣告」標籤，表示仍在使用測試 ID

---

## 📝 App Store / Google Play 設定

### **App Store Connect**

1. 登入 [App Store Connect](https://appstoreconnect.apple.com/)
2. 選擇您的應用程式
3. 前往 **「App 資訊」** → **「隱私權政策 URL」**
4. 貼上隱私政策連結（參考 `PRIVACY_POLICY.md`）
5. 前往 **「App 隱私權」** → 設定隱私權標籤（參考隱私政策文件）

---

### **Google Play Console**

1. 登入 [Google Play Console](https://play.google.com/console/)
2. 選擇您的應用程式
3. 前往 **「政策」** → **「應用程式內容」**
4. 填寫「隱私權政策」連結
5. 設定「廣告」選項：選擇 **「是，此應用程式包含廣告」**

---

## ⚙️ AdMob 帳號設定檢查清單

在應用程式上架前，確認以下設定：

### **付款資訊**
- [ ] 已填寫付款地址
- [ ] 已設定付款方式（銀行帳戶 / 支票）
- [ ] 已設定付款門檻（預設 $100 USD）

### **稅務資訊**
- [ ] 已提交稅務表單（W-9 / W-8BEN）
- [ ] 已驗證身分（可能需要護照/身分證）

### **政策合規**
- [ ] 已閱讀並同意 AdMob 政策
- [ ] 已設定應用程式分級（年齡分級）
- [ ] 已啟用「兒童導向內容」設定（如適用）

---

## 🚨 常見錯誤

### **錯誤一：廣告不顯示**

**原因**：
- 新建立的 AdMob 應用程式需要 1-2 小時生效
- App ID 設定錯誤
- 網路連線問題

**解決方法**：
```bash
# 1. 檢查 Log 是否有錯誤
flutter run --verbose

# 2. 確認 App ID 格式正確（包含 ~ 符號）
# 正確格式：ca-app-pub-1234567890123456~0987654321

# 3. 等待 1-2 小時後再測試
```

---

### **錯誤二：「Invalid AdMob App ID」**

**原因**：App ID 格式錯誤或複製時包含多餘空白

**解決方法**：
```xml
<!-- ❌ 錯誤：包含換行或空白 -->
<string>
    ca-app-pub-XXXX~YYYY
</string>

<!-- ✅ 正確：單行無空白 -->
<string>ca-app-pub-XXXX~YYYY</string>
```

---

### **錯誤三：iOS 無法通過審核（AdMob 相關）**

**常見原因**：
1. 使用測試 ID 提交審核
2. 隱私政策未提及 AdMob
3. 未設定 NSUserTrackingUsageDescription

**解決方法**：
- 確認已替換所有測試 ID
- 檢查 `Info.plist` 中的 `NSUserTrackingUsageDescription`
- 在隱私政策中明確說明使用 Google AdMob

---

## 📊 上架前最終檢查

```bash
# 1. 搜尋所有測試 ID（應該找不到）
grep -r "3940256099942544" .

# 2. 檢查 iOS Info.plist
cat ios/Runner/Info.plist | grep GADApplicationIdentifier -A 1

# 3. 檢查 Android Manifest
cat android/app/src/main/AndroidManifest.xml | grep APPLICATION_ID -A 1

# 4. 執行完整建置測試
flutter clean
flutter pub get
flutter build ios --release
flutter build apk --release
```

**預期結果**：
- ✅ 沒有找到測試 ID `3940256099942544`
- ✅ iOS 和 Android 都顯示您的正式 App ID
- ✅ 建置成功無錯誤

---

## 📚 參考資源

- **AdMob 快速入門**: https://developers.google.com/admob/flutter/quick-start
- **AdMob 政策中心**: https://support.google.com/admob/answer/6128543
- **測試 ID 列表**: https://developers.google.com/admob/flutter/test-ads
- **AdMob 幫助中心**: https://support.google.com/admob/

---

## ❓ 疑難排解

**Q1: 我可以同時使用測試 ID 和正式 ID 嗎？**
A: 不行。必須完全移除測試 ID。如需測試，請使用測試裝置 ID（參考 GDPR_IMPLEMENTATION_GUIDE.md）。

**Q2: 如果忘記備份測試 ID 怎麼辦？**
A: Google 官方測試 ID 是公開的，可在此查詢：https://developers.google.com/admob/flutter/test-ads

**Q3: AdMob 帳號申請需要多久？**
A: 通常在 1-3 個工作天內審核完成。審核期間可先使用測試 ID 開發。

**Q4: 可以在開發時使用正式 ID 嗎？**
A: 不建議。可能導致無效點擊（Invalid Traffic），影響帳號評分。建議使用測試裝置 ID。

---

**版本**: 1.0.0
**最後更新**: 2025-01-XX
**注意事項**: 請務必在提交 App Store / Google Play 審核前完成 ID 替換
