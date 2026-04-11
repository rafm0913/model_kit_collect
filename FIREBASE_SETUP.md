# Firebase + Google 登入 設定步驟

本專案為公開 repo，**所有 API keys 與 Client ID 皆已改為 placeholder**。  
clone 後請依下列步驟設定你自己的 Firebase 專案。

---

## 前置：Clone 後必做

1. 執行 `flutterfire configure` 產生 `firebase_options.dart`、`google-services.json`、`GoogleService-Info.plist`
2. 在 `lib/config/auth_config.dart` 填入你的 Web OAuth Client ID
3. 在 `ios/Runner/Info.plist` 填入 GIDClientID、GIDServerClientID、CFBundleURLSchemes
4. 在 `web/index.html` 的 meta tag 填入 Web Client ID

---

---

## 步驟一：安裝 FlutterFire CLI

在終端機執行：

```bash
dart pub global activate flutterfire_cli
```

確保 `~/.pub-cache/bin` 已加入 PATH（若尚未加入，可執行 `export PATH="$PATH":"$HOME/.pub-cache/bin"`）。

---

## 步驟二：登入 Firebase

1. 開啟瀏覽器前往 [Firebase Console](https://console.firebase.google.com/)
2. 使用 Google 帳號登入
3. 點擊「新增專案」或選擇現有專案

---

## 步驟三：在專案目錄執行 FlutterFire 設定

在專案根目錄（`model_kit_collect`）執行：

```bash
cd /path/to/model_kit_collect
flutterfire configure
```

此指令會：

- 引導你選擇或建立 Firebase 專案
- 自動產生 `lib/firebase_options.dart`
- 自動下載並放置 `google-services.json`（Android）
- 自動下載並放置 `GoogleService-Info.plist`（iOS）

---

## 步驟四：啟用 Google 登入

1. 在 Firebase Console 左側選單點擊「Authentication」
2. 點擊「開始使用」
3. 在「登入方法」分頁，點擊「Google」
4. 開啟「啟用」開關
5. 設定「專案支援電子郵件」（選你的 Gmail）
6. 點擊「儲存」

---

## 步驟五：更新 main.dart 使用 Firebase 選項（可選）

`flutterfire configure` 會產生 `lib/firebase_options.dart`。若要使用該設定檔，可將 `main.dart` 改為：

```dart
import 'firebase_options.dart';

await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

若未產生該檔，使用 `await Firebase.initializeApp();` 搭配正確放置的設定檔即可。

---

## 步驟六：iOS 額外設定（若使用 iOS）

Google Sign-In 需要設定 URL scheme，讓登入完成後能回到你的 App。

### 6-1 取得 REVERSED_CLIENT_ID

**方法 A：從 GoogleService-Info.plist 取得**

1. 開啟 `ios/Runner/GoogleService-Info.plist`
2. 尋找 `REVERSED_CLIENT_ID` 這個 key
3. 複製它的值（格式類似 `com.googleusercontent.apps.123456789-xxxxx`）

**方法 B：若 plist 中沒有 REVERSED_CLIENT_ID**

1. 前往 [Firebase Console](https://console.firebase.google.com/) → 選擇你的專案
2. 點擊左上角齒輪圖示 ⚙️ →「專案設定」
3. 捲動到「您的應用程式」區塊，點擊 iOS 應用程式
4. 若有顯示「iOS URL 類型」或「自訂 URL 配置」，複製該值即可
5. **若沒有**，點擊「在 Google Cloud Console 中管理」連結（會開啟新分頁）
6. 在 Google Cloud Console 中：
   - 點擊左上角 **☰ 漢堡選單**
   - 選擇 **「API 和服務」**（或 "APIs & Services"）→ **「憑證」**（或 "Credentials"）
   - 或直接在頂部搜尋欄輸入「Credentials」或「憑證」
7. 在「OAuth 2.0 用戶端 ID」區塊，找到類型為 **iOS** 的項目，點擊名稱
8. 複製「用戶端 ID」，格式為：`123456789-xxxxx.apps.googleusercontent.com`
9. 反轉成：`com.googleusercontent.apps.123456789-xxxxx`（把 `123456789-xxxxx` 移到 `com.googleusercontent.apps.` 後面）

com.googleusercontent.apps.275704555947-la8lg43p9ljgf5j1odv3scrta3f3j5id

### 6-2 加入 Info.plist

1. 開啟 `ios/Runner/Info.plist`
2. 在 `</dict>` 結束標籤**之前**加入以下內容（將 `你的REVERSED_CLIENT_ID` 替換成上面取得的值）：

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>你的REVERSED_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

**範例**：若 REVERSED_CLIENT_ID 為 `com.googleusercontent.apps.123456789-abcdefg`，則：

```xml
<string>com.googleusercontent.apps.123456789-abcdefg</string>
```

---

## 步驟七：Android 額外設定（若使用 Android）

確認 `android/app/build.gradle.kts` 或 `build.gradle` 有加入：

```gradle
apply plugin: 'com.google.gms.google-services'
```

以及專案層級的 `build.gradle` 有：

```gradle
classpath 'com.google.gms:google-services:4.4.0'
```

FlutterFire 通常會自動處理這些設定。

---

## 步驟七-B：網頁版額外設定（若用瀏覽器測試）

網頁版需要 **Web OAuth Client ID**（與 iOS 不同）。

### 取得 Web Client ID

1. [Google Cloud Console](https://console.cloud.google.com/) → 選擇你的 Firebase 專案
2. 左側 ☰ → **「API 和服務」** → **「憑證」**
3. 在「OAuth 2.0 用戶端 ID」找到類型為 **「網頁應用程式」**（Web application）的項目
4. 若沒有，點「+ 建立憑證」→「OAuth 用戶端 ID」→ 應用程式類型選「網頁應用程式」
5. 複製「用戶端 ID」，格式為：`123456789-xxxxx.apps.googleusercontent.com`

### 填入專案

1. 開啟 `lib/config/auth_config.dart`，將 `YOUR_WEB_CLIENT_ID.apps.googleusercontent.com` 替換成上面複製的完整 Client ID
2. 開啟 `web/index.html`，將 `<meta name="google-signin-client_id" content="...">` 的 content 替換成同一個 Client ID

---

## 步驟八：執行專案

```bash
flutter pub get
flutter run
```

---

## 常見問題

### 登入時出現「DEVELOPER_ERROR」

- 確認 Firebase Console 已啟用 Google 登入
- 確認 SHA-1 指紋已加入 Firebase（Android）：執行 `cd android && ./gradlew signingReport` 取得 SHA-1，在 Firebase 專案設定中加入

### iOS 模擬器登入失敗

- 部分情況下需在實機測試
- 確認已登入 iCloud 且模擬器有設定 Google 帳號

### 找不到 firebase_options.dart

- 務必先執行 `flutterfire configure`
- 該檔案會自動產生在 `lib/` 目錄下
