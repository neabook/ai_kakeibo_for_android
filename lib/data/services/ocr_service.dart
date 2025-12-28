import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

/// OCR解析結果
class OcrResult {
  final bool success;
  final double confidence;
  final String? storeName;
  final String? date;
  final String? time;
  final int totalAmount;
  final List<OcrItem> items;
  final String suggestedCategory;
  final String? paymentMethod;
  final String rawText;
  final String? errorMessage;

  OcrResult({
    required this.success,
    required this.confidence,
    this.storeName,
    this.date,
    this.time,
    required this.totalAmount,
    required this.items,
    required this.suggestedCategory,
    this.paymentMethod,
    required this.rawText,
    this.errorMessage,
  });

  factory OcrResult.fromJson(Map<String, dynamic> json) {
    return OcrResult(
      success: json['success'] as bool,
      confidence: (json['confidence'] as num).toDouble(),
      storeName: json['store_name'] as String?,
      date: json['date'] as String?,
      time: json['time'] as String?,
      totalAmount: json['total_amount'] as int? ?? 0,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => OcrItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      suggestedCategory: json['suggested_category'] as String? ?? 'その他',
      paymentMethod: json['payment_method'] as String?,
      rawText: json['raw_text'] as String? ?? '',
      errorMessage: null,
    );
  }

  factory OcrResult.error(String message) {
    return OcrResult(
      success: false,
      confidence: 0.0,
      totalAmount: 0,
      items: [],
      suggestedCategory: 'その他',
      rawText: '',
      errorMessage: message,
    );
  }
}

/// OCR商品アイテム
class OcrItem {
  final String name;
  final int price;
  final int quantity;
  final int subtotal;

  OcrItem({
    required this.name,
    required this.price,
    required this.quantity,
    required this.subtotal,
  });

  factory OcrItem.fromJson(Map<String, dynamic> json) {
    return OcrItem(
      name: json['name'] as String? ?? '',
      price: json['price'] as int? ?? 0,
      quantity: json['quantity'] as int? ?? 1,
      subtotal: json['subtotal'] as int? ?? 0,
    );
  }
}

/// OCRサービス
class OcrService {
  final String? _apiKey;

  OcrService({String? apiKey}) : _apiKey = apiKey;

  /// 画像をBase64エンコード
  String _encodeImage(Uint8List imageBytes) {
    return base64Encode(imageBytes);
  }

  /// 画像を解析してOCR結果を取得
  Future<OcrResult> analyzeImage(Uint8List imageBytes) async {
    if (_apiKey == null || _apiKey.isEmpty) {
      return OcrResult.error('APIキーが設定されていません');
    }

    try {
      final base64Image = _encodeImage(imageBytes);
      return await _callApi(base64Image);
    } catch (e) {
      return OcrResult.error('画像の解析に失敗しました: $e');
    }
  }

  /// OpenAI API呼び出し
  Future<OcrResult> _callApi(String base64Image) async {
    const url = 'https://api.openai.com/v1/chat/completions';

    final requestBody = {
      'model': 'gpt-4o-mini',
      'messages': [
        {
          'role': 'system',
          'content': _systemPrompt,
        },
        {
          'role': 'user',
          'content': [
            {
              'type': 'text',
              'text': _userPrompt,
            },
            {
              'type': 'image_url',
              'image_url': {
                'url': 'data:image/jpeg;base64,$base64Image',
              },
            },
          ],
        },
      ],
      'response_format': {
        'type': 'json_object',
      },
      'max_tokens': 2000,
      'temperature': 0.1,
    };

    final response = await http
        .post(
          Uri.parse(url),
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(requestBody),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final responseJson = jsonDecode(response.body) as Map<String, dynamic>;
      return _parseResponse(responseJson);
    } else if (response.statusCode == 401) {
      return OcrResult.error('APIキーが無効です');
    } else if (response.statusCode == 429) {
      return OcrResult.error('API制限に達しました。しばらく待ってから再試行してください');
    } else {
      return OcrResult.error('APIエラー: ${response.statusCode}');
    }
  }

