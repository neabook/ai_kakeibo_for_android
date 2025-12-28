# 本番リリース前の手作業セットアップガイド

このドキュメントでは、AI家計簿アプリを本番リリースする際に必要な手作業設定をまとめています。

---

## 1. OpenAI API キー設定

### 対象ファイル
- `lib/data/services/ocr_service.dart`
- `lib/data/services/analysis_service.dart`

### 作業内容
開発用の仮キーを本番用APIキーに置換します。

```dart
// 現在（開発用）
static const String _apiKey = 'sk-proj-xxx...';

// 本番用に変更
static const String _apiKey = '本番用のOpenAI APIキー';
```

### 推奨: 環境変数化
セキュリティのため、APIキーはハードコードせず環境変数から読み込むことを推奨します。

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

final apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
```

`.env` ファイル（gitignore対象）:
```
OPENAI_API_KEY=sk-proj-your-production-key
```

---

## 2. AdMob 設定

### 2-1. 広告ユニットID設定

#### 対象ファイル
`lib/data/services/ad_service.dart`

#### 作業内容
テスト用広告IDを本番用に置換します。

```dart
// 現在（テスト用）
static const String _androidRewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';
static const String _iosRewardedAdUnitId = 'ca-app-pub-3940256099942544/1712485313';
static const String _androidInterstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
static const String _iosInterstitialAdUnitId = 'ca-app-pub-3940256099942544/4411468910';

// 本番用に変更
static const String _androidRewardedAdUnitId = 'ca-app-pub-XXXXXXXX/XXXXXXXXXX';
static const String _iosRewardedAdUnitId = 'ca-app-pub-XXXXXXXX/XXXXXXXXXX';
static const String _androidInterstitialAdUnitId = 'ca-app-pub-XXXXXXXX/XXXXXXXXXX';
static const String _iosInterstitialAdUnitId = 'ca-app-pub-XXXXXXXX/XXXXXXXXXX';
```

### 2-2. Android AdMob App ID 設定

#### 対象ファイル
`android/app/src/main/AndroidManifest.xml`

#### 作業内容
`<application>` タグ内に以下を追加:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application
        android:label="ai_kakeibo"
        ...>

        <!-- AdMob App ID（この行を追加） -->
        <meta-data
            android:name="com.google.android.gms.ads.APPLICATION_ID"
            android:value="ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX"/>

        <activity
            android:name=".MainActivity"
            ...>
        </activity>
    </application>
</manifest>
```

### 2-3. iOS AdMob App ID 設定

#### 対象ファイル
`ios/Runner/Info.plist`

#### 作業内容
`</dict>` の直前に以下を追加:

```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX</string>

<!-- iOS 14以降のATT対応（任意） -->
<key>NSUserTrackingUsageDescription</key>
<string>お客様に最適な広告を表示するために使用します</string>
```

