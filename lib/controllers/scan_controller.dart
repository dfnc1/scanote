import 'dart:io';

// GetX 4.7 masih memakai snackbar warna dari flutter/material.dart.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../services/api_service.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';

typedef ImagePickFn = Future<File?> Function(ImageSource source);
typedef ImageCompressFn = Future<File> Function(File file);

/// Controller GetX untuk memilih foto catatan, mengompres gambar, dan mengirim ke /api/scan.
class ScanController extends GetxController {
  ScanController({
    required this.apiService,
    ImagePickFn? imagePicker,
    ImageCompressFn? imageCompressor,
  })  : _imagePicker = imagePicker ?? _defaultPickImage,
        _imageCompressor = imageCompressor ?? _defaultCompressImage;

  final ApiService apiService;
  final ImagePickFn _imagePicker;
  final ImageCompressFn _imageCompressor;

  final pickedImage = Rxn<File>();
  final isScanning = false.obs;
  final errorMessage = RxnString();
  final resultTitle = ''.obs;
  final resultContent = ''.obs;
  final activeSource = ImageSource.camera.obs;

  Future<void> pickFromCamera() => _pick(ImageSource.camera);

  Future<void> pickFromGallery() => _pick(ImageSource.gallery);

  Future<void> _pick(ImageSource source) async {
    activeSource.value = source;
    errorMessage.value = null;
    try {
      final file = await _imagePicker(source);
      if (file != null) {
        pickedImage.value = file;
      }
    } catch (_) {
      errorMessage.value = source == ImageSource.camera
          ? 'Gagal membuka kamera. Periksa izin kamera perangkat.'
          : 'Gagal membuka galeri. Silakan coba lagi.';
      _showErrorSnackbar(errorMessage.value!);
    }
  }

  /// Mengompres foto lalu mengirimkannya ke endpoint /api/scan.
  Future<bool> scan() async {
    final image = pickedImage.value;
    if (image == null) {
      errorMessage.value = 'Pilih atau potret foto catatan terlebih dahulu.';
      return false;
    }

    isScanning.value = true;
    errorMessage.value = null;
    try {
      final compressed = await _imageCompressor(image);
      final result = await apiService.scanImage(compressed);

      resultTitle.value = result.title;
      resultContent.value = result.content;

      final isEmptyResult =
          result.title.trim().isEmpty && result.content.trim().isEmpty;

      final warning = isEmptyResult
          ? 'Teks tidak terbaca. Coba foto ulang dengan pencahayaan lebih baik.'
          : null;

      await Get.toNamed<void>(
        AppRoutes.preview,
        arguments: {
          'title': result.title,
          'content': result.content,
          'emptyWarning': warning,
        },
      );
      return true;
    } on ApiException catch (e) {
      errorMessage.value = e.message;
      _showErrorSnackbar(e.message);
      return false;
    } catch (_) {
      const msg = 'Gagal membaca foto, coba lagi.';
      errorMessage.value = msg;
      _showErrorSnackbar(msg);
      return false;
    } finally {
      isScanning.value = false;
    }
  }

  /// Mereset state hasil scan setelah catatan disimpan atau dibatalkan.
  void clearScan() {
    pickedImage.value = null;
    errorMessage.value = null;
    resultTitle.value = '';
    resultContent.value = '';
  }

  void _showErrorSnackbar(String message) {
    if (Get.overlayContext == null) return;
    Get.snackbar(
      'Gagal Memindai',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.surfaceInput,
      colorText: AppColors.error,
      borderColor: AppColors.error,
      borderWidth: 1,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    );
  }

  static Future<File?> _defaultPickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 1920,
      imageQuality: 90,
    );
    if (picked == null) return null;
    return File(picked.path);
  }

  /// Kompres foto ke lebar sekitar 1280 px dan kualitas 80 sebelum dikirim ke server.
  static Future<File> _defaultCompressImage(File file) async {
    try {
      final targetPath =
          '${Directory.systemTemp.path}${Platform.pathSeparator}scanote_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final compressed = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        minWidth: 1280,
        quality: 80,
        format: CompressFormat.jpeg,
      );
      if (compressed != null) {
        return File(compressed.path);
      }
    } catch (_) {
      // Gunakan file asli jika kompresi tidak didukung di platform tertentu.
    }
    return file;
  }
}
