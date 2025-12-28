# 本番リリース クイックチェックリスト

## コード変更が必要なファイル一覧

| ファイル | 変更内容 | 取得先 |
|----------|----------|--------|
| `lib/data/services/ocr_service.dart` | OpenAI APIキー | [OpenAI Dashboard](https://platform.openai.com/api-keys) |
| `lib/data/services/analysis_service.dart` | OpenAI APIキー | 同上 |
| `lib/data/services/ad_service.dart` | AdMob 広告ユニットID×4 | [AdMob Console](https://admob.google.com/) |
| `lib/data/services/subscription_service.dart` | RevenueCat APIキー×2 | [RevenueCat Dashboard](https://app.revenuecat.com/) |
| `android/app/src/main/AndroidManifest.xml` | AdMob App ID | AdMob Console |
| `ios/Runner/Info.plist` | AdMob App ID | AdMob Console |

---

## 各サービスで作成が必要なもの

### AdMob
- [ ] Androidアプリ登録 → App ID 取得
- [ ] iOSアプリ登録 → App ID 取得
- [ ] リワード広告ユニット作成（Android/iOS）
- [ ] インタースティシャル広告ユニット作成（Android/iOS）

### RevenueCat
- [ ] プロジェクト作成
- [ ] Android/iOSアプリ追加
- [ ] Entitlement作成: `premium`
- [ ] Products追加:
  - `ai_kakeibo_premium_monthly`
  - `ai_kakeibo_premium_yearly`
- [ ] Offerings設定

### Google Play Console
- [ ] 定期購入アイテム作成:
  - `ai_kakeibo_premium_monthly` (¥500/月)
  - `ai_kakeibo_premium_yearly` (¥4,800/年)
- [ ] RevenueCat用サービスアカウント連携

### App Store Connect
- [ ] App内課金アイテム作成:
  - `ai_kakeibo_premium_monthly` (¥500/月)
  - `ai_kakeibo_premium_yearly` (¥4,800/年)
- [ ] Shared Secret取得 → RevenueCatに設定

---

## コード変更例

### OpenAI APIキー
```dart
// lib/data/services/ocr_service.dart (7行目)
// lib/data/services/analysis_service.dart (8行目)
static const String _apiKey = 'sk-proj-本番キー';
```

### AdMob 広告ID
```dart
// lib/data/services/ad_service.dart (9-14行目)
static const String _androidRewardedAdUnitId = 'ca-app-pub-XXX/YYY';
static const String _iosRewardedAdUnitId = 'ca-app-pub-XXX/YYY';
static const String _androidInterstitialAdUnitId = 'ca-app-pub-XXX/YYY';
static const String _iosInterstitialAdUnitId = 'ca-app-pub-XXX/YYY';
```

### RevenueCat APIキー
```dart
// lib/data/services/subscription_service.dart (10-11行目)
static const String androidApiKey = 'goog_XXXX';
static const String iosApiKey = 'appl_XXXX';
```

### Android AdMob App ID
```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-XXXXXXXX~YYYYYYYY"/>
```

### iOS AdMob App ID
```xml
<!-- ios/Runner/Info.plist -->
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-XXXXXXXX~YYYYYYYY</string>
```

---

## ビルドコマンド

```bash
# Android本番ビルド
flutter build appbundle --release

# iOS本番ビルド
flutter build ios --release
```