### AdMob 広告ID取得方法
1. [AdMob Console](https://admob.google.com/) にログイン
2. アプリを追加（Android/iOS別々に）
3. 広告ユニットを作成（リワード広告、インタースティシャル広告）
4. 発行されたIDをコードに設定

---

## 3. RevenueCat 設定

### 3-1. APIキー設定

#### 対象ファイル
`lib/data/services/subscription_service.dart`

#### 作業内容
プレースホルダーを本番用APIキーに置換:

```dart
// 現在（プレースホルダー）
static const String androidApiKey = 'your_android_api_key';
static const String iosApiKey = 'your_ios_api_key';

// 本番用に変更
static const String androidApiKey = 'goog_XXXXXXXXXXXXXXXXXXXXXXXX';
static const String iosApiKey = 'appl_XXXXXXXXXXXXXXXXXXXXXXXX';
```

### 3-2. Google Play Console 設定（Android）

1. **アプリ内アイテム作成**
   - Google Play Console → アプリを選択 → 収益化 → 定期購入
   - 以下の商品IDで作成:
     - `ai_kakeibo_premium_monthly` （月額 ¥500）
     - `ai_kakeibo_premium_yearly` （年額 ¥4,800）

2. **RevenueCatと連携**
   - サービスアカウントJSON作成
   - RevenueCat Dashboard → Apps → Google Play credentials に設定

### 3-3. App Store Connect 設定（iOS）

1. **App内課金アイテム作成**
   - App Store Connect → アプリを選択 → App内課金
   - 以下の商品IDで作成:
     - `ai_kakeibo_premium_monthly` （月額 ¥500）
     - `ai_kakeibo_premium_yearly` （年額 ¥4,800）

2. **Shared Secret取得**
   - App Store Connect → アプリ → App情報 → App用共有シークレット
   - RevenueCat Dashboard → Apps → App Store credentials に設定

### 3-4. RevenueCat Dashboard 設定

1. [RevenueCat Dashboard](https://app.revenuecat.com/) でプロジェクト作成
2. Entitlements 作成: `premium`
3. Products 追加（上記の商品IDを登録）
4. Offerings 設定（defaultに商品を追加）

### RevenueCat APIキー取得方法
1. RevenueCat Dashboard → API Keys
2. Public API Key をコピー（プラットフォーム別）

---

## 4. アプリ署名設定

### 4-1. Android 署名設定

#### キーストア作成
```bash
keytool -genkey -v -keystore ~/ai-kakeibo-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias ai-kakeibo
```

#### 対象ファイル
`android/key.properties`（新規作成、gitignore対象）

```properties
storePassword=キーストアのパスワード
keyPassword=キーのパスワード
keyAlias=ai-kakeibo
storeFile=/path/to/ai-kakeibo-release.jks
```

#### 対象ファイル
`android/app/build.gradle.kts`

```kotlin
// signingConfigs ブロックを追加
android {
    signingConfigs {
        create("release") {
            val keystoreProperties = Properties()
            val keystorePropertiesFile = rootProject.file("key.properties")
            if (keystorePropertiesFile.exists()) {
                keystoreProperties.load(FileInputStream(keystorePropertiesFile))
            }
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            // ...
        }
    }
}
```

### 4-2. iOS 署名設定

1. Apple Developer Program に登録
2. Xcode でチーム設定
3. Provisioning Profile 作成
4. `ios/Runner.xcodeproj` を Xcode で開き署名設定

---

## 5. アプリアイコン・スプラッシュ設定

### 5-1. アプリアイコン

#### 必要なアセット
- 1024x1024 PNG（iOS App Store用）
- 512x512 PNG（Android Play Store用）
- 各解像度別アイコン

#### 推奨ツール
`flutter_launcher_icons` パッケージを使用:

```yaml
# pubspec.yaml に追加
dev_dependencies:
  flutter_launcher_icons: ^0.13.1

flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icon/app_icon.png"
```

```bash
flutter pub run flutter_launcher_icons
```

### 5-2. スプラッシュ画面

#### 推奨ツール
`flutter_native_splash` パッケージを使用:

```yaml
# pubspec.yaml に追加
dev_dependencies:
  flutter_native_splash: ^2.3.0

flutter_native_splash:
  color: "#6C63FF"
  image: assets/splash/splash_logo.png
```

```bash
flutter pub run flutter_native_splash:create
```

---

## 6. ストア掲載情報

### Google Play Store

| 項目 | 必須 | 説明 |
|------|------|------|
| アプリ名 | ○ | AI家計簿 |
| 短い説明 | ○ | 80文字以内 |
| 詳しい説明 | ○ | 4000文字以内 |
| スクリーンショット | ○ | 最低2枚、推奨8枚 |
| フィーチャーグラフィック | ○ | 1024x500 |
| アイコン | ○ | 512x512 |
| プライバシーポリシーURL | ○ | 必須 |
| カテゴリ | ○ | ファイナンス |

### Apple App Store

| 項目 | 必須 | 説明 |
|------|------|------|
| アプリ名 | ○ | AI家計簿 |
| サブタイトル | - | 30文字以内 |
| 説明 | ○ | 4000文字以内 |
| キーワード | ○ | 100文字以内 |
| スクリーンショット | ○ | 各デバイスサイズ別 |
| プライバシーポリシーURL | ○ | 必須 |
| サポートURL | ○ | 必須 |
| App Previews | - | 動画（任意） |

---

## 7. プライバシーポリシー・利用規約

### 必要なドキュメント
1. **プライバシーポリシー**
   - 収集するデータ（支出情報、レシート画像等）
   - データの利用目的
   - 第三者サービス（OpenAI API、AdMob、RevenueCat）への送信
   - データ保持期間
   - ユーザーの権利

2. **利用規約**
   - サービス内容
   - 禁止事項
   - 免責事項
   - サブスクリプション条件

### ホスティング先
- GitHub Pages
- Notion Public Page
- 自社サイト

---

## 8. チェックリスト

### リリース前確認

- [ ] OpenAI APIキー（本番用）を設定
- [ ] AdMob App ID（Android）を設定
- [ ] AdMob App ID（iOS）を設定
- [ ] AdMob 広告ユニットID（本番用）を設定
- [ ] RevenueCat APIキー（Android）を設定
- [ ] RevenueCat APIキー（iOS）を設定
- [ ] Google Play 定期購入アイテム作成
- [ ] App Store App内課金アイテム作成
- [ ] Android 署名設定完了
- [ ] iOS 署名設定完了
- [ ] アプリアイコン設定
- [ ] スプラッシュ画面設定
- [ ] プライバシーポリシー公開
- [ ] 利用規約公開
- [ ] ストア掲載情報準備
- [ ] テスト端末で動作確認（Android）
- [ ] テスト端末で動作確認（iOS）

---

## 9. 本番ビルドコマンド

### Android (AAB)
```bash
flutter build appbundle --release
# 出力: build/app/outputs/bundle/release/app-release.aab
```

### iOS (Archive)
```bash
flutter build ios --release
# Xcodeでアーカイブ → App Store Connect へアップロード
```

---

## 参考リンク

- [AdMob ドキュメント](https://developers.google.com/admob/flutter/quick-start)
- [RevenueCat ドキュメント](https://www.revenuecat.com/docs)
- [Google Play Console](https://play.google.com/console)
- [App Store Connect](https://appstoreconnect.apple.com)
- [OpenAI API](https://platform.openai.com/docs)
