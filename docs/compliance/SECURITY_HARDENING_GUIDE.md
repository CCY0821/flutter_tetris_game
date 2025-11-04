# 資安加固建議指南
**進階安全措施與最佳實踐（可選實作項目）**

---

## 📋 概述

本文件提供**可選的**資安加固措施。這些措施雖非 App Store 強制要求，但可提升應用程式安全性與使用者信任度。

**硬性規則遵守**：
- ✅ 所有建議均不影響遊戲邏輯與 UI 佈局
- ✅ 可逐項選擇實作，互不依賴
- ✅ 提供完整的實作與還原方法

---

## 🔒 優先級分級

| 優先級 | 項目 | 影響範圍 | 實作難度 |
|--------|------|---------|---------|
| 🔴 高 | 程式碼混淆（Code Obfuscation） | 防止逆向工程 | ⭐ 簡單 |
| 🟡 中 | 加密儲存（Secure Storage） | 遊戲資料保護 | ⭐⭐ 中等 |
| 🟢 低 | Root/Jailbreak 檢測 | 防作弊 | ⭐⭐⭐ 複雜 |
| 🟢 低 | 防截圖保護 | 防止畫面洩漏 | ⭐ 簡單 |
| 🟢 低 | SSL Pinning | 防中間人攻擊 | ⭐⭐⭐ 複雜 |

---

## 🔴 高優先級：程式碼混淆

### **目的**
防止駭客透過反編譯工具（如 APKTool、Hopper）破解遊戲邏輯。

### **效果**
- ✅ 類別名稱、函數名稱被隨機化（例：`GameLogic` → `a.b.c`）
- ✅ 符文系統邏輯難以被分析
- ✅ 提升逆向工程難度 80%+

### **實作方法（零程式碼修改）**

#### **方案一：建置時啟用混淆**

```bash
# Android APK（混淆）
flutter build apk --obfuscate --split-debug-info=build/app/outputs/symbols-android

# iOS IPA（混淆）
flutter build ios --obfuscate --split-debug-info=build/ios/outputs/symbols-ios

# App Bundle（Google Play 推薦）
flutter build appbundle --obfuscate --split-debug-info=build/app/outputs/symbols-bundle
```

**注意事項**：
- `--split-debug-info` 會產生符號檔案（symbol files），用於 Crash 分析
- **務必保存這些符號檔案**，否則無法解讀 Crashlytics 錯誤堆疊

---

#### **方案二：Android ProGuard 規則優化**

編輯 `android/app/build.gradle`（已存在，僅需檢查）：

```gradle
buildTypes {
    release {
        // ✅ 已啟用混淆（預設）
        minifyEnabled true
        shrinkResources true
        proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
    }
}
```

編輯 `android/app/proguard-rules.pro`（新增以下規則）：

```proguard
# Flutter 核心保留規則
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }

# Google AdMob 保留規則
-keep class com.google.android.gms.ads.** { *; }
-dontwarn com.google.android.gms.**

# SharedPreferences 保留（防止混淆導致讀取失敗）
-keepclassmembers class * implements android.content.SharedPreferences {
    *;
}

# 保留遊戲存檔相關類別（防止反序列化失敗）
-keep class com.yourcompany.flutter_tetris_game.** { *; }

# 移除 Log（正式版不需要）
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}
```

---

### **測試混淆效果**

```bash
# 1. 建置混淆版本
flutter build apk --obfuscate --split-debug-info=build/symbols

# 2. 解壓縮 APK
cd build/app/outputs/flutter-apk
unzip app-release.apk -d decompiled

# 3. 檢查 classes.dex（應看到 a.b.c 等混淆名稱）
# 使用 jadx 或 dex2jar 工具反編譯檢視
```

---

## 🟡 中優先級：加密儲存

### **目的**
將遊戲進度資料從明文儲存（SharedPreferences）升級為加密儲存。

### **當前風險**
- 遊戲存檔、高分可被輕易修改（透過 Root/Jailbreak）
- SharedPreferences 檔案位置：
  - Android: `/data/data/com.yourcompany.app/shared_prefs/`
  - iOS: `~/Library/Preferences/`

