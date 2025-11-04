# GDPR 合規實作指南
**Google UMP SDK (User Messaging Platform) 整合方案**

---

## 📋 概述

本文件說明如何在不影響現有遊戲邏輯與 UI 佈局的前提下，整合 GDPR 同意對話框。

**重要原則**：
- ✅ 僅在首次啟動時顯示（不干擾遊戲流程）
- ✅ 僅針對歐盟/英國使用者（其他地區不顯示）
- ✅ 完全不修改現有遊戲畫面與邏輯

---

## 🔧 實作步驟

### **步驟一：新增依賴套件**

編輯 `pubspec.yaml`：

```yaml
dependencies:
  # 現有依賴...
  google_mobile_ads: ^5.1.0  # 已存在，確保版本 >= 5.0.0
```

**注意**：Google Mobile Ads SDK 5.0+ 已內建 UMP SDK，無需額外安裝。

---

### **步驟二：建立 GDPR 管理器**

建立新檔案：`lib/services/consent_manager.dart`

```dart
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/material.dart';

/// GDPR 同意管理器
/// 負責處理歐盟使用者的資料收集同意流程
class ConsentManager {
  static final ConsentManager _instance = ConsentManager._internal();
  factory ConsentManager() => _instance;
  ConsentManager._internal();

  bool _isConsentGathered = false;
  bool get isConsentGathered => _isConsentGathered;

  /// 初始化並請求同意（僅首次啟動或需要更新時觸發）
  Future<void> gatherConsent() async {
    // 🔒 資安規則：僅在需要時顯示對話框
    final params = ConsentRequestParameters();

    try {
      // 1. 檢查使用者是否需要同意（自動判斷 IP 位置）
      await ConsentInformation.instance.requestConsentInfoUpdate(params);

      // 2. 檢查是否需要顯示同意表單
      final consentStatus = await ConsentInformation.instance.getConsentStatus();
      debugPrint('[GDPR] Consent status: $consentStatus');

      // 3. 如果需要同意且表單可用，則顯示
      if (consentStatus == ConsentStatus.required) {
        final isFormAvailable = await ConsentInformation.instance.isConsentFormAvailable();

        if (isFormAvailable) {
          await _loadAndShowConsentForm();
        } else {
          debugPrint('[GDPR] Consent form not available');
          _isConsentGathered = true;
        }
      } else {
        // 已同意或不需要同意（非歐盟地區）
        _isConsentGathered = true;
        debugPrint('[GDPR] Consent not required or already obtained');
      }
    } catch (e) {
      debugPrint('[GDPR] Error gathering consent: $e');
      // 發生錯誤時，允許繼續（避免阻擋非歐盟使用者）
      _isConsentGathered = true;
    }
  }

  /// 載入並顯示同意表單
  Future<void> _loadAndShowConsentForm() async {
    try {
      await ConsentForm.loadConsentForm((ConsentForm form) async {
        // 表單載入成功，顯示給使用者
        await form.show((FormError? formError) {
          if (formError != null) {
            debugPrint('[GDPR] Form error: ${formError.message}');
          }
          _isConsentGathered = true;
          debugPrint('[GDPR] Consent form dismissed');
        });
      }, (FormError formError) {
        debugPrint('[GDPR] Failed to load consent form: ${formError.message}');
        _isConsentGathered = true;
      });
    } catch (e) {
      debugPrint('[GDPR] Exception loading consent form: $e');
      _isConsentGathered = true;
    }
  }

  /// 重置同意（用於測試或使用者要求重新選擇）
  Future<void> resetConsent() async {
    try {
      await ConsentInformation.instance.reset();
      _isConsentGathered = false;
      debugPrint('[GDPR] Consent reset successfully');
    } catch (e) {
      debugPrint('[GDPR] Error resetting consent: $e');
    }
  }

  /// 檢查使用者是否可以顯示個人化廣告
  Future<bool> canShowPersonalizedAds() async {
    final status = await ConsentInformation.instance.getConsentStatus();
    return status == ConsentStatus.obtained;
  }
}
```

---

### **步驟三：整合到 App 啟動流程**

編輯 `lib/main.dart`，在現有 `main()` 函數中新增：

```dart
import 'package:flutter/material.dart';
import 'services/consent_manager.dart';
import 'services/high_score_service.dart';
// ... 其他現有 imports

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔒 資安規則：先處理 GDPR 同意，再初始化廣告
  await ConsentManager().gatherConsent();

  // 現有的初始化邏輯（保持不變）
  await HighScoreService.instance.initialize();
  await MobileAds.instance.initialize();

  runApp(const MyApp());
}
```

