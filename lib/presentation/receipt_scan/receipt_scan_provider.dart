import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/services/ocr_service.dart';

/// レシートスキャン状態
enum ScanStatus {
  idle, // 初期状態
  capturing, // 撮影中
  processing, // OCR処理中
  success, // 成功
  error, // エラー
}

/// レシートスキャン状態クラス
class ReceiptScanState {
  final ScanStatus status;
  final Uint8List? imageBytes;
  final String? imagePath;
  final OcrResult? ocrResult;
  final String? errorMessage;

  const ReceiptScanState({
    this.status = ScanStatus.idle,
    this.imageBytes,
    this.imagePath,
    this.ocrResult,
    this.errorMessage,
  });

  ReceiptScanState copyWith({
    ScanStatus? status,
    Uint8List? imageBytes,
    String? imagePath,
    OcrResult? ocrResult,
    String? errorMessage,
  }) {
    return ReceiptScanState(
      status: status ?? this.status,
      imageBytes: imageBytes ?? this.imageBytes,
      imagePath: imagePath ?? this.imagePath,
      ocrResult: ocrResult ?? this.ocrResult,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  ReceiptScanState clearImage() {
    return const ReceiptScanState();
  }
}

/// レシートスキャンNotifier
class ReceiptScanNotifier extends StateNotifier<ReceiptScanState> {
  final OcrService _ocrService;
  final ImagePicker _imagePicker;

  ReceiptScanNotifier({
    required OcrService ocrService,
    ImagePicker? imagePicker,
  })  : _ocrService = ocrService,
        _imagePicker = imagePicker ?? ImagePicker(),
        super(const ReceiptScanState());

  /// カメラから画像を取得
  Future<void> captureFromCamera() async {
    state = state.copyWith(status: ScanStatus.capturing);

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) {
        state = state.copyWith(status: ScanStatus.idle);
        return;
      }

      final bytes = await image.readAsBytes();
      state = state.copyWith(
        status: ScanStatus.idle,
        imageBytes: bytes,
        imagePath: image.path,
      );
    } catch (e) {
      state = state.copyWith(
        status: ScanStatus.error,
        errorMessage: 'カメラの起動に失敗しました: $e',
      );
    }
  }

  /// ギャラリーから画像を選択
  Future<void> pickFromGallery() async {
    state = state.copyWith(status: ScanStatus.capturing);

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) {
        state = state.copyWith(status: ScanStatus.idle);
        return;
      }

      final bytes = await image.readAsBytes();
      state = state.copyWith(
        status: ScanStatus.idle,
        imageBytes: bytes,
        imagePath: image.path,
      );
    } catch (e) {
      state = state.copyWith(
        status: ScanStatus.error,
        errorMessage: '画像の選択に失敗しました: $e',
      );
    }
  }

  /// OCR解析を実行
  Future<void> analyzeImage() async {
    if (state.imageBytes == null) {
      state = state.copyWith(
        status: ScanStatus.error,
        errorMessage: '画像が選択されていません',
      );
      return;
    }

    state = state.copyWith(status: ScanStatus.processing);

    try {
      final result = await _ocrService.analyzeImage(state.imageBytes!);

      if (result.errorMessage != null) {
        state = state.copyWith(
          status: ScanStatus.error,
          errorMessage: result.errorMessage,
        );
      } else {
        state = state.copyWith(
          status: ScanStatus.success,
          ocrResult: result,
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: ScanStatus.error,
        errorMessage: 'OCR解析に失敗しました: $e',
      );
    }
  }

  /// 状態をリセット
  void reset() {
    state = const ReceiptScanState();
  }

  /// エラーをクリア
  void clearError() {
    state = state.copyWith(
      status: ScanStatus.idle,
      errorMessage: null,
    );
  }
}

/// レシートスキャンプロバイダー
final receiptScanProvider =
    StateNotifierProvider.autoDispose<ReceiptScanNotifier, ReceiptScanState>(
        (ref) {
  final ocrService = ref.watch(ocrServiceProvider);
  return ReceiptScanNotifier(ocrService: ocrService);
});