### **實作方案：flutter_secure_storage**

#### **步驟一：新增依賴**

編輯 `pubspec.yaml`：

```yaml
dependencies:
  # 現有依賴...
  shared_preferences: ^2.2.2  # 保留，用於向後相容
  flutter_secure_storage: ^9.0.0  # 新增
```

執行：
```bash
flutter pub get
```

---

#### **步驟二：建立加密儲存管理器**

建立新檔案：`lib/core/secure_persistence.dart`

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// 🔒 加密儲存管理器（向後相容 SharedPreferences）
class SecurePersistence {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  /// 遷移現有 SharedPreferences 資料到加密儲存（僅執行一次）
  static Future<void> migrateFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    // 檢查是否已遷移
    final isMigrated = prefs.getBool('_secure_migration_done') ?? false;
    if (isMigrated) return;

    // 遷移遊戲狀態
    final gameState = prefs.getString('tetris_game_state');
    if (gameState != null) {
      await _storage.write(key: 'tetris_game_state', value: gameState);
    }

    // 遷移符文配置
    final runeLoadout = prefs.getString('tetris_rune_loadout');
    if (runeLoadout != null) {
      await _storage.write(key: 'tetris_rune_loadout', value: runeLoadout);
    }

    // 遷移高分
    final highScore = prefs.getInt('tetris_high_score');
    if (highScore != null) {
      await _storage.write(key: 'tetris_high_score', value: highScore.toString());
    }

    // 標記遷移完成
    await prefs.setBool('_secure_migration_done', true);
    print('[SecurePersistence] Migration completed');
  }

  /// 儲存字串（加密）
  static Future<void> setString(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  /// 讀取字串（解密）
  static Future<String?> getString(String key) async {
    return await _storage.read(key: key);
  }

  /// 儲存整數（加密）
  static Future<void> setInt(String key, int value) async {
    await _storage.write(key: key, value: value.toString());
  }

  /// 讀取整數（解密）
  static Future<int?> getInt(String key) async {
    final value = await _storage.read(key: key);
    return value != null ? int.tryParse(value) : null;
  }

  /// 刪除鍵值
  static Future<void> remove(String key) async {
    await _storage.delete(key: key);
  }

  /// 檢查鍵是否存在
  static Future<bool> containsKey(String key) async {
    return await _storage.containsKey(key: key);
  }
}
```

---

#### **步驟三：整合到初始化流程**

編輯 `lib/main.dart`：

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔒 資安加固：遷移到加密儲存（僅首次執行）
  await SecurePersistence.migrateFromSharedPreferences();

  // 現有的初始化流程（保持不變）
  await ConsentManager().gatherConsent();
  await HighScoreService.instance.initialize();
  await MobileAds.instance.initialize();

  runApp(const MyApp());
}
```

---

#### **步驟四：修改儲存邏輯（可選）**

**選項A：完全替換 SharedPreferences**（推薦）

修改 `lib/core/game_persistence.dart`：

```dart
// 替換所有 SharedPreferences 為 SecurePersistence
final prefs = await SharedPreferences.getInstance();
// 改為：
import 'secure_persistence.dart';
await SecurePersistence.setString(_gameStateKey, jsonString);
```

**選項B：保持現有程式碼，僅啟用遷移**（最簡單）

不修改任何現有程式碼，僅在 `main()` 中執行遷移。資料會同時存在於兩處，確保向後相容。

---

### **測試加密效果**

```bash
# Android: 檢查 SharedPreferences 檔案
adb shell run-as com.yourcompany.app cat shared_prefs/FlutterSecureStorage.xml
# 應看到加密後的亂碼，而非明文 JSON

# iOS: 使用 Keychain Dumper（需 Jailbreak）
# Keychain 資料無法透過一般方法讀取
```

---

## 🟢 低優先級：Root/Jailbreak 檢測

### **目的**
檢測裝置是否已 Root（Android）或 Jailbreak（iOS），防止作弊行為。

### **風險評估**
- 單機遊戲：影響較低（無排行榜伺服器）
- 有內購：高風險（可能被破解）
- **當前遊戲：低風險**（僅本地高分，無線上排行榜）