**變更說明**：
- 僅在 `main()` 函數新增 3 行程式碼
- 不影響現有 UI 元件與遊戲邏輯
- 對話框由 Google SDK 自動管理，不需要自訂 UI

---

### **步驟四：AdMob 初始化延遲（Android 專用）**

確認 `android/app/src/main/AndroidManifest.xml` 已設置：

```xml
<!-- 已存在，無需修改 -->
<meta-data
    android:name="com.google.android.gms.ads.DELAY_APP_MEASUREMENT_INIT"
    android:value="true"/>
```

✅ **此設置已在現有配置中，無需額外修改**。

---

## 🧪 測試方法

### **測試歐盟使用者流程**

```dart
// 在開發時，強制測試 GDPR 對話框
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🧪 測試模式：重置同意狀態
  if (const bool.fromEnvironment('GDPR_TEST_MODE')) {
    await ConsentManager().resetConsent();
  }

  await ConsentManager().gatherConsent();
  // ... 其餘初始化
}
```

執行測試：
```bash
# 強制顯示 GDPR 對話框（測試用）
flutter run --dart-define=GDPR_TEST_MODE=true

# 模擬歐盟 IP（使用 VPN 連線至德國/法國）
# 然後執行：
flutter run
```

---

## 📊 使用者體驗流程圖

```
啟動 App
    ↓
檢查 IP 位置
    ├─→ [非歐盟] → 直接進入遊戲 ✅
    └─→ [歐盟/英國]
            ↓
        檢查同意狀態
            ├─→ [已同意] → 直接進入遊戲 ✅
            └─→ [未同意] → 顯示 Google 同意對話框
                                ↓
                            [使用者選擇]
                                ↓
                            進入遊戲 ✅
```

**關鍵特性**：
- 非歐盟使用者：0 秒延遲，無任何彈窗
- 歐盟使用者（首次）：僅顯示一次 Google 標準對話框
- 已同意的歐盟使用者：0 秒延遲，直接進入

---

## ⚙️ 進階設定

### **方案A：使用測試裝置 ID（開發專用）**

```dart
// 在 gatherConsent() 中新增測試裝置
final params = ConsentRequestParameters(
  testDeviceIds: ['YOUR_TEST_DEVICE_ID'], // 從 Logcat/Console 取得
);
```

### **方案B：提供「重設同意」功能（給玩家）**

如需在設定頁面新增「重設廣告同意」按鈕：

```dart
// 在設定頁面新增按鈕（不影響現有佈局）
ElevatedButton(
  onPressed: () async {
    await ConsentManager().resetConsent();
    // 顯示提示：「請重新啟動應用程式以重新選擇同意偏好」
  },
  child: const Text('重設廣告同意'),
)
```

---

## 🔒 資安檢查清單

實作完成後，確認以下項目：

- [ ] `ConsentManager` 已建立並整合至 `main.dart`
- [ ] 使用 VPN 測試歐盟流程（德國/法國 IP）
- [ ] 測試非歐盟流程（台灣/美國 IP）
- [ ] 確認對話框僅在首次啟動顯示
- [ ] 確認拒絕同意後，廣告仍可顯示（非個人化廣告）
- [ ] 確認同意後，AdMob 正常運作
- [ ] Log 中無 GDPR 相關錯誤訊息

---

## 📚 參考資料

- **Google UMP SDK 官方文件**: https://developers.google.com/admob/flutter/privacy
- **GDPR 合規檢查清單**: https://admob.google.com/home/gdpr/
- **測試裝置 ID 取得方法**: https://developers.google.com/admob/flutter/test-ads#add_your_test_device

---

## ❓ 常見問題

**Q1: 為什麼我在台灣測試時看不到對話框？**
A: GDPR 對話框僅針對歐盟/英國 IP 顯示。使用 VPN 連線至德國可強制顯示。

**Q2: 對話框會影響遊戲效能嗎？**
A: 不會。對話框由 Google SDK 在背景非同步載入，且僅顯示一次。

**Q3: 使用者拒絕同意後會怎樣？**
A: 廣告會切換為「非個人化模式」，仍可正常顯示，但營收可能降低 30-50%。

**Q4: 是否需要在 App 內提供「隱私設定」頁面？**
A: 非強制，但建議在設定中新增「重設廣告同意」選項，提升使用者體驗。

---

**版本**: 1.0.0
**最後更新**: 2025-01-XX
**相容性**: Flutter 3.4+, google_mobile_ads 5.1.0+