  /// APIレスポンスをパース
  OcrResult _parseResponse(Map<String, dynamic> responseJson) {
    try {
      final choices = responseJson['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) {
        return OcrResult.error('APIからの応答が空です');
      }

      final choice = choices[0] as Map<String, dynamic>;
      final message = choice['message'] as Map<String, dynamic>?;
      if (message == null) {
        return OcrResult.error('APIからのメッセージが空です');
      }

      final content = message['content'] as String?;
      if (content == null || content.isEmpty) {
        return OcrResult.error('APIからのコンテンツが空です');
      }

      final resultJson = jsonDecode(content) as Map<String, dynamic>;
      return OcrResult.fromJson(resultJson);
    } catch (e) {
      return OcrResult.error('レスポンスの解析に失敗しました: $e');
    }
  }

  /// システムプロンプト
  static const String _systemPrompt = '''
あなたは日本のレシート解析の専門家です。

## 役割
レシート画像から以下の情報を正確に抽出してください：
- 店舗名
- 購入日時
- 購入商品（商品名、単価、数量、小計）
- 合計金額
- 支払方法

## 重要なルール
1. 金額は必ず整数（円単位）で出力してください
2. 日付は YYYY-MM-DD 形式で出力してください
3. 時刻は HH:MM 形式で出力してください
4. 読み取れない部分は null を設定してください
5. 合計金額が読み取れない場合は商品の小計を合算してください
6. 税込・税抜が混在する場合は税込金額を優先してください

## カテゴリ判定基準
- 食費: スーパー、コンビニ、飲食店、カフェ
- 日用品: ドラッグストア、100円ショップ、ホームセンター
- 交通費: 鉄道、バス、タクシー、ガソリンスタンド
- 娯楽: ゲーム、映画、書籍、音楽
- 医療費: 病院、薬局（処方箋）
- 衣服: アパレル、靴、アクセサリー
- 光熱費: 電気、ガス、水道
- 通信費: 携帯電話、インターネット
- その他: 上記に該当しない場合

## 支払方法の判定
- "現金", "CASH" → cash
- "クレジット", "CREDIT", "VISA", "MASTER", "JCB" → credit
- "デビット", "DEBIT" → debit
- "Suica", "PASMO", "nanaco", "WAON", "iD", "QUICPay" → emoney
- "PayPay", "LINE Pay", "楽天ペイ", "d払い", "au PAY" → qr
- 判別不能 → null

## 出力形式
必ず以下のJSON形式で出力してください：
{
  "success": true/false,
  "confidence": 0.0-1.0,
  "store_name": "店舗名" or null,
  "date": "YYYY-MM-DD" or null,
  "time": "HH:MM" or null,
  "total_amount": 整数,
  "items": [{"name": "商品名", "price": 整数, "quantity": 整数, "subtotal": 整数}],
  "suggested_category": "食費/日用品/交通費/娯楽/医療費/衣服/光熱費/通信費/その他",
  "payment_method": "cash/credit/debit/emoney/qr/other" or null,
  "raw_text": "読み取った生テキスト"
}
''';

  /// ユーザープロンプト
  static const String _userPrompt = '''
このレシート画像を解析してください。
画像が不鮮明な場合や読み取れない場合は、success を false に設定し、読み取れた範囲で情報を出力してください。
''';
}

/// APIキー設定
/// 環境変数 OPENAI_API_KEY から取得、または .env ファイルで設定
const String _devApiKey = String.fromEnvironment(
  'OPENAI_API_KEY',
  defaultValue: '',
);

/// OCRサービスプロバイダー
final ocrServiceProvider = Provider<OcrService>((ref) {
  return OcrService(apiKey: _devApiKey);
});