### **實作方案（如需要）**

#### **新增依賴**

```yaml
dependencies:
  flutter_jailbreak_detection: ^1.10.0
```

#### **實作檢測邏輯**

```dart
import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';

Future<void> checkDeviceSecurity() async {
  final isJailbroken = await FlutterJailbreakDetection.jailbroken;
  final isDeveloperMode = await FlutterJailbreakDetection.developerMode;

  if (isJailbroken || isDeveloperMode) {
    // 選項A：顯示警告（不阻擋遊戲）
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('安全性警告'),
        content: const Text('偵測到裝置處於開發模式或已越獄，遊戲資料可能不安全。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('我知道了'),
          ),
        ],
      ),
    );

    // 選項B：禁用雲端功能（如有）
    // disableCloudSync();

    // 選項C：完全阻擋（極端措施，不推薦）
    // exit(0);
  }
}
```

**建議策略**：
- ✅ 顯示警告但允許遊戲
- ❌ 不要完全阻擋（會影響使用者體驗）

---

## 🟢 低優先級：防截圖保護

### **目的**
防止遊戲畫面被截圖或螢幕錄製（適用於有敏感資訊的遊戲）。

### **適用場景**
- 付費內容預覽
- 線上排行榜（防止作弊證據偽造）
- **當前遊戲：不需要**（無敏感資訊）

### **實作方法（如需要）**

```yaml
dependencies:
  flutter_windowmanager: ^0.2.0
```

```dart
import 'package:flutter_windowmanager/flutter_windowmanager.dart';

// 啟用防截圖（僅 Android）
await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);

// 停用防截圖
await FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
```

**注意**：iOS 無法透過程式碼禁用截圖。

---

## 🟢 低優先級：SSL Pinning

### **目的**
防止中間人攻擊（MITM），確保網路連線安全。

### **當前狀態**
- ✅ 遊戲**不使用任何網路通訊**（無伺服器）
- ✅ AdMob 由 Google SDK 處理，已內建安全措施

### **結論**
**不需要實作**，因為沒有自訂的 API 呼叫。

---

## 📊 建議實作優先順序

根據此遊戲特性，推薦以下實作順序：

### **階段一：必須實作（上架前）**
1. ✅ 程式碼混淆（已完成，使用 `--obfuscate` 建置）

### **階段二：強烈建議（提升安全性）**
2. 🔒 加密儲存（如計劃推出排行榜功能）

### **階段三：可選實作（視需求）**
3. Root/Jailbreak 檢測（如發現作弊問題）
4. 防截圖保護（如有付費內容）

---

## 🧪 資安測試檢查清單

上架前執行以下測試：

```bash
# 1. 建置混淆版本
flutter build apk --release --obfuscate --split-debug-info=build/symbols

# 2. 安裝並測試
flutter install

# 3. 檢查 Log（不應有敏感資訊）
adb logcat | grep -i "password\|secret\|key"

# 4. 反編譯測試（使用 jadx）
jadx build/app/outputs/flutter-apk/app-release.apk

# 5. 掃描安全漏洞（使用 MobSF）
# 上傳 APK 至 https://mobsf.live/
```

---

## 📚 參考資源

- **OWASP Mobile Top 10**: https://owasp.org/www-project-mobile-top-10/
- **Flutter 安全最佳實踐**: https://docs.flutter.dev/security/security-best-practices
- **Android ProGuard 指南**: https://developer.android.com/studio/build/shrink-code
- **iOS App Security**: https://developer.apple.com/documentation/security

---

## ⚠️ 重要提醒

1. **程式碼混淆必須保存符號檔案**（`split-debug-info` 輸出）
2. **加密儲存需執行遷移測試**（確保現有使用者資料不遺失）
3. **Root 檢測不應阻擋遊戲**（會失去 10-15% 使用者）
4. **所有資安措施都應經過完整測試**（防止影響正常使用者）

---

**版本**: 1.0.0
**最後更新**: 2025-01-XX
**注意事項**: 所有措施均為可選實作，不影響 App Store 審核
